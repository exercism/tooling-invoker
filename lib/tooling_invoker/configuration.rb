module ToolingInvoker
  class Configuration
    include Singleton
    class << self
      extend Forwardable
      def_delegators :instance, :containers_dir, :orchestrator_address
    end

    def orchestrator_address
      "http://localhost:3020"
    end

    def containers_dir
      case env
      when :test
        File.expand_path("../../../test/fixtures/containers", __FILE__)
      when :production
        File.expand_path('/opt/containers')
      end
    end

    def env
      @env ||= case ENV["APP_ENV"].to_s
        when "test"
          :test
        when "production"
          :production
        else
          :development
        end
    end
  end
end
