module ToolingInvoker
  class InvokeDocker
    include Mandate

    def initialize(job)
      @job = job
    end

    def call
      log("Invoking request: #{job.id}: #{job.language}:#{job.exercise}")

      prepare_input!
      run_job!
    rescue StandardError => e
      job.status = 513
      job.invocation_data[:exception_msg] = e.message
      job.invocation_data[:exception_backtrace] = e.backtrace
    end

    private
    attr_reader :job

    def prepare_input!
      log "Preparing input"
      FileUtils.mkdir_p(job.dir)
      FileUtils.mkdir(job.source_code_dir)
      FileUtils.mkdir(job.output_dir)

      SyncS3.(job.s3_uri, job.source_code_dir)

      FileUtils.chmod_R(0o777, job.source_code_dir)
      FileUtils.chmod_R(0o777, job.output_dir)
    rescue StandardError => e
      raise InvocationError.new(512, "Failure preparing input", exception: e)
    end

    def run_job!
      log "Invoking container"

      begin
        job.invocation_data = ExecDocker.(job)
        job.status = 200
      rescue InvocationError => e
        job.status = e.error_code
        job.invocation_data = (e.data || {})
        job.invocation_data[:exception_msg] = e.message
      end

      job.output = job.output_filepaths.each.with_object({}) do |output_filepath, hash|
        hash[output_filepath] = File.read("#{job.source_code_dir}/#{output_filepath}")
      rescue StandardError
        # If the file hasn't been written by the tooling
        # don't blow up everything else unnceessarily
      end
    end

    def log(message)
      puts "** #{self.class} | #{message}"
    end
  end
end
