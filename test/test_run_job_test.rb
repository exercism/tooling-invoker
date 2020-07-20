require 'test_helper'

module ToolingInvoker
  class TestRunJobTest < Minitest::Test
    def test_everything_is_set_correctly
      iteration_id = "213"
      language_slug = "ruby"
      exercise_slug = "bob"
      s3_uri = "s3://asdasdas"
      container_version = "v3"
      execution_timeout = "10"
      hex = "some-hex"
      SecureRandom.expects(:hex).returns(hex)

      test_run = TestRunJob.new(iteration_id, language_slug, exercise_slug, s3_uri, container_version, execution_timeout)
      assert_equal iteration_id, test_run.iteration_id
      assert_equal language_slug, test_run.language_slug
      assert_equal exercise_slug, test_run.exercise_slug
      assert_equal s3_uri, test_run.s3_uri
      assert_equal container_version, test_run.container_version
      assert_equal execution_timeout, test_run.execution_timeout
      assert_equal "test_run-#{iteration_id}-#{hex}", test_run.id
      assert_equal ['bin/run.sh', 'bob', "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"], test_run.invocation_args
      assert_equal "results.json", test_run.results_filepath
      assert_equal "/opt/test-runner", test_run.working_directory
    end
  end
end

