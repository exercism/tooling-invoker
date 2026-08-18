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

        Http.
          expects(:patch).
          with(
            "/jobs/#{job.id}",
            {
              status: job.status,
              output: job.output
            }
          )

        Worker::HandleJob.(job)
      end

      def test_result_patch_is_retried_once_on_a_connection_error
        job = Jobs::TestRunnerJob.new(SecureRandom.hex, SecureRandom.hex, "ruby", "bob", {}, "v1")

        JobProcessor::ProcessJob.expects(:call).with(job)
        Worker::CheckCanary.expects(:call).returns(true)
        WriteToCloudwatch.expects(:call).with(job)

        # The connection sat idle throughout the job, so the first write can
        # land on a socket the server closed. It must be retried once.
        Http.
          expects(:patch).
          with("/jobs/#{job.id}", { status: job.status, output: job.output }).
          twice.
          raises(Net::HTTP::Persistent::Error).
          then.returns(nil)

        Worker::HandleJob.(job)
      end

      def test_result_patch_gives_up_after_the_second_failure
        job = Jobs::TestRunnerJob.new(SecureRandom.hex, SecureRandom.hex, "ruby", "bob", {}, "v1")

        JobProcessor::ProcessJob.expects(:call).with(job)
        Worker::CheckCanary.expects(:call).returns(true)

        Http.expects(:patch).twice.raises(Net::HTTP::Persistent::Error)

        # No result to write, and the error is swallowed and logged
        WriteToCloudwatch.expects(:call).never

        Worker::HandleJob.(job)
      end

      def test_failing_job_with_failing_canary
        job = Jobs::TestRunnerJob.new(SecureRandom.hex, SecureRandom.hex, "ruby", "bob", {}, "v1")

        # Fail the job
        JobProcessor::ProcessJob.expects(:call).with(job)

        # And fail the canary the first time
        # but recovers the second time
        Worker::CheckCanary.expects(:call).twice.returns(false, true)

        Http.
          expects(:patch).
          with("/jobs/#{job.id}/requeue")

        Worker::HandleJob.(job)
      end
    end
  end
end
