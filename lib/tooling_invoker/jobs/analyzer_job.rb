module ToolingInvoker::Jobs
  class AnalyzerJob < Job
    def type = "analyzer"
    def required_filepaths = ["analysis.json"]
    def optional_filepaths = ["tags.json"]
  end
end
