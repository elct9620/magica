module Magica
  class Builder
    include Rake::DSL

    COMPILERS = %w(cxx)
    COMMANDS = COMPILERS + %w(linker)

    attr_accessor *COMMANDS.map(&:to_sym)

    def initialize(name = 'host', dest = 'build', &block)
      @name = name.to_s
      @dest = dest.to_s
      @sources = FileList["src/**/*.cpp"]
      @cxx = Command::Compiler.new(self, %w(.cpp))
      @linker = Command::Linker.new(self)

      Magica.targets[@name] = self
      Magica.targets[@name].instance_eval(&block) unless block.nilk

      Magica.default_toolchain.setup(self, Magica.toolchain_params) if Magica.default_toolchain
    end

    def source(path)
      @sources = FileList[path]
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
        "#{@dest}/#{name}.o"
      end
    end

    def toolchain(name, params = {})
      toolchain = Toolchain.toolchains[name]
      fail I18n.t("magica.unknow_toolchain", toolchain: name) unless toolchain
      toolchain.setup(self, params)
    end

    def compile(source)
      file objfile(source) => source do |t|
        @cxx.run t.name, t.prerequisites.first
      end
    end
  end
end
