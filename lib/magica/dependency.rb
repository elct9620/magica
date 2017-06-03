module Magica
  # :nodoc:
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
    def initialize(name, _options = {}, &block)
      @name = name.to_s
      @vcs = nil
      @command = :git
      @source = ''
      @version = nil
      @dir = "lib/#{@name}"
      @install_dir = "#{@dir}/build"
      @build_command = 'make'
      @environments = {}

      @static_libraries = []

      Dependency[name] = self
      Dependency[name].instance_eval(&block)
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

    def static_library(*name)
      @static_libraries.push(*name.flatten)
    end

    def build(builder)
      options = builder.send(:options)
      clean if options[:clean_all]

      return if !options[:clean_all] & File.exist?(@install_dir)

      setup_environment
      clone(builder)
      exec
    end

    def static_libraries
      @static_libraries.map do |library|
        File.join(*[
          Magica.root, @install_dir, library
        ].flatten.reject(&:empty?))
      end
    end

    private

    def exec
      root = Dir.pwd
      Dir.chdir source_dir
      sh @build_command, verbose: false
      Dir.chdir root
    end

    def clone(builder)
      @vcs = builder.send(@command)
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
      FileUtils.rm_r(@install_dir, force: true)
    end
  end
end
