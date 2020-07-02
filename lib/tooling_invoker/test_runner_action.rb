module ToolingInvoker
  class TestRunnerAction < ContainerAction

    def initialize(request)
      super(request)
    end

    private
    def setup_container_run(track_dir, exercise_slug, job_slug)
      ToolingInvoker::TestRun.new(track_dir, exercise_slug, job_slug)
    end
  end
end
