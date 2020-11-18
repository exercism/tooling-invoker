module ToolingInvoker
  class Worker
    include Mandate

    def call
      loop do
        job = check_for_job
        if job
          puts "#{job.id}: Starting job"
          start_time = Time.now.to_f
          handle_job(job)
          puts "#{job.id}: Total time: #{Time.now.to_f - start_time}"
        else
          sleep(ToolingInvoker.config.job_polling_delay)
        end
      rescue StandardError => e
        p "Top level error"
        p e.message
        p e.backtrace

        sleep(ToolingInvoker.config.job_polling_delay)
      end
    end

    private
    # This will raise an exception if something other than
    # a 200 or a 404 is found.
    def check_for_job
      resp = RestClient.get(
        "#{config.orchestrator_address}/jobs/next"
      )
      job_data = JSON.parse(resp.body)

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
        job_data['language'],
        job_data['exercise'],
        job_data['s3_uri'],
        job_data['container_version'],
        job_data['timeout']
      )
    rescue RestClient::NotFound
      nil
    end

    def handle_job(job)
      config.invoker.(job)
      RestClient.patch(
        "#{config.orchestrator_address}/jobs/#{job.id}",
        job.to_h
      )
    rescue StandardError => e
      p e.message
      p e.backtrace
    end

    def log(message)
      puts "* #{message}"
    end

    def config
      ToolingInvoker.config
    end
  end
end
