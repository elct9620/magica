module Magica
  class Command::Linker < Command
    attr_accessor :flags

    def initialize(build)
      super

      @command = ENV['LD'] || 'ld'
      @flags = (ENV['LDFLAGS'] || [])
      @link_options = "%{flags} -o %{outfile} %{objects} %{libs}"
      @libaries = []
      @libary_paths = []

      @option_libary = "-l%s"
      @option_libary_path = "-L%s"
    end

    def combine_flags(_library_paths = [], _flags = [])
      libary_paths = [@libary_paths, _library_paths].flatten.map { |path| @option_libary_path % filename(path) }
      [flags, libary_paths, _flags].flatten.uniq.join(" ")
    end

    def run(outfile, objects, _libaries = [], _library_paths = [], _flags = [])
      FileUtils.mkdir_p File.dirname(outfile)

      libary_flags = [@libaries, _libaries].flatten.map { |library| @option_libary % library }

      puts "LINK\t#{outfile}"
      _run @link_options, {
        outfile: outfile,
        objects: objects.join(" "),
        libs: libary_flags.uniq.join(" "),
        flags: combine_flags(_library_paths, _flags)
      }
    end
  end
end
