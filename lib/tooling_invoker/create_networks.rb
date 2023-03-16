module ToolingInvoker
  class CreateNetworks
    include Mandate

    def call
      # Setup docker network. If the network already
      # exists then this will be a noop. It takes about
      # 120ms to exec, so just do it on worker init
      system(
        "docker network create --internal internal",
        out: File::NULL, err: File::NULL
      )
    end
  end
end
