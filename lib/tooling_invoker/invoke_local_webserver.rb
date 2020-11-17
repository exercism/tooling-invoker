module ToolingInvoker
  class InvokeLocalWebserver
    include Mandate

    def initialize(job)
      @job = job
    end

    def call
      FileUtils.mkdir_p(job.source_code_dir)

      SetupInputFiles.(job)

      zip_file = "#{job.dir}/files.zip"
      ZipFileGenerator.new(job.source_code_dir, zip_file).write

      resp = RestClient.post("http://#{job.tool}:4567/job", {
                               zipped_files: File.read(zip_file),
                               output_filepaths: job.output_filepaths.join(','),
                               exercise: job.exercise,
                               working_directory: job.working_directory
                             })

      json = JSON.parse(resp.body)

      job.stdout = ""
      job.stderr = ""
      job.output = json['output_files']
      job.output ? job.succeeded! : job.exceptioned!("No output")
    end

    private
    attr_reader :job
  end

  require 'zip'

  # This is a simple example which uses rubyzip to
  # recursively generate a zip file from the contents of
  # a specified directory. The directory itself is not
  # included in the archive, rather just its contents.
  #
  # Usage:
  #   directory_to_zip = "/tmp/input"
  #   output_file = "/tmp/out.zip"
  #   zf = ZipFileGenerator.new(directory_to_zip, output_file)
  #   zf.write()
  class ZipFileGenerator
    # Initialize with the directory to zip and the location of the output archive.
    def initialize(input_dir, output_file)
      @input_dir = input_dir
      @output_file = output_file
    end

    # Zip the input directory.
    def write
      entries = Dir.entries(@input_dir) - %w[. ..]

      ::Zip::File.open(@output_file, ::Zip::File::CREATE) do |zipfile|
        write_entries entries, '', zipfile
      end
    end

    private
    # A helper method to make the recursion work.
    def write_entries(entries, path, zipfile)
      entries.each do |e|
        zipfile_path = path == '' ? e : File.join(path, e)
        disk_file_path = File.join(@input_dir, zipfile_path)

        if File.directory? disk_file_path
          recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
        else
          put_into_archive(disk_file_path, zipfile, zipfile_path)
        end
      end
    end

    def recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
      zipfile.mkdir zipfile_path
      subdir = Dir.entries(disk_file_path) - %w[. ..]
      write_entries subdir, zipfile_path, zipfile
    end

    def put_into_archive(disk_file_path, zipfile, zipfile_path)
      zipfile.add(zipfile_path, disk_file_path)
    end
  end
end
