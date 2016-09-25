module Magica
  class Command::Linker < Command
    attr_accessor :flags

    def initialize(build)
      super

      @command = ENV['LD'] || 'ld'
      @flags = (ENV['LDFLAGS'] || [])
      @link_options = "%{flags} -o %{outfile} %{objects} %{libs}"
      @libraries = []
      @library_paths = []

      @option_library = "-l%s"
      @option_library_path = "-L%s"
    end

    def combine_flags(_library_paths = [], _flags = [])
      library_paths = [@library_paths, _library_paths].flatten.map { |path| @option_library_path % filename(path) }
      [flags, library_paths, _flags].flatten.uniq.join(" ")
    end

    def run(outfile, objects, _libraries = [], _library_paths = [], _flags = [])
      FileUtils.mkdir_p File.dirname(outfile)

      library_flags = [@libraries, _libraries].flatten.map { |library| @option_library % library }

      puts "LINK\t#{outfile}"
      _run @link_options, {
        outfile: outfile,
        objects: objects.join(" "),
        libs: library_flags.uniq.join(" "),
        flags: combine_flags(_library_paths, _flags)
      }
    end
  end
end
