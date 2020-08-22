module ToolingInvoker
  class RepresenterJob < Job
    def initialize(id, *args)
      super(id, *args)
    end

    def invocation_args
      ["bin/generate.sh", exercise, "/mnt/exercism-iteration/", "/mnt/exercism-iteration/"]
    end

    def results_filepath
      "results.json"
    end

    def working_directory
      "/opt/representer"
    end

    def tool
      "#{language}-representer"
    end

    def parsed_result
      JSON.parse(result)
    rescue StandardError
      {}
    end
  end
end
