module ToolingInvoker
  class Worker
    class RetrieveJob
      include Mandate

      # This will raise an exception if something other than
      # a 200 or a 404 is found.
      def call
        resp = RestClient.get(
          "#{config.orchestrator_address}/jobs/next"
        )
        job_data = JSON.parse(resp.body)
        build_job(job_data)
      rescue RestClient::NotFound
        nil
      end

      def build_job(job_data)
        klass = case job_data['type']
                when 'test_runner'
                  Jobs::TestRunnerJob
                when 'representer'
                  Jobs::RepresenterJob
                when 'analyzer'
                  Jobs::AnalyzerJob
                else
                  raise "Unknown job: #{job_data['type']}"
                end

        klass.new(
          job_data['id'],
          job_data['submission_uuid'],
          job_data['language'],
          job_data['exercise'],
          job_data['source'],
          job_data['container_version']
        )
      end

      def config
        ToolingInvoker.config
      end
    end
  end
end
