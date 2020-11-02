require 'test_helper'

module ToolingInvoker
  class InvokeRuncTest < Minitest::Test
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

      @expected_context = {
        job_dir: "#{config.jobs_dir}/#{@job.id}-#{@hex}",
        rootfs_source: "#{config.containers_dir}/ruby-test-runner/releases/v1/rootfs"
      }

      SecureRandom.expects(:hex).twice.returns(@hex)
    end

    def test_happy_path
      ExternalCommand.any_instance.expects(:wrapped_cmd).returns(
        "#{__dir__}/bin/mock_runc"
      ).at_least_once

      expected_output = { "results.json" => '{"happy": "people"}' }
      expected_invocation_data = {
        cmd: "/opt/container_tools/runc --root root-state run #{@hex}",
        exit_status: 0,
        stdout: "",
        stderr: ""
      }

      begin
        InvokeRunc.(@job)
      ensure
        FileUtils.rm_rf("#{config.containers_dir}/ruby-test-runner/releases/v1/jobs/#{@job.id}")
      end

      assert_equal 200, @job.status
      assert_equal expected_output, @job.output
      assert_equal expected_invocation_data, @job.invocation_data
      assert_equal @expected_context, @job.context
    end

    def test_failed_invocation
      ExternalCommand.any_instance.expects(:wrapped_cmd).returns(
        "#{__dir__}/bin/missing_file"
      ).at_least_once

      expected_invocation_data = {
        cmd: "/opt/container_tools/runc --root root-state run #{@hex}",
        exit_status: nil,
        stdout: "",
        stderr: "",
        exception_msg: "513: The following error occurred: No such file or directory - /Users/iHiD/Code/exercism/tooling-invoker/test/bin/missing_file"  # rubocop:disable Layout/LineLength
      }

      begin
        InvokeRunc.(@job)
      ensure
        FileUtils.rm_rf("#{config.containers_dir}/ruby-test-runner/releases/v1/jobs/#{@job.id}")
      end

      assert_equal 513, @job.status
      assert_equal({}, @job.output)
      assert_equal expected_invocation_data, @job.invocation_data
      assert_equal @expected_context, @job.context
    end
  end
end
