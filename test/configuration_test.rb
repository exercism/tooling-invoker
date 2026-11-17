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
      assert_equal 20, config.timeout_for_tool("foobar")
      assert_equal 6, config.timeout_for_tool("ruby-test-runner")
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
      assert_equal 0.6, config.job_polling_delay
      assert_equal '/tmp/exercism/tooling-jobs', config.jobs_dir
      assert_equal orchestrator_url, config.orchestrator_address
      assert_equal "latest", config.image_tag
    end

    def test_test_defaults
      orchestrator_url = mock
      Exercism.stubs(
        env: ExercismConfig::Environment.new(:test),
        config: mock(
          tooling_orchestrator_url: orchestrator_url
        )
      )
      config = Configuration.instance
      assert_equal 0.6, config.job_polling_delay
      assert_equal '/tmp/exercism/tooling-jobs', config.jobs_dir
      assert_equal orchestrator_url, config.orchestrator_address
      assert_equal "production", config.image_tag
    end

    def test_job_poll_wait
      assert_equal 20, Configuration.instance.job_poll_wait
    end

    # If the read times out before the orchestrator answers, a job given to
    # the invoker at the last moment will only go back on the queue when its
    # deadline passes.
    def test_http_read_timeout_comfortably_exceeds_the_wait
      assert_operator Http::CONNECTION.read_timeout, :>=, Configuration::JOB_POLL_WAIT + 30
    end
  end
end
