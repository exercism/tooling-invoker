module ToolingInvoker
  class Worker
    class WriteToCloudwatch
      include Mandate

      initialize_with :job

      def call
        return unless Exercism.env.production?

        client.put_log_events(
          {
            log_group_name: Exercism.config.tooling_cloudwatch_jobs_log_group_name,
            log_stream_name: Exercism.config.tooling_cloudwatch_jobs_log_stream_name,
            log_events: [
              {
                timestamp:,
                message:
              }
            ]
          }
        )
      end

      private
      def message
        {
          id: job.id,
          submission_uuid: job.submission_uuid,
          type: job.type,
          language: job.language,
          exercise: job.exercise,
          status: job.status,
          duration: job.duration,
          instance_id:
        }.to_json
      end

      def timestamp
        Time.now.to_i * 1000 # ms since epoch
      end

      def client
        Exercism.cloudwatch_logs_client
      end

      def instance_id
        `curl -s -H "X-aws-ec2-metadata-token: $(curl -s -X PUT -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600' http://169.254.169.254/latest/api/token)" http://169.254.169.254/latest/meta-data/instance-id` # rubocop:disable Layout/LineLength
      end
    end
  end
end
