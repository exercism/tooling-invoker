require 'test_helper'

module ToolingInvoker
  class GuardsTest < Minitest::Test
    def setup
      super
      @job_id = SecureRandom.hex
      @submission_uuid = SecureRandom.hex
      @hex = SecureRandom.hex

      SecureRandom.stubs(hex: @hex)

      @job_dir = "#{Configuration.instance.jobs_dir}/#{@job_id}-#{@hex}"
    end

    def teardown
      FileUtils.rm_rf(@job_dir)
    end

    def test_timeout
      # This is the timeout that we use to test this
      Configuration.any_instance.stubs(:timeout_for_tool).returns(1)

      job = Jobs::TestRunnerJob.new(
        @job_id, @submission_uuid,
        "ruby", "bob", { 'submission_filepaths' => [] }, "v1"
      )
      JobProcessor::ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/../bin/infinite_loop")

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
        JobProcessor::ProcessJob.(job)
      ensure
        `kill -s SIGKILL #{pid_to_kill}`
      end

      assert_equal Jobs::Job::TIMEOUT_STATUS, job.status
    end

    def test_too_many_results
      # This is the timeout that we use to test this
      Configuration.any_instance.stubs(:timeout_for_tool).returns(1)

      job = Jobs::TestRunnerJob.new(
        @job_id, @submission_uuid,
        "ruby", "bob", { 'submission_filepaths' => [] }, "v1"
      )

      FileUtils.mkdir_p(job.source_code_dir)
      Dir.chdir(job.source_code_dir) do
        File.write(
          "results.json",
          "a" * (Jobs::Job::MAX_OUTPUT_FILE_SIZE + 1)
        )
      end

      JobProcessor::ProcessJob.(job)

      assert_equal Jobs::Job::EXCESSIVE_OUTPUT_STATUS, job.status
    end

    def test_excessive_output
      # Ensures this is high enough to run out of output
      Configuration.any_instance.stubs(:timeout_for_tool).returns(1)

      job = Jobs::TestRunnerJob.new(
        @job_id, @submission_uuid,
        "ruby", "bob", { 'submission_filepaths' => [] }, "v1"
      )
      JobProcessor::ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/../bin/infinite_output")

      JobProcessor::ProcessJob.(job)

      assert_equal Jobs::Job::EXCESSIVE_STDOUT_STATUS, job.status
    end
  end
end
