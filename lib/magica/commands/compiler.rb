module Magica
  # rubocop:disable Style/FormatStringToken
  class Command
    # :nodoc:
    class Compiler < Command
      attr_accessor :flags

      def initialize(build, source_exts = [])
        super(build)

        @command = ENV['CC'] || 'cc'
        @flags = [ENV['CFLAGS'] || []]
        @source_exts = source_exts
        @compile_options = '%{flags} -o %{outfile} -c %{infile}'
        @include_paths = ['include']
        @defines = %w[]

        @option_include_path = '-I%s'
        @option_defines = '-D%s'
      end

      def combine_flags(defines = [], include_paths = [], flags = [])
        define_flags = [
          @defines, defines
        ].flatten.map { |define| @option_defines % define }
        include_path_flags = [
          @include_paths, include_paths
        ].flatten.map do |include_path|
          @option_include_path % filename(include_path)
        end
        [define_flags, include_path_flags, flags].flatten.uniq.join(' ')
      end

      def run(outfile, infile, defines = [], include_paths = [], flags = [])
        FileUtils.mkdir_p File.dirname(outfile)
        puts "COMPILE\t#{outfile}"
        _run(@compile_options,
             outfile: outfile,
             infile: infile,
             flags: combine_flags(defines, include_paths, flags))
      end
    end
  end
end
