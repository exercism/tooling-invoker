module ToolingInvoker
  class Worker
    include Mandate

    SLEEP_TIME = 1 #0.1

    def initialize
    end

    def call
      loop do
        begin
          job = check_for_job
          if job 
            handle_job(job)
          else
            sleep(SLEEP_TIME)
          end
        rescue => e
          sleep(SLEEP_TIME)
        end
      end
    end

    private

    # This will raise an exception if something other than 
    # a 200 or a 404 is found.
    def check_for_job
      resp = RestClient.get(
        "#{Configuration.orchestrator_address}/jobs/next"
      )
      request = JSON.parse(resp.body)

      klass = case request['job_type']
      when 'test_runner'
        TestRunnerJob
      else 
        raise "Unknown job: #{type}"
      end

      klass.new(
        request['id'],
        request['language'],
        request['exercise'],
        request['s3_uri'],
        request['container_version'],
        request['execution_timeout']
      )
    rescue RestClient::NotFound
      nil
    end

    def handle_job(job)
      results = Configuration.invoker.(job)
      RestClient.patch(
        "#{Configuration.orchestrator_address}/jobs/#{job.id}", 
        results
      )
    end

    def log(message)
      puts "* #{message}"
    end
  end
end

