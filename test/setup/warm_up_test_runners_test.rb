require 'test_helper'

module ToolingInvoker
  module Setup
    class WarmUpTestRunnersTest < Minitest::Test
      def setup
        super

        @marker_dir = Dir.mktmpdir
        WarmUpTestRunners.any_instance.stubs(marker_path: "#{@marker_dir}/marker", boot_id: "boot-1")
      end

      def teardown
        FileUtils.rm_r(@marker_dir)
        super
      end

      def test_runs_each_test_runner_through_the_normal_job_code
        WarmUpTestRunners.any_instance.stubs(languages: %w[python ruby])
        jobs = %w[python ruby].to_h { |language| [language, Jobs::TestRunnerJob.new("1", "2", language, "hello-world", {}, "1")] }

        jobs.each do |language, job|
          BuildWarmUpJob.expects(:call).with(language, anything, 120).returns(job)
          JobProcessor::ProcessJob.expects(:call).with(job)
        end

        WarmUpTestRunners.()
      end

      def test_carries_on_after_a_runner_fails
        WarmUpTestRunners.any_instance.stubs(languages: %w[missing ruby])
        job = Jobs::TestRunnerJob.new("1", "2", "ruby", "hello-world", {}, "1")

        BuildWarmUpJob.expects(:call).with("missing", anything, 120).raises(Rugged::OSError)
        BuildWarmUpJob.expects(:call).with("ruby", anything, 120).returns(job)
        JobProcessor::ProcessJob.expects(:call).with(job)

        WarmUpTestRunners.()
      end

      def test_stops_once_out_of_time
        WarmUpTestRunners.any_instance.stubs(languages: %w[python ruby])

        # By the time python has finished, the pass is out of time.
        start = Time.now
        Time.stubs(:now).returns(start, start, start + WarmUpTestRunners::MAX_TOTAL_SECONDS + 1)

        WarmUpTestRunners.any_instance.expects(:warm_up!).with("python")
        WarmUpTestRunners.any_instance.expects(:warm_up!).with("ruby").never

        WarmUpTestRunners.()
      end

      def test_never_raises
        WarmUpTestRunners.any_instance.stubs(:languages).raises(RuntimeError)

        WarmUpTestRunners.()
      end

      def test_only_runs_on_fleet_machines
        WarmUpTestRunners.any_instance.stubs(marker_path: "/no/such/dir/marker")
        WarmUpTestRunners.any_instance.expects(:languages).never

        WarmUpTestRunners.()
      end

      def test_runs_once_per_boot
        WarmUpTestRunners.any_instance.stubs(languages: %w[python ruby])
        WarmUpTestRunners.any_instance.expects(:warm_up!).with("python").twice
        WarmUpTestRunners.any_instance.expects(:warm_up!).with("ruby").twice

        # The first run of this boot, the same boot again, and then a new boot.
        WarmUpTestRunners.()
        WarmUpTestRunners.()
        WarmUpTestRunners.any_instance.stubs(boot_id: "boot-2")
        WarmUpTestRunners.()
      end

      def test_carries_on_after_the_invoker_crashes
        WarmUpTestRunners.any_instance.stubs(languages: %w[csharp python ruby])
        File.write("#{@marker_dir}/marker", "boot-1\ncsharp\n")

        # csharp was running when the invoker crashed, so it isn't retried.
        WarmUpTestRunners.any_instance.expects(:warm_up!).with("csharp").never
        WarmUpTestRunners.any_instance.expects(:warm_up!).with("python")
        WarmUpTestRunners.any_instance.expects(:warm_up!).with("ruby")

        WarmUpTestRunners.()

        assert_equal "boot-1\ncsharp\npython\nruby\n", File.read("#{@marker_dir}/marker")
      end

      def test_lists_the_test_runner_images_on_the_machine
        Configuration.any_instance.stubs(image_registry: "ecr.example.com", image_tag: "production")

        service = WarmUpTestRunners.new
        filter = "reference=ecr.example.com/*-test-runner:production"
        service.expects(:`).
          with("docker image ls --filter '#{filter}' --format '{{.Repository}}'").
          returns("ecr.example.com/ruby-test-runner\necr.example.com/common-lisp-test-runner\n" \
                  "ecr.example.com/ruby-test-runner\n")

        assert_equal %w[common-lisp ruby], service.send(:languages)
      end
    end
  end
end
