require 'test_helper'

module ToolingInvoker
  class WorkerTest < Minitest::Test
    def test_flow
      job_id = "123"
      language = "ruby"
      exercise  = "bob"
      s3_uri = "s3://..."
      container_version = "v1"
      execution_timeout = 10

      resp = {
        job_type: "test_runner",
        id: job_id,
        language: language,
        exercise: exercise,
        s3_uri: s3_uri,
        container_version: container_version,
        execution_timeout: execution_timeout
      }

      job = mock(id: job_id)
      results = mock

      TestRunnerJob.expects(:new).with(
        job_id, language, exercise, s3_uri, container_version, execution_timeout
      ).returns(job)
      InvokeRunc.expects(:call).with(job).returns(results)
      RestClient.expects(:get).
        with("#{Configuration.orchestrator_address}/jobs/next").
        returns(mock(body: resp.to_json))

      RestClient.expects(:patch).
        with(
          "#{Configuration.orchestrator_address}/jobs/#{job_id}",
          results
        )

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
