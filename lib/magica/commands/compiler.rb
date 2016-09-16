module Magica
  class Command::Compiler < Command
    attr_accessor :flags

    def initialize(build, source_exts = [])
      super(build)

      @command = ENV['CC'] || 'cc'
      @flags = [ENV['CFLAGS'] || []]
      @source_exts = source_exts
      @compile_options = "%{flags} -o %{outfile} -c %{infile}"
    end

    def run(outfile, infile)
      FileUtils.mkdir_p File.dirname(outfile)
      _run @compile_options, { outfile: outfile, infile: infile, flags: "" }
    end
  end
end
