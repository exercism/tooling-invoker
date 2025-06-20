module ToolingInvoker
  module JobProcessor
    class ProcessJob
      include Mandate

      initialize_with :job

      def call
        Log.("Invoking request: #{job.type}:#{job.language}:#{job.exercise}", job:)

        JobProcessor::PrepareInput.(job) && run_job!
      ensure
        JobProcessor::CleanUp.(job)
      end

      private
      def run_job!
        start_time = Time.now.to_f

        begin
          Log.("Invoking container", job:)

          ExecDocker.(job)
        rescue StandardError => e
          job.exceptioned!(e.message, backtrace: e.backtrace)
        ensure
          job.duration = Time.now.to_f - start_time
        end
      end
    end
  end
end
