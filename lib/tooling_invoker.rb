ENV["EXERCISM_ENV"] ||= "development"

require 'mandate'
require 'aws-sdk-s3'
require 'rest-client'
require 'singleton'
require 'rugged'
require 'exercism-config'

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module ToolingInvoker
  def self.config
    Configuration.instance
  end
end
