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
    end

    def test_creates_network
      Mocha::Configuration.override(stubbing_method_unnecessarily: :allow) do
        worker = mock
        worker.stubs(start!: true)
        Worker.expects(:new).once.returns(worker)

        service = WorkerPool.new(1)

        Setup::CreateNetworks.expects(:call)

        service.start!
        sleep(1)
      end
    end

    def test_flow_for_test_runner
      resp = {
        type: "test_runner",
        id: @job_id,
        language: @language,
        exercise: @exercise,
        source: @source,
        container_version: @container_version
      }

      status = mock
      output = mock
      job = Jobs::Job.new(@job_id, 'ruby', 'two-fer', nil, nil)
      job.stubs(status:, output:)

      Jobs::TestRunnerJob.expects(:new).with(
        @job_id, @language, @exercise, @source, @container_version
      ).returns(job)

      JobProcessor::ProcessJob.expects(:call).with(job)
      Worker::WriteToCloudwatch.expects(:call).with(job)

      RestClient.expects(:get).
        with("#{config.orchestrator_address}/jobs/next").
        returns(mock(body: resp.to_json))

      RestClient.expects(:patch).
        with(
          "#{config.orchestrator_address}/jobs/#{@job_id}",
          {
            status:,
            output:
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
        container_version: @container_version
      }

      status = mock
      output = mock
      job = mock
      job.stubs(id: @job_id, status:, output:)

      Jobs::RepresenterJob.expects(:new).with(
        @job_id, @language, @exercise, @source, @container_version
      ).returns(job)
      JobProcessor::ProcessJob.expects(:call).with(job)
      Worker::WriteToCloudwatch.expects(:call).with(job)

      RestClient.expects(:get).
        with("#{config.orchestrator_address}/jobs/next").
        returns(mock(body: resp.to_json))

      RestClient.expects(:patch).
        with(
          "#{config.orchestrator_address}/jobs/#{@job_id}",
          {
            status:,
            output:
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
        container_version: @container_version
      }

      status = mock
      output = mock
      job = mock
      job.stubs(id: @job_id, status:, output:)

      Jobs::AnalyzerJob.expects(:new).with(
        @job_id, @language, @exercise, @source, @container_version
      ).returns(job)
      JobProcessor::ProcessJob.expects(:call).with(job)
      Worker::WriteToCloudwatch.expects(:call).with(job)

      RestClient.expects(:get).
        with("#{config.orchestrator_address}/jobs/next").
        returns(mock(body: resp.to_json))

      RestClient.expects(:patch).
        with(
          "#{config.orchestrator_address}/jobs/#{@job_id}",
          {
            status:,
            output:
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
