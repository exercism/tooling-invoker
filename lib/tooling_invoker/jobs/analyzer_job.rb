module ToolingInvoker::Jobs
  class AnalyzerJob < Job
    def type = "analyzer"
    def cmd = "bin/run.sh"
    def invocation_args = [exercise, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
    def output_filepaths = ["analysis.json"]
    def working_directory = "/opt/analyzer"
    def tool = "#{language}-analyzer"
  end
end
