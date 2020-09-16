require 'test_helper'

module ToolingInvoker
  class InvokeRuncTest < Minitest::Test
    def setup
      super

      SyncS3.expects(:call).once

      @job = TestRunnerJob.new(
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
      ExternalCommand.any_instance.expects(:cmd).returns(
        "#{__dir__}/bin/mock_runc"
      ).at_least_once

      expected_output_files = { "results.json" => "{\"happy\": \"people\"}" }
      expected_invocation_data = {
        cmd: "bash -x -c 'ulimit -v 3000000; /opt/container_tools/runc --root root-state run #{@hex}'",
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
      assert_equal expected_output_files, @job.output_files
      assert_equal expected_invocation_data, @job.invocation_data
      assert_equal @expected_context, @job.context
    end

    def test_failed_invocation
      ExternalCommand.any_instance.expects(:cmd).returns(
        "#{__dir__}/bin/missing_file"
      ).at_least_once

      expected_invocation_data = {
        cmd: "bash -x -c 'ulimit -v 3000000; /opt/container_tools/runc --root root-state run #{@hex}'",
        exit_status: nil,
        stdout: "",
        stderr: "",
        exception_msg: "513: Container returned exit status of nil"
      }

      begin
        InvokeRunc.(@job)
      ensure
        FileUtils.rm_rf("#{config.containers_dir}/ruby-test-runner/releases/v1/jobs/#{@job.id}")
      end

      assert_equal 513, @job.status
      assert_nil @job.output_files
      assert_equal expected_invocation_data, @job.invocation_data
      assert_equal @expected_context, @job.context
    end
  end
end
