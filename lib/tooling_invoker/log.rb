module ToolingInvoker
  class Log
    include Mandate

    def initialize(obj, job: nil)
      @obj = obj
      @job = job
    end

    def call
      puts "#{prefix}: #{obj}"
    end

    private
    attr_reader :obj, :job

    def prefix
      job ? job.id : "SYSTEM"
    end
  end
end
