require 'test_helper'

module ToolingInvoker
  class InvokeDockerTest < Minitest::Test
    def setup
      super

      SyncS3.expects(:call).once

      @job = Jobs::TestRunnerJob.new(
        SecureRandom.hex,
        "ruby",
        "bob",
        "s3://exercism-iterations/production/iterations/1182520",
        "v1",
        10
      )

      @hex = SecureRandom.hex
      @job_dir = "#{config.jobs_dir}/#{@job.id}-#{@hex}"

      SecureRandom.expects(:hex).twice.returns(@hex)
    end

    def test_happy_path
      ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/bin/mock_docker")

      expected_output = { "results.json" => '{"happy": "people"}' }
      expected_invocation_data = {
        cmd: "#{__dir__}/bin/mock_docker",
        exit_status: 0,
        stdout: "",
        stderr: ""
      }

      begin
        Dir.mkdir("#{@job_dir}")
        Dir.chdir(@job_dir) do
          InvokeDocker.(@job)
        end
      ensure
        FileUtils.rm_rf("#{config.containers_dir}/ruby-test-runner/releases/v1/jobs/#{@job.id}")
      end

      assert_equal 200, @job.status
      assert_equal expected_output, @job.output
      assert_equal expected_invocation_data, @job.invocation_data
    end

    def test_failed_invocation
      ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/bin/missing_file")

      expected_invocation_data = {
        cmd: "#{__dir__}/bin/missing_file",
        exit_status: nil,
        stdout: "",
        stderr: "",
        exception_msg: "513: The following error occurred: No such file or directory - #{__dir__}/bin/missing_file"  # rubocop:disable Layout/LineLength
      }

      begin
        InvokeDocker.(@job)
      ensure
        FileUtils.rm_rf("#{config.containers_dir}/ruby-test-runner/releases/v1/jobs/#{@job.id}")
      end

      assert_equal 513, @job.status
      assert_equal({}, @job.output)
      assert_equal expected_invocation_data, @job.invocation_data
    end
  end
end
