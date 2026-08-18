require 'test_helper'

module ToolingInvoker
  class HttpTest < Minitest::Test
    # The orchestrator reads job results back as a Hash
    # (params.slice("status", "output")), so the nesting has to survive the
    # round trip. Net::HTTP's set_form_data would send a Ruby inspect string
    # here, which is exactly the bug this pins.
    def test_patch_encodes_nested_hashes_like_rack_expects
      body = capture_patch_body(
        status: :pass,
        output: { "results.json" => "{\"status\":\"pass\"}" }
      )

      assert_equal(
        [
          ["status", "pass"],
          ["output[results.json]", "{\"status\":\"pass\"}"]
        ],
        URI.decode_www_form(body)
      )
    end

    def test_patch_handles_an_empty_payload
      assert_equal "", capture_patch_body({})
    end

    def test_get_raises_not_found_for_an_empty_queue
      stub_response(Net::HTTPNotFound)

      assert_raises(Http::NotFound) { Http.get("/jobs/next") }
    end

    def test_raises_request_failed_for_anything_else
      stub_response(Net::HTTPInternalServerError, code: "500")

      assert_raises(Http::RequestFailed) { Http.get("/jobs/next") }
    end

    private
    def capture_patch_body(payload)
      body = nil
      Http::CONNECTION.stubs(:request).with do |_uri, request|
        body = request.body
        true
      end.returns(stub_success)

      Http.patch("/jobs/1", payload)
      body
    end

    def stub_response(klass, code: "404")
      Http::CONNECTION.stubs(:request).returns(klass.new("1.1", code, ""))
    end

    def stub_success
      Net::HTTPOK.new("1.1", "200", "OK")
    end
  end
end
