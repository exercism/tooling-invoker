module ToolingInvoker
  class WorkerPool
    extend Mandate::InitializerInjector

    initialize_with :count

    def start!
      workers = Array(count).map { |idx| Worker.new(idx) }

      threads = workers.map do |worker|
        Thread.new { worker.start! }
      end

      %w[INT TERM].each do |sig|
        trap sig do
          p "Exit signal recieved"
          workers.each(&:exit!)
        end
      end

      threads.each(&:join)
    end
  end
end
