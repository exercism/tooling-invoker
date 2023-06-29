module ToolingInvoker
  class WorkerPool
    extend Mandate::InitializerInjector

    initialize_with :count

    def start!
      $stdout.sync = true
      $stderr.sync = true

      Log.("Waiting for Manager to finish")
      Setup::WaitForManager.()

      Log.("Creating Networks")
      Setup::CreateNetworks.()

      Log.("Waiting for Canary") until Worker::CheckCanary.()

      workers = (1..count).map { |idx| Worker.new(idx) }

      workers.each do |worker|
        fork { worker.start! }
      end

      %w[INT TERM].each do |sig|
        trap sig do
          p "Exit signal recieved"
          workers.each(&:exit!)
        end
      end

      Process.waitall
    end
  end
end
