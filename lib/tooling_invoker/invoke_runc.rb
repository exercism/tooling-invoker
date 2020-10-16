module ToolingInvoker
  class InvokeRunc
    include Mandate

    def initialize(job)
      @job = job

      @environment = RuntimeEnvironment.new(
        job.container_version,
        job.tool,
        job.id
      )

      runc_configuration = RuncConfiguration.new(
        job.working_directory,
        environment.rootfs_source,
        job.invocation_args
      )

      @runc = RuncWrapper.new(
        environment.job_dir,
        runc_configuration,
        timeout: job.timeout
      )
    end

    def call
      log("Invoking request: #{job.id}: #{job.language}:#{job.exercise}")

      check_container!
      prepare_input!
      run_job!
    rescue StandardError => e
      job.status = 513
      job.invocation_data[:exception_msg] = e.message
      job.invocation_data[:exception_backtrace] = e.backtrace
    end

    private
    attr_reader :job, :environment, :runc

    def check_container!
      log "Checking container"
      unless environment.container_exists?
        raise InvocationError.new(511, "Container is not available at #{environment.container_dir}")
      end

      # Add context for later retreival
      job.context[:job_dir] = environment.job_dir
      job.context[:rootfs_source] = environment.rootfs_source
    rescue StandardError => e
      raise if e.is_a?(InvocationError)

      raise InvocationError.new(512, "Failure accessing environment (during container check)", exception: e)
    end

    def prepare_input!
      log "Preparing input"
      FileUtils.mkdir_p(environment.job_dir)
      FileUtils.mkdir("#{environment.job_dir}/tmp")
      FileUtils.mkdir(environment.source_code_dir)

      SyncS3.(job.s3_uri, environment.source_code_dir)
    rescue StandardError => e
      raise InvocationError.new(512, "Failure preparing input", exception: e)
    end

    def run_job!
      log "Invoking container"

      begin
        job.invocation_data = runc.run!
        job.status = 200
      rescue InvocationError => e
        job.status = e.error_code
        job.invocation_data = (e.data || {})
        job.invocation_data[:exception_msg] = e.message
      end

      job.output = job.output_filepaths.each.with_object({}) do |output_filepath, hash|
        hash[output_filepath] = File.read("#{environment.source_code_dir}/#{output_filepath}")
      rescue StandardError
        # If the file hasn't been written by the tooling
        # don't blow up everything else unnceessarily
      end
    end

    def log(message)
      puts "** #{self.class} | #{message}"
    end
  end
end
