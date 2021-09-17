require 'test_helper'

module ToolingInvoker
  class ProcessJobTest < Minitest::Test
    def test_happy_path
      job = Jobs::TestRunnerJob.new(
        SecureRandom.hex,
        "ruby",
        "bob",
        { 'submission_filepaths' => [] },
        "v1"
      )

      begin
        ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/bin/mock_docker")

        FileUtils.mkdir_p(job.dir)
        Dir.chdir(job.dir) do
          ProcessJob.(job)
        end

        expected_output = { "results.json" => '{"happy": "people"}' }

        assert_equal 200, job.status
        assert_equal expected_output, job.output
        assert_equal "", job.stdout
        assert_equal "", job.stderr
      ensure
        FileUtils.rm_rf(job.dir)
      end
    end

    def test_failed_setup
      job = Jobs::TestRunnerJob.new(
        SecureRandom.hex,
        "ruby",
        "bob",
        {},
        "v1"
      )

      begin
        FileUtils.mkdir_p(job.dir)
        Dir.chdir(job.dir) do
          ProcessJob.(job)
        end

        assert_equal 512, job.status
        assert_equal "", job.stdout
        assert_equal "", job.stderr
      ensure
        FileUtils.rm_rf(job.dir)
      end
    end

    def test_failed_invocation
      job = Jobs::TestRunnerJob.new(
        SecureRandom.hex,
        "ruby",
        "bob",
        { 'submission_filepaths' => [] },
        "v1"
      )

      begin
        ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/bin/missing_file")

        ProcessJob.(job)

        assert_equal 513, job.status
        assert_empty job.output
        assert_equal "", job.stdout
        assert_equal "", job.stderr
      ensure
        FileUtils.rm_rf(job.dir)
      end
    end
  end
end
