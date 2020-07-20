require 'test_helper'

module ToolingInvoker
  class InvokeRuncTest < Minitest::Test
    def test_proxies_to_external_command
      ExternalCommand.any_instance.expects(:cmd).returns(
        "#{File.expand_path(File.dirname(__FILE__))}/../bin/mock_runc"
      ).at_least_once

      SyncS3.expects(:call).once

      job = TestRunJob.new(
        SecureRandom.hex,
        "ruby",
        "bob",
        "s3://exercism-iterations/production/iterations/1182520",
        "v1", 
        10
      )

      expected = {
        exercise_slug: "bob", 
        job_dir: "#{Configuration.containers_dir}/ruby-test-runner/releases/v1/jobs/#{job.id}", 
        rootfs_source: "#{Configuration.containers_dir}/ruby-test-runner/releases/v1/rootfs", 
        invocation: {
          cmd: "bash -x -c 'ulimit -v 3000000; /opt/container_tools/runc --root root-state run #{job.id}'", 
          success: true, 
          stdout: "", 
          stderr: ""
        }, 
        results: {'happy' => 'people'}, 
        exit_status: 0, 
        msg_type: :response
      }
        
      begin
        assert_equal expected, InvokeRunc.(job)
      ensure
        FileUtils.rm_rf("#{Configuration.containers_dir}/ruby-test-runner/releases/v1/jobs/#{job.id}")
      end
    end
  end
end
