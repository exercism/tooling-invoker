ENV["EXERCISM_ENV"] ||= "development"

require 'mandate'
require 'aws-sdk-s3'
require 'rest-client'
require 'singleton'
require 'exercism-config'

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module ToolingInvoker
  TIMEOUT_EXIT_STATUS = 124
  EXCESSIVE_OUTPUT_EXIT_STATUS = 402

  def self.config
    Configuration.instance
  end
end
