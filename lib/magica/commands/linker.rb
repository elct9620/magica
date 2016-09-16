module Magica
  class Command::Linker < Command
    attr_accessor :flags

    def initialize(build)
      super

      @command = ENV['LD'] || 'ld'
      @flags = (ENV['LDFLAGS'] || [])
      @link_options = "%{flags} -o %{outfile} %{objects}"
    end

    def run(outfile, objects)
      _run @link_options, { outfile: outfile, objects: objects.join(" "), flags: "" }
    end
  end
end
