require 'test_helper'

module ToolingInvoker
  class Worker
    class HandleJobTest < Minitest::Test
      def test_failing_job_with_passing_canary
        job = Jobs::TestRunnerJob.new(SecureRandom.hex, SecureRandom.hex, "ruby", "bob", {}, "v1")

        # Fail the job
        JobProcessor::ProcessJob.expects(:call).with(job)

        # But pass the canary
        Worker::CheckCanary.expects(:call).returns(true)

        RestClient.
          expects(:patch).
          with(
            "#{config.orchestrator_address}/jobs/#{job.id}",
            {
              status: job.status,
              output: job.output
            }
          )

        Worker::HandleJob.(job)
      end

      def test_failing_job_with_failing_canary
        job = Jobs::TestRunnerJob.new(SecureRandom.hex, SecureRandom.hex, "ruby", "bob", {}, "v1")

        # Fail the job
        JobProcessor::ProcessJob.expects(:call).with(job)

        # And fail the canary the first time
        # but recovers the second time
        Worker::CheckCanary.expects(:call).twice.returns(false, true)

        RestClient.
          expects(:patch).
          with("#{config.orchestrator_address}/jobs/#{job.id}/requeue", {})

        Worker::HandleJob.(job)
      end
    end
  end
end
