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

      @exe_name = @name
      @exe_path = "bin"

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

    def dynamic_library(name)
      config = PackageConfig[name]
      @libaries.push(*config.libaries)
      @libary_paths.push(*config.libary_paths)
      @include_paths.push(*config.include_paths)
      @defines.push(*config.defines)
      @flags.push(*config.flags)
    end

    def source(path)
      @sources = FileList[path]
    end

    def dest(path)
      @dest = path.to_s
    end

    def filename(name)
      '"%s"' % name
    end

    def exe_path(path)
      @exe_path = path.to_s
    end

    def exe_name(name)
      @exe_name = name.to_s
    end

    def exefile(name = nil)
      return exefile(@exe_name) if name.nil?
      if name.is_a?(Array)
        name.flatten.map { |n| exefile(n) }
      else
        File.join(*[Magica.root, @exe_path, "#{name}"].flatten.reject(&:empty?))
      end
    end

    def libfile
    end

    def objfile(name)
      if name.is_a?(Array)
        name.flatten.map { |n| objfile(n) }
      else
        File.join(*[Magica.root, @dest, "#{name}.o"].flatten.reject(&:empty?))
      end
    end

    def clear_dest
      path = File.join(*[Magica.root, @dest].flatten.reject(&:empty?))
      FileUtils.rm_r(path, force: true)
    end

    def clear_exe
      path = File.join(*[Magica.root, @exe_path].flatten.reject(&:empty?))
      FileUtils.rm_r(path, force: true)
    end

    def clean
      clear_dest
      clear_exe
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
