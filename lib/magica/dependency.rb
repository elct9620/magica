module Magica
  # :nodoc:
  # rubocop:disable Metrics/ClassLength
  class Dependency
    class << self
      def [](name)
        @dependencies ||= {}
        @dependencies[name.to_s]
      end

      def []=(name, value)
        @dependencies ||= {}
        @dependencies[name.to_s] = value
      end
    end

    include Rake::DSL

    # rubocop:disable Metrics/MethodLength
    def initialize(builder, name, _options = {}, &block)
      @builder = builder
      @name = name.to_s
      @vcs = nil
      @command = :git
      @source = ''
      @version = nil
      @dir = "lib/#{@name}"
      @install_dir = "#{@dir}/build"
      @build_command = 'make'
      @clean_command = ''
      @environments = {}

      @static_libraries = []

      Dependency[name] = self
      Dependency[name].instance_eval(&block)

      add_header "#{@dir}/include" if Dir.exist?("#{@dir}/include")
    end
    # rubocop:enable Metrics/MethodLength

    def use(name)
      @vcs = name.to_sym
    end

    def env(name, value)
      @environments[name.to_s] = value
    end

    def source(source)
      @source = source.to_s
    end

    def dir(dir)
      @dir = dir.to_s
    end

    def install_dir(dir)
      @install_dir = dir.to_s
    end

    def version(version)
      @version = version.to_s
    end

    def command(command)
      @build_command = command.to_s
    end

    def clean_command(command)
      @clean_command = command.to_s
    end

    def static_library(*name)
      @static_libraries.push(*name.flatten)
    end

    def build
      clean if @builder.options[:clean_all]

      return unless exec?

      setup_environment
      clone
      exec
    end

    def add_src(*paths)
      @builder.source(@builder.sources + paths)
    end

    def add_header(*paths)
      @builder.include_path(paths)
    end

    def static_libraries
      @static_libraries.map do |library|
        File.join(*[
          Magica.root, @install_dir, library
        ].flatten.reject(&:empty?))
      end
    end

    private

    def exec?
      clean_all = @builder.options[:clean_all]
      return true if @builder.options[:rebuild]
      return false if !clean_all & File.exist?(@install_dir)
      return false if !clean_all & @build_command.empty? & File.exist?(@dir)
      true
    end

    def exec
      root = Dir.pwd
      Dir.chdir source_dir
      sh @build_command, verbose: false unless @build_command.empty?
      Dir.chdir root
    end

    # rubocop:disable Metrics/MethodLength
    def clone
      return if @builder.options[:rebuild]
      @vcs = @builder.send(@command)
      @vcs.flags = %w[--quiet]

      puts "UPDATE DEPENDENCY\t #{[@name, @version].join(' ')}"

      if Dir.exist?(source_dir)
        checkout if @version
        pull
      else
        @vcs.clone(source_dir, @source)
        checkout if @version
      end
    end
    # rubocop:enable Metrics/MethodLength

    def checkout
      @vcs.checkout(source_dir, @version)
    end

    def pull
      @vcs.pull(source_dir, 'origin', @version)
    end

    def source_dir
      File.join(Magica.root, @dir)
    end

    def setup_environment
      @environments.each do |name, value|
        ENV[name] = value
      end
    end

    def clean
      return FileUtils.rm_r(@install_dir, force: true) if @clean_command.empty?
      root = Dir.pwd
      Dir.chdir source_dir
      sh @clean_command, verbose: false
      Dir.chdir root
    end
  end
end
