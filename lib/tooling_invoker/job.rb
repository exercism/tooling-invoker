module ToolingInvoker
  class Job
    attr_reader :id, :exercise_slug

    def initialize(exercise_slug)
      @exercise_slug = exercise_slug
    end
  end
end
