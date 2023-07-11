module ToolingInvoker
  class Worker
    class HandleJob
      include Mandate

      initialize_with :job

      def call
        JobProcessor::ProcessJob.(job)

        return if Jobs::Job::ABNORMAL_STATUSES.include?(job.status) && !check_canary!

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

      def check_canary!
        return true if Worker::CheckCanary.()

        # OK - we're in a bad state.
        # Firstly, let's tell the orchestrator to let something
        # else handle this job.
        begin
          RestClient.patch("#{config.orchestrator_address}/jobs/#{job.id}/requeue", {})
        rescue RestClient::NotFound
          # This is weird, but not enough to shut the machine down
        end

        # Now let's check the machine a couple more times
        # and if we keep getting failures, we'll kill the machine
        # By doing this here, as part of a job process, we won't
        # pick up any new jobs until we've made a determination one
        # way or the other.
        Worker::HandleFailingCanary.()

        # If we get here the canary has recovered,
        # but now we want to abort this.
        false
      rescue StandardError
        # Everything's gone to hell. Tell the machine to shut down
        # And then raise an exception.
        `sudo shutdown now`
      end
    end
  end
end
