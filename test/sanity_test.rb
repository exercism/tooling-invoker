require 'test_helper'

module ToolingInvoker
  class SanityTest < Minitest::Test
    def test_sanity
      TestRunnerAction.new({
        'context' => {
          "credentials" => {}
        }
      }).invoke
    end
  end
end
