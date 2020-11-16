require 'test_helper'

module ToolingInvoker
  class WorkerTest < Minitest::Test
    def setup
      super

      @job_id = "123"
      @language = "ruby"
      @exercise = "bob"
      @s3_uri = "s3://..."
      @container_version = "v1"
      @timeout = 10
    end

    def test_flow_for_test_runner
      resp = {
        type: "test_runner",
        id: @job_id,
        language: @language,
        exercise: @exercise,
        s3_uri: @s3_uri,
        container_version: @container_version,
        timeout: @timeout
      }

      status = mock
      output = mock
      job = mock
      job.stubs(id: @job_id, status: status, output: output)

      Jobs::TestRunnerJob.expects(:new).with(
        @job_id, @language, @exercise, @s3_uri, @container_version, @timeout
      ).returns(job)

      InvokeDocker.expects(:call).with(job)
      UploadMetadata.expects(:call).with(job)

      RestClient.expects(:get).
        with("#{config.orchestrator_address}/jobs/next").
        returns(mock(body: resp.to_json))

      RestClient.expects(:patch).
        with(
          "#{config.orchestrator_address}/jobs/#{@job_id}",
          {
            status: status,
            output: output
          }
        )

      service = Worker.new
      service.expects(:loop).yields
      service.expects(:sleep).never

      service.()
    end

    def test_flow_for_representer
      resp = {
        type: "representer",
        id: @job_id,
        language: @language,
        exercise: @exercise,
        s3_uri: @s3_uri,
        container_version: @container_version,
        timeout: @timeout
      }

      status = mock
      output = mock
      job = mock
      job.stubs(id: @job_id, status: status, output: output)

      Jobs::RepresenterJob.expects(:new).with(
        @job_id, @language, @exercise, @s3_uri, @container_version, @timeout
      ).returns(job)
      InvokeDocker.expects(:call).with(job)
      UploadMetadata.expects(:call).with(job)

      RestClient.expects(:get).
        with("#{config.orchestrator_address}/jobs/next").
        returns(mock(body: resp.to_json))

      RestClient.expects(:patch).
        with(
          "#{config.orchestrator_address}/jobs/#{@job_id}",
          {
            status: status,
            output: output
          }
        )

      service = Worker.new
      service.expects(:loop).yields
      service.expects(:sleep).never

      service.()
    end

    def test_flow_for_analyzer
      resp = {
        type: "analyzer",
        id: @job_id,
        language: @language,
        exercise: @exercise,
        s3_uri: @s3_uri,
        container_version: @container_version,
        timeout: @timeout
      }

      status = mock
      output = mock
      job = mock
      job.stubs(id: @job_id, status: status, output: output)

      Jobs::AnalyzerJob.expects(:new).with(
        @job_id, @language, @exercise, @s3_uri, @container_version, @timeout
      ).returns(job)
      InvokeDocker.expects(:call).with(job)
      UploadMetadata.expects(:call).with(job)

      RestClient.expects(:get).
        with("#{config.orchestrator_address}/jobs/next").
        returns(mock(body: resp.to_json))

      RestClient.expects(:patch).
        with(
          "#{config.orchestrator_address}/jobs/#{@job_id}",
          {
            status: status,
            output: output
          }
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
