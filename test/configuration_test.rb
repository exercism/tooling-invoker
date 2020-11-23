require 'test_helper'

module ToolingInvoker
  class ConfigurationTest < Minitest::Test
    def test_production_defaults
      orchestrator_url = mock
      Exercism.stubs(
        env: ExercismConfig::Environment.new(:production),
        config: mock(
          tooling_orchestrator_url: orchestrator_url
        )
      )
      config = Configuration.instance
      assert_equal '/opt/jobs', config.jobs_dir
      assert_equal orchestrator_url, config.orchestrator_address
      assert_equal InvokeDocker, config.invoker
      assert_equal "1GB", config.max_memory_for_tool("ruby-test-runner")
      assert_equal "3GB", config.max_memory_for_tool("foobar")
      assert_equal "internal", config.network_for_tool("elixir-test-runner")
      assert_equal "none", config.network_for_tool("foobar")
    end

    def test_development_defaults
      orchestrator_url = mock
      Exercism.stubs(
        env: ExercismConfig::Environment.new(:development),
        config: mock(
          tooling_orchestrator_url: orchestrator_url
        )
      )
      config = Configuration.instance
      assert_equal 1, config.job_polling_delay
      assert_equal '/tmp/exercism-tooling-jobs', config.jobs_dir
      assert_equal '/tmp/exercism-tooling-jobs-efs', config.jobs_efs_dir
      assert_equal File.expand_path('../..', __dir__), config.containers_dir
      assert_equal orchestrator_url, config.orchestrator_address
      assert_equal InvokeLocalWebserver, config.invoker
    end

    def test_local_shell_flag_does_not_override_test
      ENV['EXERCISM_INVOKE_STATEGY'] = "shell"
      Exercism.stubs(
        env: ExercismConfig::Environment.new(:test)
      )
      assert_equal InvokeDocker, Configuration.instance.invoker
    ensure
      ENV.delete('EXERCISM_INVOKE_STATEGY')
    end

    def test_local_shell_flag_does_not_override_production
      ENV['EXERCISM_INVOKE_STATEGY'] = "shell"
      Exercism.stubs(
        env: ExercismConfig::Environment.new(:production)
      )
      assert_equal InvokeDocker, Configuration.instance.invoker
    ensure
      ENV.delete('EXERCISM_INVOKE_STATEGY')
    end

    def test_development_defaults_with_local_shell_flag
      ENV['EXERCISM_INVOKE_STATEGY'] = "shell"
      orchestrator_url = mock
      Exercism.stubs(
        env: ExercismConfig::Environment.new(:development),
        config: mock(
          tooling_orchestrator_url: orchestrator_url
        )
      )
      config = Configuration.instance
      assert_equal 1, config.job_polling_delay
      assert_equal '/tmp/exercism-tooling-jobs', config.jobs_dir
      assert_equal '/tmp/exercism-tooling-jobs-efs', config.jobs_efs_dir
      assert_equal File.expand_path('../..', __dir__), config.containers_dir
      assert_equal orchestrator_url, config.orchestrator_address
      assert_equal InvokeLocalShell, config.invoker
    ensure
      ENV.delete('EXERCISM_INVOKE_STATEGY')
    end

    def test_test_defaults
      orchestrator_url = mock
      Exercism.stubs(
        environment: :test,
        config: mock(
          tooling_orchestrator_url: orchestrator_url
        )
      )
      config = Configuration.instance
      assert_equal 1, config.job_polling_delay
      assert_equal '/tmp/exercism-tooling-jobs', config.jobs_dir
      assert_equal File.expand_path('../test/fixtures/containers', __dir__), config.containers_dir
      assert_equal orchestrator_url, config.orchestrator_address
      assert_equal InvokeDocker, config.invoker
    end
  end
end
