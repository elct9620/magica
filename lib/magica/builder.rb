module Magica
  class Builder
    include Rake::DSL

    COMPILERS = %w(cxx)
    COMMANDS = COMPILERS + %w(linker)

    attr_block COMMANDS

    def initialize(name = 'host', dest = 'build', &block)
      @name = name.to_s
      @dest = dest.to_s
      @sources = FileList["src/**/*.cpp"]
      @cxx = Command::Compiler.new(self, %w(.cpp))
      @linker = Command::Linker.new(self)
      @defines = %w()
      @include_paths = %w()
      @libaries = %w()
      @libary_paths = %w()
      @flags = %w()

      Magica.targets[@name] = self
      Magica.targets[@name].instance_eval(&block) unless block.nil?

      Magica.default_toolchain.setup(self, Magica.toolchain_params) if Magica.default_toolchain
    end

    def define(name)
      @defines << name.to_s.upcase
    end

    def include_path(path)
      @include_paths << path.to_s
    end

    def flag(flag)
      @flags << flag.to_s
    end

    def library(name, path)
      @libaries << name.to_s
      @libary_paths << path.to_s
    end

    def source(path)
      @sources = FileList[path]
    end

    def filename(name)
      '"%s"' % name
    end

    def exefile(name)
      if name.is_a?(Array)
        name.flatten.map { |n| exefile(n) }
      else
        "#{name}"
      end
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
        @cxx.run t.name, t.prerequisites.first, @defines, @include_paths, @flags
      end
    end

    def link(exec, objects)
      task "build:#{@name}" => objects do
        @linker.run "#{exec}", objects, @libaries, @libary_paths, @flags
      end
    end
  end
end
