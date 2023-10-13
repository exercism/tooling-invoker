module ToolingInvoker::Jobs
  class RepresenterJob < Job
    def type = "representer"
    def required_filepaths = ["representation.txt", "mapping.json"]
    def optional_filepaths = ["representation.json"]
  end
end
