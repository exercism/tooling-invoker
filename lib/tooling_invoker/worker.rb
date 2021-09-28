module ToolingInvoker
  class Worker
    extend Mandate::InitializerInjector

    initialize_with :worker_idx

    def exit!
      @should_exit = true
    end

    def start!
      Log.("Worker #{worker_idx}: Starting")

      counter = 0

      loop do
        if should_exit?
          Log.("Worker #{worker_idx}: Exiting")
          break
        end

        if counter > 100
          counter = 0
          Log.("Worker #{worker_idx}: Alive at #{Time.now}")
        else
          counter += 1
        end

        job = check_for_job
        if job
          Log.("Starting job", job: job)
          start_time = Time.now.to_f
          handle_job(job)
          Log.("Total time: #{Time.now.to_f - start_time}", job: job)
        else
          sleep(ToolingInvoker.config.job_polling_delay)
        end
      rescue StandardError => e
        Log.("Top level error")
        Log.(e.message)
        Log.(e.backtrace)

        sleep(ToolingInvoker.config.job_polling_delay)
      end
    end

    private
    def should_exit?
      @should_exit
    end

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
        job_data['source'],
        job_data['container_version']
      )
    rescue RestClient::NotFound
      nil
    end

    def handle_job(job)
      ProcessJob.(job)
      RestClient.patch(
        "#{config.orchestrator_address}/jobs/#{job.id}",
        status: job.status,
        output: job.output
      )
      UploadMetadata.(job)
    rescue StandardError => e
      Log.("Error handling job", job: job)
      Log.(e.message, job: job)
      Log.(e.backtrace, job: job)
    end

    def config
      ToolingInvoker.config
    end
  end
end
