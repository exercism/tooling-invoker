require 'test_helper'

module ToolingInvoker
  class WorkerTest < Minitest::Test
    def setup
      super

      @job_id = "123"
      @language = "ruby"
      @exercise = "bob"
      @source = { "foo" => 'bar' }
      @container_version = "v1"
      @timeout = 10

      Kernel.stubs(:system)
    end

    def test_creates_network
      worker = mock
      worker.stubs(start!: true)
      Worker.expects(:new).once.returns(worker)

      service = WorkerPool.new(1)

      service.expects(:system).with(
        "docker network create --internal internal",
        out: File::NULL, err: File::NULL
      )

      service.start!
    end

    def test_flow_for_test_runner
      resp = {
        type: "test_runner",
        id: @job_id,
        language: @language,
        exercise: @exercise,
        source: @source,
        container_version: @container_version,
        timeout: @timeout
      }

      status = mock
      output = mock
      exception = mock
      job = mock
      job.stubs(id: @job_id, status: status, output: output, exception: exception)

      Jobs::TestRunnerJob.expects(:new).with(
        @job_id, @language, @exercise, @source, @container_version, @timeout
      ).returns(job)

      ProcessJob.expects(:call).with(job)
      UploadMetadata.expects(:call).with(job)

      RestClient.expects(:get).
        with("#{config.orchestrator_address}/jobs/next").
        returns(mock(body: resp.to_json))

      RestClient.expects(:patch).
        with(
          "#{config.orchestrator_address}/jobs/#{@job_id}",
          {
            status: status,
            output: output,
            exception: exception
          }
        )

      service = Worker.new(1)
      service.expects(:loop).yields
      service.expects(:sleep).never

      service.start!
    end

    def test_flow_for_representer
      resp = {
        type: "representer",
        id: @job_id,
        language: @language,
        exercise: @exercise,
        source: @source,
        container_version: @container_version,
        timeout: @timeout
      }

      status = mock
      output = mock
      exception = mock
      job = mock
      job.stubs(id: @job_id, status: status, output: output, exception: exception)

      Jobs::RepresenterJob.expects(:new).with(
        @job_id, @language, @exercise, @source, @container_version, @timeout
      ).returns(job)
      ProcessJob.expects(:call).with(job)
      UploadMetadata.expects(:call).with(job)

      RestClient.expects(:get).
        with("#{config.orchestrator_address}/jobs/next").
        returns(mock(body: resp.to_json))

      RestClient.expects(:patch).
        with(
          "#{config.orchestrator_address}/jobs/#{@job_id}",
          {
            status: status,
            output: output,
            exception: exception
          }
        )

      service = Worker.new(1)
      service.expects(:loop).yields
      service.expects(:sleep).never

      service.start!
    end

    def test_flow_for_analyzer
      resp = {
        type: "analyzer",
        id: @job_id,
        language: @language,
        exercise: @exercise,
        source: @source,
        container_version: @container_version,
        timeout: @timeout
      }

      status = mock
      output = mock
      exception = mock
      job = mock
      job.stubs(id: @job_id, status: status, output: output, exception: exception)

      Jobs::AnalyzerJob.expects(:new).with(
        @job_id, @language, @exercise, @source, @container_version, @timeout
      ).returns(job)
      ProcessJob.expects(:call).with(job)
      UploadMetadata.expects(:call).with(job)

      RestClient.expects(:get).
        with("#{config.orchestrator_address}/jobs/next").
        returns(mock(body: resp.to_json))

      RestClient.expects(:patch).
        with(
          "#{config.orchestrator_address}/jobs/#{@job_id}",
          {
            status: status,
            output: output,
            exception: exception
          }
        )

      service = Worker.new(1)
      service.expects(:loop).yields
      service.expects(:sleep).never

      service.start!
    end

    def test_without_job
      service = Worker.new(1)
      RestClient.expects(:get).raises(RestClient::NotFound)
      service.expects(:loop).yields
      service.expects(:sleep)
      service.start!
    end

    def test_with_exception
      RestClient.expects(:get).raises(RuntimeError)
      service = Worker.new(1)
      service.expects(:loop).yields
      service.expects(:sleep)

      service.start!
    end
  end
end
