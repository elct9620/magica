module Magica
  # rubocop:disable Style/FormatStringToken
  class Command
    # :nodoc:
    class Linker < Command
      attr_accessor :flags

      def initialize(build)
        super

        @command = ENV['LD'] || 'ld'
        @flags = (ENV['LDFLAGS'] || [])
        @link_options = '%{flags} -o %{outfile} %{objects} %{libs}'
        @libraries = []
        @library_paths = []

        @option_library = '-l%s'
        @option_library_path = '-L%s'
      end

      def combine_flags(library_paths = [], flags = [])
        library_paths = [
          @library_paths, library_paths
        ].flatten.map { |path| @option_library_path % filename(path) }
        [flags, library_paths, flags].flatten.uniq.join(' ')
      end

      def run(outfile, objects, libraries = [], library_paths = [], flags = [])
        FileUtils.mkdir_p File.dirname(outfile)

        library_flags = [
          @libraries, libraries
        ].flatten.map { |library| @option_library % library }

        puts "LINK\t#{outfile}"
        _run(@link_options,
             outfile: outfile,
             objects: objects.join(' '),
             libs: library_flags.uniq.join(' '),
             flags: combine_flags(library_paths, flags))
      end
    end
  end
end
