module ToolingInvoker
  class WriteToCloudwatch
    include Mandate

    initialize_with :job, :duration

    def call
      resp = client.put_log_events({
        log_group_name: Exercism.config.tooling_cloudwatch_jobs_log_group_name,
        log_stream_name: Exercism.config.tooling_cloudwatch_jobs_log_stream_name,
        log_events: [
          {
            timestamp: timestamp,
            message: message
          },
        ]
      })
    end

    private
    def message
      {
        id: job.id,
        type: job.type,
        language: job.language,
        exercise: job.exercise,
        status: job.status,
        instance_id: instance_id,
        duration: duration
      }.to_json
    end

    def timestamp
      Time.now.to_i * 1000 # ms since epoch
    end

    def client
      Exercism.cloudwatch_logs_client
    end

    def instance_id
      `curl http://169.254.169.254/latest/meta-data/instance-id`
    end
  end
end
