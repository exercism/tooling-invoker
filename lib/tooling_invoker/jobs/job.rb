module ToolingInvoker
  module Jobs
    class Job
      extend Mandate::Memoize

      SUCCESS_STATUS = 200
      TIMEOUT_STATUS = 408
      DID_NOT_EXCEUTE_STATUS = 410
      EXCESSIVE_STDOUT_STATUS = 413
      EXCESSIVE_OUTPUT_STATUS = 460
      FAILED_TO_PREPARE_INPUT = 512
      UNKNOWN_ERROR_STATUS = 513

      MAX_OUTPUT_FILE_SIZE = 500 * 1024 # 500 kilobyte

      attr_reader :id, :language, :exercise, :source, :container_version, :timeout_s
      attr_accessor :stdout, :stderr
      attr_writer :output # Used by local webserver

      def initialize(id, language, exercise, source, container_version, timeout_s)
        @id = id
        @language = language
        @exercise = exercise
        @source = source
        @container_version = container_version
        @timeout_s = timeout_s

        @status = DID_NOT_EXCEUTE_STATUS
        @stdout = ""
        @stderr = ""
        @exception = {}
      end

      def tool
        "#{language}-#{type}"
      end

      def succeeded!
        @status = 200
      end

      def failed_to_prepare_input!(exception)
        @status = FAILED_TO_PREPARE_INPUT

        @exception = {
          message: exception.message,
          backtrace: exception.backtrace
        }
      end

      def timed_out!
        return if status_set?

        @status = TIMEOUT_STATUS
      end

      def killed_for_excessive_output!
        return if status_set?

        @status = EXCESSIVE_STDOUT_STATUS
      end

      def exceptioned!(message, backtrace: nil)
        return if status_set?

        @status = UNKNOWN_ERROR_STATUS
        @exception = {
          message: message,
          backtrace: backtrace
        }
      end

      # Check the instance variable here, not the public accessor
      def status_set?
        @status != DID_NOT_EXCEUTE_STATUS
      end

      def status
        # Exec the output function first as parsing the files
        # can affect the status
        output

        @status
      end

      def output
        # TODO: Ensure files are smaller than some sensible value
        @output ||= output_filepaths.each.with_object({}) do |output_filepath, hash|
          begin
            # TODO: This should be set to source_code_dir eventually
            contents = File.read("#{source_code_dir}/#{output_filepath}")
          rescue StandardError
            # If the file hasn't been written by the tooling
            # don't blow up everything else unnceessarily
            next
          end

          if contents.size > MAX_OUTPUT_FILE_SIZE
            @status = EXCESSIVE_OUTPUT_STATUS
            return # rubocop:disable Lint/NonLocalExitFromIterator
          end

          hash[output_filepath] = contents
        end
      end

      def image
        "#{Configuration.instance.image_registry}/#{tool}:#{Configuration.instance.image_tag}"
      end

      def source_code_root_dir
        ENV['EXERCISM_DEV_ENV_DIR'] if ENV["EXERCISM_DOCKER"]
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
