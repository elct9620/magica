include Magica::DSL

require "magica/framework"

load File.expand_path("../tasks/build.rake", __FILE__)

module Magica
  class Build
    class << self
      attr_accessor :current
    end

    include Rake::DSL

    COMPILERS = %w(cc cxx)
    COMMANDS = COMPILERS + %w(linker git)

    attr_reader :options
    attr_block COMMANDS

    Exts = Struct.new(:object, :executable, :library)

    def initialize(name = 'host', options = {dest: 'build'}, &block)
      @name = name.to_s
      @dest = (options[:dest] || 'build').to_s
      @sources = FileList["src/**/*.cpp"]
      @options = OpenStruct.new(options.merge(Rake.application.options.to_h))

      @exe_name = @name
      @exe_path = "bin"

      @exts = Exts.new('.o', '', '.a')

      @cc = Command::Compiler.new(self, %w(.c))
      @cxx = Command::Compiler.new(self, %w(.cpp))
      @linker = Command::Linker.new(self)

      @compiler = @cc

      @git = Command::Git.new(self)

      @defines = %w()
      @include_paths = %w()
      @libraries = %w()
      @library_paths = %w()
      @flags = %w()

      @dependencies = []
      @static_libraries = []

      Magica.targets[@name] = self
      Magica.targets[@name].instance_eval(&block) unless block.nil?
      Magica.targets[@name].instance_exec(@options, &Magica.default_compile_task)

      Magica.default_toolchain.setup(self, Magica.toolchain_params) if Magica.default_toolchain
    end

    def define(name, value = nil)
      if name.is_a?(Array)
        name.flatten.map { |n| define(n, value) }
      else
        _define = name.to_s.upcase
        value = '\"%{value}\"' % {value: value} unless value.is_a?(Fixnum)
        _define << "=#{value}" unless value.nil?
        @defines << _define
      end
      @defines
    end

    def include_path(path)
      if path.is_a?(Array)
        path.flatten.map  { |p| include_path(p) }
      else
        @include_paths << path.to_s
      end
      @include_paths
    end

    def flag(flag)
      if flag.is_a?(Array)
        flag.flatten.map { |f| flag(f) }
      else
        @flags << flag.to_s
      end
      @flags
    end

    def library(name, path = nil)
      @libraries << name.to_s
      @library_paths << path.to_s if path
    end

    def library_path(path)
      @library_path << path.to_s
    end

    def dynamic_library(name)
      config = PackageConfig[name]
      @libraries.push(*config.libraries)
      @library_paths.push(*config.library_paths)

      include_path(config.include_paths)
      define(config.defines)
      flag(config.flags)
    end

    def source(*paths, **options)
      @sources = FileList.new(*paths)
      @sources = @sources.exclude(options[:exclude]) if options[:exclude]
    end

    def exclude(*patterns)
      @sources = @sources.exclude(*patterns)
    end

    def dest(path)
      @dest = path.to_s
    end

    def dependency(name, options = {}, &block)
      Dependency.new(name, options, &block)
      desc "The targets #{@name}'s dependency project : #{name}"
      task "#{@name}:dependency:#{name}" do |t|
        Dependency[name].build(self)
      end
      @dependencies << "#{@name}:dependency:#{name}"
      @static_libraries.push(*Dependency[name].static_libraries)
    end

    def use(compiler)
      return @compiler = self.send(compiler.to_s) if COMPILERS.include?(compiler.to_s)
      @compiler = @cc
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
      return exefile("#{@exe_name}#{@exts.executable}") if name.nil?
      if name.is_a?(Array)
        name.flatten.map { |n| exefile(n) }
      else
        File.join(*[Magica.root, @exe_path, "#{name}#{@exts.executable}"].flatten.reject(&:empty?))
      end
    end

    def libfile
    end

    def objfile(name)
      if name.is_a?(Array)
        name.flatten.map { |n| objfile(n) }
      else
        File.join(*[Magica.root, @dest, "#{name}#{@exts.object}"].flatten.reject(&:empty?))
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

    def add(source)
      FileUtils.cp(source, File.join(*[Magica.root, @dest].flatten.reject(&:empty?)))
    end

    def toolchain(name, params = {})
      toolchain = Toolchain.toolchains[name]
      fail I18n.t("magica.unknow_toolchain", toolchain: name) unless toolchain
      toolchain.setup(self, params)
    end

    def compile(source)
      file objfile(source) => source do |t|
        Build.current = Magica.targets[@name]
        @compiler.run t.name, t.prerequisites.first, @defines, @include_paths, @flags
      end
    end

    def link(exec, objects)
      desc "Build target #{@name}'s executable file"
      task "build:#{@name}" => @dependencies + objects  do
        Build.current = Magica.targets[@name]
        @linker.run "#{exec}", objects + @static_libraries, @libraries, @library_paths, @flags
      end
    end

    def build_task(&block)
      Magica.targets[@name].instance_eval(@options, &block)
    end
  end
end
