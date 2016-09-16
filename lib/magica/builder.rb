module Magica
  class Builder
    include Rake::DSL

    COMPILERS = %w(cxx)
    COMMANDS = COMPILERS + %w(linker)

    attr_accessor *COMMANDS.map(&:to_sym)

    def initialize(name = 'host', dest = 'build', &block)
      @name = name.to_s
      @dest = dest.to_s
      @cxx = Command::Compiler.new(self, %w(.cpp))
      @linker = Command::Linker.new(self)

      Magica.targets[@name] = self
      Magica.targets[@name].instance_eval(&block)
    end

    def filename
    end

    def exefile
    end

    def libfile
    end

    def objfile(name)
      if name.is_a?(Array)
        name.flatten.map { |n| objfile(n) }
      else
        "build/#{name}.o"
      end
    end

    def toolchain(name, params = {})
      toolchain = Toolchain.toolchains[name]
      fail "Unknow #{name} toolchain" unless toolchain
      toolchain.setup(self, params)
    end

    def compile(source)
      file objfile(source) => source do |t|
        @cxx.run t.name, t.prerequisites.first
      end
    end
  end
end
