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
      assert_equal "1GB", config.max_memory_for_tool("ruby-test-runner")
      assert_equal "3GB", config.max_memory_for_tool("foobar")
      assert_equal "internal", config.network_for_tool("elixir-test-runner")
      assert_equal "none", config.network_for_tool("foobar")
      assert_equal "production", config.image_tag
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
      assert_equal '/tmp/exercism/tooling-jobs', config.jobs_dir
      assert_equal orchestrator_url, config.orchestrator_address
      assert_equal "latest", config.image_tag
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
      assert_equal '/tmp/exercism/tooling-jobs', config.jobs_dir
      assert_equal orchestrator_url, config.orchestrator_address
      assert_equal "production", config.image_tag
    end
  end
end
