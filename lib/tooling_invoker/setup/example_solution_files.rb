module ToolingInvoker
  module Setup
    # Pairs each of an exercise's solution files with the example file that
    # should take its place, so the example can be run as if a student had
    # submitted it. An example is paired with the solution file that has the
    # same extension (so example.h goes to hello_world.h), and otherwise in
    # the order listed in the exercise's config.
    class ExampleSolutionFiles
      include Mandate

      initialize_with :solutions, :examples

      def call
        remaining = Array(examples).dup

        Array(solutions).each_with_object({}) do |solution, pairs|
          example = remaining.find { |file| File.extname(file) == File.extname(solution) } || remaining.first
          next unless example

          remaining.delete(example)
          pairs[solution] = example
        end
      end
    end
  end
end
