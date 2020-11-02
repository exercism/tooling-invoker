require 'test_helper'

module ToolingInvoker
  class InvokeDockerTest < Minitest::Test
    def setup
      super
      @job_id = SecureRandom.hex
      @hex = SecureRandom.hex

      @expected_context = {
        job_dir: "#{config.jobs_dir}/#{@job_id}-#{@hex}",
        rootfs_source: "#{config.containers_dir}/ruby-test-runner/releases/v1/rootfs"
      }

      SecureRandom.stubs(hex: @hex)
      SyncS3.stubs(:call)
    end

    def test_timeout
      job = Jobs::TestRunnerJob.new(
        @job_id,
        "ruby", "bob", "s3://exercism-iterations/production/iterations/1182520", "v1",
        1 # This is the timeout that we use to test this
      )
      ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/bin/infinite_loop")

      # Check the cleanup command is called correctly and then
      # store it so we can clean up the test too. Else we'll leave
      # the infinite loop running, and your laptop battery will die.
      pid_to_kill = nil
      Process.expects(:kill).with do |signal, pid|
        assert_equal "KILL", signal
        assert pid
        pid_to_kill = pid
      end

      begin
        InvokeDocker.(job)
      ensure
        FileUtils.rm_rf("#{config.containers_dir}/ruby-test-runner/releases/v1/jobs/#{@job_id}")
        `kill -s SIGKILL #{pid_to_kill}`
      end

      assert_equal 401, job.status
    end

    def test_excessive_output
      job = Jobs::TestRunnerJob.new(
        @job_id,
        "ruby", "bob", "s3://exercism-iterations/production/iterations/1182520", "v1",
        1 # Ensures this is high enough to run out of output
      )
      ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/bin/infinite_output")

      # The command will print out 20,000 bytes. Let's break at
      # the half way stage.
      ExecDocker.any_instance.stubs(output_limit: 10_000)

      begin
        InvokeDocker.(job)
      ensure
        FileUtils.rm_rf("#{config.containers_dir}/ruby-test-runner/releases/v1/jobs/#{@job_id}")
      end

      assert_equal 402, job.status
    end
  end
end
