ENV["APP_ENV"] ||= "development"

require 'mandate'
require 'aws-sdk-s3'
require 'rest-client'
require 'singleton'

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
