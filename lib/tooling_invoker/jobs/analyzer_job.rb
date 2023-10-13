module ToolingInvoker::Jobs
  class AnalyzerJob < Job
    def type = "analyzer"
    def required_filepaths = ["analysis.json"]
    def optional_filepaths = ["tags.json"]
    def working_directory = "/opt/analyzer"
  end
end
