require 'test_helper'

module ToolingInvoker
  class ConfigurationTest < Minitest::Test
    def test_production_defaults
      orchestrator_url = mock
      Exercism.stubs(
        environment: :production,
        config: mock(
          tooling_orchestrator_url: orchestrator_url
        )
      )
      config = Configuration.instance
      assert_equal '/opt/jobs', config.jobs_dir
      assert_equal '/opt/containers', config.containers_dir
      assert_equal orchestrator_url, config.orchestrator_address
      assert_equal InvokeRunc, config.invoker
    end

    def test_development_defaults
      orchestrator_url = mock
      Exercism.stubs(
        environment: :development,
        config: mock(
          tooling_orchestrator_url: orchestrator_url
        )
      )
      config = Configuration.instance
      assert_equal '/tmp/exercism-tooling-jobs', config.jobs_dir
      assert_equal File.expand_path("../../..", __FILE__), config.containers_dir
      assert_equal orchestrator_url, config.orchestrator_address
      assert_equal InvokeLocally, config.invoker
    end

    def test_development_defaults_with_docker_flag
      ENV['EXERCISM_INVOKE_VIA_DOCKER'] = "true"
      orchestrator_url = mock
      Exercism.stubs(
        environment: :development,
        config: mock(
          tooling_orchestrator_url: orchestrator_url
        )
      )
      config = Configuration.instance
      assert_equal '/tmp/exercism-tooling-jobs', config.jobs_dir
      assert_equal File.expand_path("../../..", __FILE__), config.containers_dir
      assert_equal orchestrator_url, config.orchestrator_address
      assert_equal InvokeDocker, config.invoker
    ensure
      ENV.delete('EXERCISM_INVOKE_VIA_DOCKER')
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
      assert_equal '/tmp/exercism-tooling-jobs', config.jobs_dir
      assert_equal File.expand_path("../../test/fixtures/containers", __FILE__), config.containers_dir
      assert_equal orchestrator_url, config.orchestrator_address
      assert_equal InvokeRunc, config.invoker
    end
  end
end
