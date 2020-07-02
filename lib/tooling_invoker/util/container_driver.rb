module ToolingInvoker
  module Util
    class ContainerDriver
      attr_accessor :runc, :img, :configurator, :workdir

      def initialize(runc, img, configurator, workdir)
        @runc = runc
        @img = img
        @configurator = configurator
        @workdir = workdir
      end

      # def unpack_image(build_tag)
      #   puts "unpack #{build_tag}"
      #   Dir.chdir(workdir) do
      #     img.unpack(build_tag)
      #   end
      #   configurator.setup_for_terminal_access
      #   File.write("#{workdir}/terminal_config.json", configurator.build.to_json)
      # end

      def invoke(container_work_dir, args)
        configurator.setup_invocation_args(container_work_dir, args)
        File.write("#{workdir}/invocation_config.json", configurator.build.to_json)
        FileUtils.symlink("#{workdir}/invocation_config.json", "#{workdir}/config.json", force: true)
        runc.run(workdir)
      end
    end
  end
end
