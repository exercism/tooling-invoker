module ToolingInvoker
  class InvokeDocker
    include Mandate

    def initialize(job)
      @job = job
    end

    def call
      log("Invoking request: #{job.id}: #{job.language}:#{job.exercise}")

      prepare_input! && run_job!
    end

    private
    attr_reader :job

    def prepare_input!
      log "Preparing input"
      FileUtils.mkdir_p(job.dir)
      FileUtils.mkdir(job.source_code_dir)
      FileUtils.mkdir(job.output_dir)

      SetupInputFiles.(job)

      FileUtils.chmod_R(0o777, job.source_code_dir)
      FileUtils.chmod_R(0o777, job.output_dir)

      true
    rescue StandardError => e
      job.failed_to_prepare_input!(e)

      false
    end

    def run_job!
      log "Invoking container"

      ExecDocker.(job)
    rescue StandardError => e
      job.exceptioned!(e.message, backtrace: e.backtrace)
    end

    def log(message)
      puts "** #{self.class} | #{message}"
    end
  end
end
