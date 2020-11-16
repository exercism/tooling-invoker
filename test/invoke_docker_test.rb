require 'test_helper'

module ToolingInvoker
  class InvokeDockerTest < Minitest::Test
    def setup
      super

      @job = Jobs::TestRunnerJob.new(
        SecureRandom.hex,
        "ruby",
        "bob",
        "v1",
        10
      )
      FileUtils.mkdir_p(@job.input_efs_dir)
    end

    def teardown
      FileUtils.rm_rf(@job.dir)
      FileUtils.rm_rf(@job.input_efs_dir)
    end

    def test_happy_path
      ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/bin/mock_docker")

      Dir.mkdir(@job.dir)
      Dir.chdir(@job.dir) do
        InvokeDocker.(@job)
      end

      expected_output = { "results.json" => '{"happy": "people"}' }

      assert_equal 200, @job.status
      assert_equal expected_output, @job.output
      assert_equal "", @job.stdout
      assert_equal "", @job.stderr
    end

    def test_failed_setup
      FileUtils.rm_rf(@job.input_efs_dir)
      ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/bin/mock_docker")

      FileUtils.mkdir_p(@job.dir)
      Dir.chdir(@job.dir) do
        InvokeDocker.(@job)
      end

      assert_equal 512, @job.status
      assert_equal "", @job.stdout
      assert_equal "", @job.stderr
    end

    def test_failed_invocation
      ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/bin/missing_file")

      InvokeDocker.(@job)

      assert_equal 513, @job.status
      assert_equal({}, @job.output)
      assert_equal "", @job.stdout
      assert_equal "", @job.stderr
    end
  end
end
