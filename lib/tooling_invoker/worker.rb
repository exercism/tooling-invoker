module ToolingInvoker
  class Worker
    def initialize
    end

    def call
      loop do
        begin
          job = check_for_job
          if job 
            handle_job(job)
          else
            sleep(0.1)
          end
        rescue => e
          p e
        end
      end
    end

    private

    # "id" => id,
    # "track_slug" => "ruby",
    # "exercise_slug" => "bob",
    # "s3_uri" => "s3://exercism-iterations/production/iterations/1182520",
    # "execution_timeout" => 0,
    # 'context' => {
      # "credentials" => {
      #   'access_key_id' => ENV["AWS_ACCESS_KEY_ID"],
      #   'secret_access_key' => ENV["AWS_SECRET_ACCESS_KEY"],
      # }
    # }

    # This will raise an exception if something other than 
    # a 200 or a 404 is found.
    def check_for_job
      resp = RestClient.get(Configuration.orchestrator_address)
      request = JSON.parse(resp.body)

      klass = case request['job_type']
      when 'test_run'
        TestRunJob
      else 
        raise "Unknown job: #{type}"
      end

      klass.constantize.new(
        request['iteration_id'],
        request['language_slug']
        request['exercise_slug']
        request['container_version']
        request['execution_timeout']
      )
      end
    rescue RestClient::NotFound
      nil
    end

    def handle_job(job)
    end

    def log(message)
      puts "* #{message}"
    end
  end
end

