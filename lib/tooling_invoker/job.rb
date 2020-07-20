module ToolingInvoker
  class Job
    attr_reader :id, :iteration_id, :language_slug, :s3_uri, :exercise_slug, :container_version, :execution_timeout

    def initialize(id, iteration_id, language_slug, exercise_slug, s3_uri, container_version, execution_timeout)
      @id = id
      @iteration_id = iteration_id
      @language_slug = language_slug
      @exercise_slug = exercise_slug
      @s3_uri = s3_uri
      @container_version = container_version
      @execution_timeout = execution_timeout
    end
  end
end
