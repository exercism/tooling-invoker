module ToolingInvoker::Jobs
  class RepresenterJob < Job
    def type = "representer"
    def cmd = "bin/run.sh"
    def invocation_args = [exercise, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
    def required_filepaths = ["representation.txt", "mapping.json"]
    def optional_filepaths = ["representation.json"]
    def working_directory = "/opt/representer"
    def tool = "#{language}-representer"
  end
end
