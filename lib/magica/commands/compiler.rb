module Magica
  class Command::Compiler < Command
    attr_accessor :flags

    def initialize(build, source_exts = [])
      super(build)

      @command = ENV['CC'] || 'cc'
      @flags = [ENV['CFLAGS'] || []]
      @source_exts = source_exts
      @compile_options = "%{flags} -o %{outfile} -c %{infile}"
      @include_paths = ["include"]
      @defines = %w()

      @option_include_path = "-I%s"
      @option_defines = "-D%s"
    end

    def combine_flags(_defines = [], _include_paths = [], _flags = [])
      define_flags = [@defines, _defines].flatten.map { |define| @option_defines % define }
      include_path_flags = [@include_paths, _include_paths].flatten.map { |include_path| @option_include_path % filename(include_path) }
      [define_flags, include_path_flags, _flags].flatten.uniq.join(' ')
    end

    def run(outfile, infile, _defines = [], _include_paths = [], _flags = [])
      FileUtils.mkdir_p File.dirname(outfile)
      _run @compile_options, { outfile: outfile, infile: infile, flags: combine_flags(_defines, _include_paths, _flags) }
    end
  end
end
