module ToolingInvoker
  class UploadMetadata
    include Mandate

    initialize_with :job

    def call
      # The server can't access redis (deliberately)
      # so we can't retrieve the job, but we don't actually
      # need to as we're just using the key to write to S3.
      helper = Exercism::ToolingJob.new(job.id, {})
      helper.store_stdout!(job.stdout)
      helper.store_stderr!(job.stderr)
      helper.store_metadata!(metadata)
    end

    private
    def metadata
      {
        id: job.id,
        language: job.language,
        exercise: job.exercise,
        status: job.status,
        output: job.output,
        exception: job.exception
      }
    end
  end
end
