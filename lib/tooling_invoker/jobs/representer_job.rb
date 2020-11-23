module ToolingInvoker::Jobs
  class RepresenterJob < Job
    def initialize(id, *args)
      super(id, *args)
    end

    def type
      "representer"
    end

    def cmd
      "bin/run.sh"
    end

    def invocation_args
      [exercise, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
    end

    def output_filepaths
      ["representation.txt", "mapping.json"]
    end

    def working_directory
      "/opt/representer"
    end

    def tool
      "#{language}-representer"
    end
  end
end
