module ToolingInvoker
  class Invoker
    def initialize(request, job_type, containers_dir)
      @request = request
      @job_type = job_type
      @containers_dir = containers_dir

      iteration_id = request["id"]
      container_version = request["container_version"]

      @environment = RuntimeEnvironment.new(
        containers_dir, 
        container_version, 
        request["track_slug"], 
        iteration_id
      )

      case job_type
      when :test_run
        @job = TestRunJob.new(exercise_slug)
      else 
        raise "Unknown job: #{type}"
      end

      runc_configuration = RuncConfiguration.new(
        job.working_directory,
        environment.rootfs_source,
        job.invocation_args
      )

      @runc = RuncWrapper.new(
        job.id,
        environment.iteration_dir, 
        runc_configuration, 
        execution_timeout: request["execution_timeout"]
      )
    end

    def invoke
      log("Invoking request: #{environment.iteration_id}: #{environment.track_slug}:#{job.exercise_slug}")

      check_container!
      prepare_input!
      result = run_job!
      result.merge(msg_type: :response)

    rescue InvocationError => e
      e.to_h.merge(msg_type: :error_response)
    end

    private
    attr_reader :request, :job, :environment, :runc

    def check_container!
      log "Checking container"
      unless environment.container_exists?
        raise InvocationError.new(511, "Container is not available at #{environment.dir}")
      end
    rescue => e
      raise InvocationError.new(512, "Failure accessing environment (during container check)", exception: e)
    end

    def prepare_input!
      log "Preparing input"
      FileUtils.mkdir_p(environment.iteration_dir)
      FileUtils.mkdir("#{environment.iteration_dir}/tmp")

      SyncS3.(@request["s3_uri"], environment.source_code_dir, @request["context"]["credentials"])
    rescue => e
      raise InvocationError.new(512, "Failure preparing input", exception: e)
    end

    def run_job!
      log "Invoking container"
      begin
        runc_result = runc.run!
      rescue => e
        raise InvocationError.new(513, "Error from container", exception: e)
      end

      exit_status = runc_result.exit_status
      if exit_status != 0
        raise InvocationError.new(513, "Container returned exit status of #{exit_status}", data: runc_result)
      end

      raw_results = File.read("#{environment.iteration_dir}/#{job.results_filepath}")
      parsed_results = JSON.parse(raw_results)

      {
        exercise_slug: exercise_slug,
        iteration_dir: environment.iteration_dir,
        rootfs_source: environment.rootfs_source,
        invocation: runc_result.report,
        result: parsed_results,
        exit_status: exit_status
      }
    end

    def log(message)
      puts "** #{self.class.to_s} | #{message}"
    end

    def exercise_slug
      @exercise_slug ||= request["exercise_slug"]
    end
  end
end
