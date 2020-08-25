module ToolingInvoker
  class AnalyzerJob < Job
    def initialize(id, *args)
      super(id, *args)
    end

    def invocation_args
      ["bin/run.sh", exercise, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
    end

    def results_filepath
      "analysis.json"
    end

    def working_directory
      "/opt/analyzer"
    end

    def tool
      "#{language}-analyzer"
    end

    def parsed_result
      JSON.parse(result)
    rescue StandardError
      {}
    end
  end
end
