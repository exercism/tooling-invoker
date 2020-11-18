module ToolingInvoker::Jobs
  class AnalyzerJob < Job
    def initialize(id, *args)
      super(id, *args)
    end

    def cmd
      "bin/run.sh"
    end

    def invocation_args
      [exercise, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
    end

    def output_filepaths
      ["analysis.json"]
    end

    def working_directory
      "/opt/analyzer"
    end

    def tool
      "#{language}-analyzer"
    end
  end
end
