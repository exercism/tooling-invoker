module ToolingInvoker
  class Worker
    class HandleJob
      include Mandate

      initialize_with :job

      def call
        JobProcessor::ProcessJob.(job)

        return if Jobs::Job::ABNORMAL_STATUSES.include?(job.status) && !check_canary!

        report_result!
        WriteToCloudwatch.(job)
      rescue StandardError => e
        Log.("Error handling job", job:)
        Log.(e.message, job:)
        Log.(e.backtrace, job:)
      end

      # The connection has been idle for the whole duration of the job, so
      # it's possible (if rare — the pool reopens anything idle for more than
      # 5s) that the server closed it just before we wrote. Losing this PATCH
      # loses the job's result entirely, and it's safe to repeat, so retry
      # once on a fresh connection before giving up.
      def report_result!
        attempts = 0
        begin
          Http.patch(
            "/jobs/#{job.id}",
            {
              status: job.status,
              output: job.output
            }
          )
        rescue StandardError
          raise if (attempts += 1) > 1

          retry
        end
      end

      def check_canary!
        return true if Worker::CheckCanary.()

        # OK - we're in a bad state.
        # Firstly, let's tell the orchestrator to let something
        # else handle this job.
        begin
          Http.patch("/jobs/#{job.id}/requeue")
        rescue StandardError
          # This is weird, but not enough to shut the machine down
          # It could be a 404 on the job id or somnething else.
          # But let's just catch everything to be safe.
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
