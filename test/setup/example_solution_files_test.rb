require 'test_helper'

module ToolingInvoker
  module Setup
    class ExampleSolutionFilesTest < Minitest::Test
      def test_pairs_a_single_file
        assert_equal(
          { "hello_world.rb" => ".meta/example.rb" },
          ExampleSolutionFiles.(["hello_world.rb"], [".meta/example.rb"])
        )
      end

      def test_pairs_files_by_extension
        assert_equal(
          { "hello_world.cpp" => ".meta/example.cpp", "hello_world.h" => ".meta/example.h" },
          ExampleSolutionFiles.(["hello_world.cpp", "hello_world.h"], [".meta/example.h", ".meta/example.cpp"])
        )
      end

      def test_falls_back_to_the_listed_order
        assert_equal(
          { "src/lib.rs" => ".meta/example.txt" },
          ExampleSolutionFiles.(["src/lib.rs"], [".meta/example.txt"])
        )
      end

      def test_leaves_out_solution_files_without_an_example
        assert_equal(
          { "a.py" => "ex.py" },
          ExampleSolutionFiles.(["a.py", "b.py"], ["ex.py"])
        )
      end

      def test_handles_missing_lists
        assert_empty ExampleSolutionFiles.(nil, nil)
      end
    end
  end
end
