module ToolingInvoker
  class AnalyzerJob < Job
    def initialize(id, *args)
      super(id, *args)
    end

    def invocation_args
      ["bin/run.sh", exercise, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
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

    def output=(output_files)
      @output = { "analysis.json": JSON.parse(output_files["analysis.json"]) }
    rescue StandardError
      @output = {}
    end
  end
end
