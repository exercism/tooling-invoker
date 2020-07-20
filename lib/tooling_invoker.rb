ENV["APP_ENV"] ||= "development"

#require "orchestrator/http/app"

# Stubbed methods to avoid having to work
# with zmq locally. See files for details.
if ENV["APP_ENV"] == "development"
  #require "orchestrator/stubs/platform_connection"
end

require 'mandate'
require 'aws-sdk-s3'
require 'rest-client'

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module ToolingInvoker

  # TODO - Pivot this on config
  CONTAINERS_DIR = "tmp/"

  def self.env
    @env ||= ENV["APP_ENV"]
  end
end
