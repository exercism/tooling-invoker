module ToolingInvoker
  class ProcessJob
    include Mandate

    def initialize(job)
      @job = job
    end

    def call
      Log.("Invoking request: #{job.type}:#{job.language}:#{job.exercise}", job: job)

      prepare_input! && run_job!
    end

    private
    attr_reader :job

    def prepare_input!
      Log.("Preparing input", job: job)      
      FileUtils.mkdir_p(job.dir)      
      FileUtils.mkdir(job.source_code_dir)
      FileUtils.mkdir(job.output_dir)

      FileUtils.rm_rf("#{job.dir}/*")

      SetupInputFiles.(job)

      FileUtils.chmod_R(0o777, job.source_code_dir)
      FileUtils.chmod_R(0o777, job.output_dir)

      true
    rescue StandardError => e
      Log.("Failed to prepare input", job: job)
      job.failed_to_prepare_input!(e)

      false
    end

    def run_job!
      Log.("Invoking container", job: job)

      ExecDocker.(job)
    rescue StandardError => e
      job.exceptioned!(e.message, backtrace: e.backtrace)
    end
  end
end
