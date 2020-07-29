ENV["EXERCISM_ENV"] ||= "development"

require 'mandate'
require 'aws-sdk-s3'
require 'rest-client'
require 'singleton'
require 'exercism_config'

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module ToolingInvoker
  def self.env
    @env ||= ENV["EXERCISM_ENV"]
  end
end
