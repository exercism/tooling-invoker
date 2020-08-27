module ToolingInvoker
  class RepresenterJob < Job
    def initialize(id, *args)
      super(id, *args)
    end

    def invocation_args
      ["bin/run.sh", exercise, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
    end

    def results_filepath
      "representation.txt"
    end

    def working_directory
      "/opt/representer"
    end

    def tool
      "#{language}-representer"
    end

    def parsed_result
      result
    end
  end
end
