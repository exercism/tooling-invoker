module ToolingInvoker
  class RuntimeEnvironment

    attr_reader :container_dir, :iteration_dir, :source_code_dir, 
                :rootfs_source, :track_slug, :iteration_id

    def initialize(containers_dir, container_version, track_slug, iteration_id)
      track_containers_dir = "#{containers_dir}/#{track_slug}"

      if !container_version || container_version.empty?
        container_version = File.readlink("#{track_containers_dir}/current").split('/').last
      end

      @container_dir = "#{track_containers_dir}/releases/#{container_version}"
      @iteration_dir = "#{container_dir}/runs/iteration_#{Time.now.to_i}-#{iteration_id}-#{SecureRandom.hex}"
      @source_code_dir = "#{iteration_dir}/code"
      @rootfs_source = "#{container_dir}/rootfs"
    end

    def container_exists?
      Dir.exist?(container_dir)
    end
  end
end

