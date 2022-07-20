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
      retries = 0

      begin
        Log.("Preparing input", job: job)
        FileUtils.rm_rf("#{job.dir}/*")
        FileUtils.mkdir_p(job.dir) unless Dir.exist?(job.dir)
        FileUtils.mkdir(job.source_code_dir) unless Dir.exist?(job.source_code_dir)
        FileUtils.mkdir(job.output_dir) unless Dir.exist?(job.output_dir)

        SetupInputFiles.(job)

        FileUtils.chmod_R(0o777, job.source_code_dir)
        FileUtils.chmod_R(0o777, job.output_dir)

        true
      rescue StandardError => e
        retries += 1

        if retries <= MAX_NUM_RETRIES
          sleep RETRY_SLEEP_SECONDS[retries - 1]
          retry
        end

        Log.("Failed to prepare input", job: job)
        job.failed_to_prepare_input!(e)

        false
      end
    end

    def run_job!
      Log.("Invoking container", job: job)

      ExecDocker.(job)
    rescue StandardError => e
      job.exceptioned!(e.message, backtrace: e.backtrace)
    end

    RETRY_SLEEP_SECONDS = [0.1, 0.3, 0.6].freeze
    MAX_NUM_RETRIES = 3

    private_constant :RETRY_SLEEP_SECONDS, :MAX_NUM_RETRIES
  end
end
