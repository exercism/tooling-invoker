module ToolingInvoker
  class Worker
    class HandleJob
      include Mandate

      initialize_with :job

      def call
        JobProcessor::ProcessJob.(job)
        RestClient.patch(
          "#{config.orchestrator_address}/jobs/#{job.id}",
          {
            status: job.status,
            output: job.output
          }
        )
        WriteToCloudwatch.(job)
      rescue StandardError => e
        Log.("Error handling job", job:)
        Log.(e.message, job:)
        Log.(e.backtrace, job:)
      end

      def config
        ToolingInvoker.config
      end

    end
  end
end
