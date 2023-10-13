module ToolingInvoker
  module Jobs
    class Job
      extend Mandate::Memoize

      SUCCESS_STATUS = 200
      TIMEOUT_STATUS = 408
      DID_NOT_EXECUTE_STATUS = 410
      EXCESSIVE_STDOUT_STATUS = 413
      EXCESSIVE_OUTPUT_STATUS = 460
      FAILED_TO_PREPARE_INPUT = 512
      UNKNOWN_ERROR_STATUS = 513

      ABNORMAL_STATUSES = [
        DID_NOT_EXECUTE_STATUS,
        TIMEOUT_STATUS,
        FAILED_TO_PREPARE_INPUT,
        UNKNOWN_ERROR_STATUS
      ].freeze

      MAX_OUTPUT_FILE_SIZE = 500 * 1024 # 500 kilobyte

      attr_reader :id, :submission_uuid, :language, :exercise, :source, :container_version, :exception
      attr_accessor :stdout, :stderr, :duration
      attr_writer :output # Used by local webserver

      def initialize(id, submission_uuid, language, exercise, source, container_version)
        @id = id
        @submission_uuid = submission_uuid
        @language = language
        @exercise = exercise
        @source = source
        @container_version = container_version

        @status = DID_NOT_EXECUTE_STATUS
        @stdout = ""
        @stderr = ""
        @exception = {}
      end

      def tool = "#{language}-#{type}"
      def cmd = "bin/run.sh"
      def invocation_args = [exercise, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
      def working_directory = "/opt/#{type}"

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

      def timed_out!(details)
        return if status_set?

        # Sometimes a test runner writes the file but fails
        # to fully exit. This handles that case.
        return succeeded! if valid_output?

        @status = TIMEOUT_STATUS
        @exception = { message: "Timed out. #{details}" }
      end

      def killed_for_excessive_output!
        return if status_set?

        @status = EXCESSIVE_STDOUT_STATUS
      end

      def exceptioned!(message, backtrace: nil)
        return if status_set?

        @status = UNKNOWN_ERROR_STATUS
        @exception = {
          message:,
          backtrace:
        }
      end

      # Check the instance variable here, not the public accessor
      def status_set?
        @status != DID_NOT_EXECUTE_STATUS
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
            # don't blow up everything else unnecessarily
            next
          end

          if contents.size > MAX_OUTPUT_FILE_SIZE
            @status = EXCESSIVE_OUTPUT_STATUS
            return # rubocop:disable Lint/NonLocalExitFromIterator
          end

          hash[output_filepath] = contents
        end
      end

      def valid_output?
        required_filepaths.all? do |output_filepath|
          contents = File.read("#{source_code_dir}/#{output_filepath}")
          contents && contents.size > 0 && contents.size <= MAX_OUTPUT_FILE_SIZE
        rescue StandardError
          false
        end
      end

      def output_filepaths = required_filepaths + optional_filepaths

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
