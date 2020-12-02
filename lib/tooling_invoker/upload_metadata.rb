module ToolingInvoker
  class UploadMetadata
    include Mandate

    initialize_with :job

    def call
      upload('stdout', job.stdout)
      upload('stderr', job.stderr)
    end

    def upload(name, contents)
      client.put_object(
        bucket: bucket_name,
        key: "#{folder}/#{name}",
        body: contents,
        acl: 'private'
      )
    end

    memoize
    def folder
      "#{Exercism.env}/#{job.id}"
    end

    memoize
    def client
      Exercism.s3_client
    end

    memoize
    def bucket_name
      Exercism.config.aws_tooling_jobs_bucket
    end
  end
end
