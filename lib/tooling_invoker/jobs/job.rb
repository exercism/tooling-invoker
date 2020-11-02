module ToolingInvoker
  module Jobs
    class Job
      extend Mandate::Memoize

      attr_reader :id, :language, :s3_uri, :exercise, :container_version, :timeout_s
      attr_accessor :status, :output, :invocation_data

      def initialize(id, language, exercise, s3_uri, container_version, timeout_s)
        @id = id
        @language = language
        @exercise = exercise
        @s3_uri = s3_uri
        @container_version = container_version
        @timeout_s = timeout_s
        @status = 410
        @invocation_data = {}
      end

      def to_h
        {
          status: status,
          output: output,
          invocation_data: invocation_data
        }
      end

      def image
        "#{tool}:production"
      end

      memoize
      def source_code_dir
        "#{dir}/code"
      end

      memoize
      def output_dir
        "#{dir}/__exercism_output__"
      end

      memoize
      def dir
        "#{Configuration.instance.jobs_dir}/#{id}-#{SecureRandom.hex}"
      end
    end
  end
end
