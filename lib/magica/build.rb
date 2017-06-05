include Magica::DSL

require 'magica/framework'

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/LineLength
# rubocop:disable Metrics/MethodLength
module Magica
  # :nodoc:
  class Build
    class << self
      attr_accessor :current
    end

    include Rake::DSL

    COMPILERS = %w[cc cxx].freeze
    COMMANDS = COMPILERS + %w[linker git]

    attr_reader :sources, :options, :defines, :include_paths, :flags
    attr_block COMMANDS

    Exts = Struct.new(:object, :executable, :library)

    # rubocop:disable Metrics/AbcSize
    def initialize(name = 'host', options = { dest: 'build' }, &block)
      @name = name.to_s
      @dest = (options[:dest] || 'build').to_s
      @sources = FileList['src/**/*.cpp']
      @options = OpenStruct.new(options.merge(Rake.application.options.to_h))
      @default_target = nil
      @config_block = block
      @targets = {}

      @exe_name = @name
      @exe_path = 'bin'

      @exts = Exts.new('.o', '', '.a')

      @cc = Command::Compiler.new(self, %w[.c])
      @cxx = Command::Compiler.new(self, %w[.cpp])
      @linker = Command::Linker.new(self)

      @compiler = @cc

      @git = Command::Git.new(self)

      @defines = %w[]
      @include_paths = %w[]
      @libraries = %w[]
      @library_paths = %w[]
      @flags = %w[]

      @dependencies = []
      @static_libraries = []

      Magica.builds[@name] = self
      Magica.builds[@name].instance_eval(&block) unless block.nil?
      Magica.builds[@name].instance_exec(@options, &Magica.default_compile_task)

      Magica.default_toolchain.setup(self, Magica.toolchain_params) if Magica.default_toolchain
    end
    # rubocop:enable Metrics/AbcSize

    def target(name, **options, &block)
      return if block.nil?
      name = name.to_sym
      @targets[name] = block
      @default_target = name if options[:default]
      Target.new("#{@name}:#{name}", @options.to_h.merge(target: name), &@config_block) if Magica.const_defined?('Target')
    end

    def define(name, value = nil)
      if name.is_a?(Array)
        name.flatten.map { |n| define(n, value) }
      else
        define_name = name.to_s.upcase
        unless value.nil? || value.is_a?(Numeric)
          value = format('\"%s\"', value)
        end
        define_name << "=#{value}" unless value.nil?
        @defines.push(define_name)
      end
      @defines.uniq!
    end

    def include_path(path)
      if path.is_a?(Array)
        path.flatten.map { |p| include_path(p) }
      else
        @include_paths.push(path.to_s)
      end
      @include_paths
    end

    def flag(flag)
      if flag.is_a?(Array)
        flag.flatten.map { |f| flag(f) }
      else
        @flags.push(flag.to_s)
      end
      @flags
    end

    def library(name, path = nil)
      @libraries.push(name.to_s).uniq!
      @library_paths.push(path.to_s).uniq! if path
    end

    def library_path(path)
      @library_paths.push(path.to_s).uniq!
    end

    def dynamic_library(name)
      config = PackageConfig[name]
      @libraries.push(*config.libraries).uniq!
      @library_paths.push(*config.library_paths).uniq!

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

    def include(*patterns)
      @sources = @sources.include(*patterns)
    end

    def dest(path)
      @dest = path.to_s
    end

    def dependency(name, options = {}, &block)
      Dependency.new(self, name, options, &block)
      desc "The targets #{@name}'s dependency project : #{name}"
      task "#{@name}:dependency:#{name}" do
        Dependency[name].build(self)
      end
      @dependencies << "#{@name}:dependency:#{name}"
      @static_libraries.push(*Dependency[name].static_libraries)
    end

    def use(compiler)
      return @compiler = send(compiler.to_s) if COMPILERS.include?(compiler.to_s)
      @compiler = @cc
    end

    def filename(name)
      format('"%s"', name)
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
        File.join(
          *[Magica.root, @exe_path, "#{name}#{@exts.executable}"]
          .flatten.reject(&:empty?)
        )
      end
    end

    def objfile(name)
      if name.is_a?(Array)
        name.flatten.map { |n| objfile(n) }
      else
        File.join(
          *[Magica.root, @dest, "#{name}#{@exts.object}"]
          .flatten.reject(&:empty?)
        )
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
      FileUtils.cp(
        source,
        File.join(*[Magica.root, @dest].flatten.reject(&:empty?))
      )
    end

    def toolchain(name, params = {})
      toolchain = Toolchain.toolchains[name]
      raise I18n.t('magica.unknow_toolchain', toolchain: name) unless toolchain
      toolchain.setup(self, params)
    end

    def compile(source)
      return if Rake::Task.task_defined?(objfile(source))
      file objfile(source) => source do |t|
        @compiler.run(
          t.name,
          t.prerequisites.first,
          Build.current.defines,
          Build.current.include_paths,
          Build.current.flags
        )
      end
    end

    def link(exec, objects)
      desc "Build #{@name}'s executable file"
      task @name.to_s do
        Build.current = Magica.builds[@name]
        task "#{@name}:build" => @dependencies + objects do
          @linker.run(
            exec.to_s,
            objects + @static_libraries,
            @libraries,
            @library_paths,
            @flags
          )
        end.invoke
      end
    end

    def do_target(name = nil)
      name ||= @default_target
      return if name.nil?
      target = @targets[name.to_sym]
      @sources.clear_exclude # Reset exclude files
      @exe_name = name.to_s.capitalize
      Magica.builds[@name].instance_eval(&target) unless target.nil?
    end

    def build_task(&block)
      Magica.builds[@name].instance_eval(@options, &block)
    end
  end
end
