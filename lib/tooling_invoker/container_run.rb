module ToolingInvoker
  class ContainerRun
    attr_reader :exercise_slug

    def initialize(exercise_slug)
      @exercise_slug = exercise_slug
    end
  end
end
