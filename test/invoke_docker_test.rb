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

      begin
        Dir.mkdir(@job_dir.to_s)
        Dir.chdir(@job_dir) do
          InvokeDocker.(@job)
        end
      ensure
        FileUtils.rm_rf("#{config.containers_dir}/ruby-test-runner/releases/v1/jobs/#{@job.id}")
      end

      expected_output = { "results.json" => '{"happy": "people"}' }

      assert_equal 200, @job.status
      assert_equal expected_output, @job.output
      assert_equal "", @job.stdout
      assert_equal "", @job.stderr
    end

    def test_failed_invocation
      ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/bin/missing_file")

      begin
        InvokeDocker.(@job)
      ensure
        FileUtils.rm_rf("#{config.containers_dir}/ruby-test-runner/releases/v1/jobs/#{@job.id}")
      end

      assert_equal 513, @job.status
      assert_equal({}, @job.output)
      assert_equal "", @job.stdout
      assert_equal "", @job.stderr
    end
  end
end
