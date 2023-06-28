module ToolingInvoker
  module JobProcessor
    class PrepareInput
      include Mandate

      initialize_with :job do
        self.retries = 0
      end

      def call
        begin
          ToolingInvoker::Log.("Preparing input", job:)

          FileUtils.rm_rf("#{job.dir}/*")
          FileUtils.mkdir_p(job.dir) unless Dir.exist?(job.dir)
          FileUtils.mkdir(job.source_code_dir) unless Dir.exist?(job.source_code_dir)
          FileUtils.mkdir(job.output_dir) unless Dir.exist?(job.output_dir)

          SetupInputFiles.(job)

          FileUtils.chmod_R(0o777, job.source_code_dir)
          FileUtils.chmod_R(0o777, job.output_dir)

          true
        rescue StandardError => e
          self.retries += 1

          if self.retries <= MAX_NUM_RETRIES
            sleep RETRY_SLEEP_SECONDS[self.retries - 1]
            retry
          end

          ToolingInvoker::Log.("Failed to prepare input", job:)
          job.failed_to_prepare_input!(e)

          false
        end
      end

      private
      attr_accessor :retries

      RETRY_SLEEP_SECONDS = [0.2, 0.5, 1, 2.0].freeze
      MAX_NUM_RETRIES = RETRY_SLEEP_SECONDS.length

      private_constant :RETRY_SLEEP_SECONDS, :MAX_NUM_RETRIES
    end
  end
end
