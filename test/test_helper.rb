ENV["APP_ENV"] = "test"

gem "minitest"
require "minitest/autorun"
require "minitest/pride"
require "minitest/mock"
require "mocha/minitest"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "tooling_invoker"

module Minitest
  class Test
  end
end

