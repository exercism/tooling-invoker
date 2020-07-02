module ToolingInvoker
  class ContainerAction
    def initialize(request)
      @request = request
    end

    def invoke
      @job_slug = request["id"]
      log("Invoking request #{@job_slug}")

      @track_slug = request["track_slug"]
      @exercise_slug = request["exercise_slug"]
      @container_version = request["container_version"]
      log("Using #{track_slug}:#{container_version} for #{@exercise_slug}")

      @aws_credentials = parse_credentials(request["context"])

      check_container
      setup_run unless @error
      prepare_input unless @error
      run_container unless @error

      response = {}

      if @error
        response[:msg_type] = :error_response
        response.merge(@error)
      else
        response[:msg_type] = :response
        response.merge(@result)
      end
    end

    private
    attr_reader :request, :track_slug, :container_version
    def check_container
      log "Checking container"
      begin
        unless environment.released?(track_slug, container_version)
          msg = "Container #{track_slug}:#{container_version} isn't available"
          log msg
          @error = {
            worker_error_code: 511,
            error: msg
          }
        end
      rescue => e
        msg = "Failure accessing environment (during container check)"
        log msg
        @error = {
          worker_error_code: 512,
          error: msg,
          detail: e
        }
      end
    end

    def setup_run
      log "Setup run environment"
      track_dir = environment.track_dir(track_slug, container_version)
      begin
        @tooling_run = setup_container_run(track_dir, @exercise_slug, @job_slug)
        @tooling_run.execution_timeout = request["execution_timeout"] if request["execution_timeout"]
      rescue => e
        msg = "Failure setting up job"
        log msg
        @error = {
          worker_error_code: 512,
          error: msg,
          detail: e
        }
      end
    end

    def prepare_input
      log "Preparing input for running"
      begin
        @tooling_run.prepare_iteration do |iteration_folder|
          prepare_folder(iteration_folder)
        end
      rescue => e
        msg = "Failure preparing input"
        log msg
        @error = {
          worker_error_code: 512,
          error: msg,
          detail: e
        }
      end
    end

    def run_container
      log "Invoking container"
      begin
        data = @tooling_run.run!
        if data[:exit_status] != 0
          @error = {
            worker_error_code: 513,
            error: "Container returned exit status of #{data[:exit_status]}"
          }
          @error.merge!(data)
        else
          @result = data
        end
      rescue => e
        msg = "Error from container"
        log msg
        log e
        puts e.backtrace
        @error = {
          worker_error_code: 513,
          error: msg,
          detail: e
        }
      end
    end

    def setup_container_run(track_dir, exercise_slug, job_slug)
      raise "Please create run command"
    end


    def prepare_folder(iteration_folder)
      location = @request["s3_uri"]
      s3_sync(location, iteration_folder)
    end

    def s3_sync(s3_uri, download_folder)
      log "Syncing #{s3_uri} -> #{download_folder}"
      s3 = Aws::S3::Client.new(
        credentials: @aws_credentials,
        region: "eu-west-1",
        http_idle_timeout: 0
      )
      log "Created client"
      location_uri = URI(s3_uri)
      bucket = location_uri.host
      path = location_uri.path[1..-1]
      s3_download_path = "#{path}/"
      params = {
        bucket: bucket,
        prefix: s3_download_path,
      }
      log "Listing #{s3_download_path}"
      resp = s3.list_objects(params)
      resp.contents.each do |item|
        key = item[:key]
        local_key = key.delete_prefix(s3_download_path)
        log "listing item #{local_key}"
        target = "#{download_folder}/#{local_key}"
        target_folder = File.dirname(target)
        log "mkdir #{target_folder}"
        FileUtils.mkdir_p target_folder
        log "get_object #{key} -> #{target}"
        s3.get_object({
          bucket: bucket,
          key: key,
          response_target: target
        })
        log "downloaded #{target}"
      end
    rescue => e
      log "ERROR in s3 sync #{e.message}"
      raise
    end

    def parse_credentials(request)
      raw_credentials = request["credentials"]
      key = raw_credentials["access_key_id"]
      secret = raw_credentials["secret_access_key"]
      session = raw_credentials["session_token"]
      Aws::Credentials.new(key, secret, session)
    end

    def log(message)
      puts "** #{self.class.to_s} | #{message}"
    end
  end
end
