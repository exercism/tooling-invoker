require 'test_helper'

module ToolingInvoker
  class WorkerTest < Minitest::Test
    def test_with
      iteration_id = "123"
      language_slug = "ruby"
      exercise_slug  = "bob"
      s3_uri = "s3://..."
      container_version = "v1"
      execution_timeout = 10

      resp = {
        job_type: "test_run",
        iteration_id: iteration_id,
        language_slug: language_slug,
        exercise_slug: exercise_slug,
        s3_uri: s3_uri,
        container_version: container_version,
        execution_timeout: execution_timeout
      }

      job = mock
      TestRunJob.expects(:new).with(
        iteration_id, language_slug, exercise_slug, s3_uri, container_version, execution_timeout
      ).returns(job)
      Invoker.expects(:call).with(job)
      RestClient.expects(:get).returns(mock(body: resp.to_json))

      service = Worker.new
      service.expects(:loop).yields
      service.expects(:sleep).never

      service.()
    end

    def test_without_job
      service = Worker.new
      RestClient.expects(:get).raises(RestClient::NotFound)
      service.expects(:loop).yields
      service.expects(:sleep)

      service.()
    end

    def test_with_exception
      RestClient.expects(:get).raises(RuntimeError)
      service = Worker.new
      service.expects(:loop).yields
      service.expects(:sleep)

      service.()
    end
  end
end
