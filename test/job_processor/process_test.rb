require 'test_helper'

module ToolingInvoker
  module JobProcessor
    class ProcessTest < Minitest::Test
      def test_happy_path
        job = Jobs::TestRunnerJob.new(
          SecureRandom.hex,
          SecureRandom.hex,
          "ruby",
          "bob",
          { 'submission_filepaths' => [] },
          "v1"
        )

        begin
          ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/../bin/mock_docker")

          FileUtils.mkdir_p(job.dir)
          Dir.chdir(job.dir) do
            ProcessJob.(job)
          end

          expected_output = { "results.json" => '{"happy": "people"}' }

          # assert_equal 200, job.status
          assert_equal expected_output, job.output
          # assert_equal "", job.stdout
          # assert_equal "", job.stderr
        ensure
          FileUtils.rm_rf(job.dir)
        end
      end

      def test_failed_setup
        job = Jobs::TestRunnerJob.new(
          SecureRandom.hex,
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

      def test_failed_setup_retried_thrice
        job = Jobs::TestRunnerJob.new(
          SecureRandom.hex,
          SecureRandom.hex,
          "ruby",
          "bob",
          { 'submission_filepaths' => [] },
          "v1"
        )

        begin
          ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/../bin/mock_docker")

          SetupInputFiles.expects(:call).
            times(5).
            raises(StandardError).
            then.raises(StandardError).
            then.raises(StandardError).
            then.raises(StandardError).
            then.returns(true)

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

      def test_failed_setup_stops_at_fourth_retry
        job = Jobs::TestRunnerJob.new(
          SecureRandom.hex,
          SecureRandom.hex,
          "ruby",
          "bob",
          { 'submission_filepaths' => [] },
          "v1"
        )

        begin
          ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/../bin/mock_docker")

          SetupInputFiles.expects(:call).
            times(5).
            raises(StandardError).
            then.raises(StandardError).
            then.raises(StandardError).
            then.raises(StandardError).
            then.raises(StandardError)

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

      def test_failed_setup_retries_doesnt_wait_longer_than_two_seconds
        job = Jobs::TestRunnerJob.new(
          SecureRandom.hex,
          SecureRandom.hex,
          "ruby",
          "bob",
          { 'submission_filepaths' => [] },
          "v1"
        )

        begin
          ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/../bin/mock_docker")

          SetupInputFiles.expects(:call).
            times(5).
            raises(StandardError).
            then.raises(StandardError).
            then.raises(StandardError).
            then.raises(StandardError).
            then.raises(StandardError)

          FileUtils.mkdir_p(job.dir)

          start = Time.now
          Dir.chdir(job.dir) do
            ProcessJob.(job)
          end
          elapsed = Time.now - start

          assert elapsed >= 3
          assert elapsed <= 4
        ensure
          FileUtils.rm_rf(job.dir)
        end
      end

      def test_failed_invocation
        job = Jobs::TestRunnerJob.new(
          SecureRandom.hex,
          SecureRandom.hex,
          "ruby",
          "bob",
          { 'submission_filepaths' => [] },
          "v1"
        )

        begin
          ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/../bin/missing_file")

          ProcessJob.(job)

          assert_equal 513, job.status
          assert_empty job.output
          assert_equal "", job.stdout
          assert_equal "", job.stderr
        ensure
          FileUtils.rm_rf(job.dir)
        end
      end

      def test_timeout_with_results
        results = '{"happy": "people"}'

        job = Jobs::TestRunnerJob.new(
          SecureRandom.hex,
          SecureRandom.hex,
          "ruby",
          "bob",
          { 'submission_filepaths' => [] },
          "v1"
        )

        # Write results to the place the test runner should write to
        FileUtils.mkdir_p(job.source_code_dir)
        File.write("#{job.source_code_dir}/#{job.output_filepaths[0]}", results)

        begin
          ExecDocker.any_instance.stubs(docker_run_command: "#{__dir__}/../bin/infinite_loop")

          FileUtils.mkdir_p(job.dir)
          Dir.chdir(job.dir) do
            ProcessJob.(job)
          end

          expected_output = { "results.json" => results }

          assert_equal 200, job.status
          assert_equal expected_output, job.output
          assert_equal "", job.stdout
          assert_equal "", job.stderr
        ensure
          FileUtils.rm_rf(job.dir)
        end
      end
    end
  end
end
