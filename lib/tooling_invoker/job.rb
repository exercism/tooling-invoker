module ToolingInvoker
  class Job
    attr_reader :id, :language, :s3_uri, :exercise, :container_version, :execution_timeout

    def initialize(id, language, exercise, s3_uri, container_version, execution_timeout)
      @id = id
      @language = language
      @exercise = exercise
      @s3_uri = s3_uri
      @container_version = container_version
      @execution_timeout = execution_timeout
    end
  end
end
