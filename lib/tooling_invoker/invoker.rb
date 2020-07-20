module ToolingInvoker
  class Invoker
    include Mandate

    def initialize(job)
      @job = job

      @environment = RuntimeEnvironment.new(
        job.container_version, 
        job.language_slug,
        job.id
      )

      runc_configuration = RuncConfiguration.new(
        job.working_directory,
        environment.rootfs_source,
        job.invocation_args
      )

      @runc = RuncWrapper.new(
        job.id,
        environment.job_dir, 
        runc_configuration, 
        execution_timeout: job.execution_timeout
      )
    end

    def call
      log("Invoking request: #{job.id}: #{job.language_slug}:#{job.exercise_slug}")

      check_container!
      prepare_input!
      result = run_job!
      result.merge(msg_type: :response)

    rescue InvocationError => e
      e.to_h.merge(msg_type: :error_response)
    end

    private
    attr_reader :job, :environment, :runc

    def check_container!
      log "Checking container"
      unless environment.container_exists?
        raise InvocationError.new(511, "Container is not available at #{environment.container_dir}")
      end
    rescue => e
      raise if e.is_a?(InvocationError) 
      raise InvocationError.new(512, "Failure accessing environment (during container check)", exception: e)
    end

    def prepare_input!
      log "Preparing input"
      FileUtils.mkdir_p(environment.job_dir)
      FileUtils.mkdir("#{environment.job_dir}/tmp")

      SyncS3.(job.s3_uri, environment.source_code_dir)
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

      raw_results = File.read("#{environment.job_dir}/#{job.results_filepath}")
      parsed_results = JSON.parse(raw_results)

      {
        exercise_slug: job.exercise_slug,
        job_dir: environment.job_dir,
        rootfs_source: environment.rootfs_source,
        invocation: runc_result.report,
        result: parsed_results,
        exit_status: exit_status
      }
    end

    def log(message)
      puts "** #{self.class.to_s} | #{message}"
    end
  end
end
