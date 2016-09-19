module Magica
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

    def initialize(name, options = {}, &block)

      @name = name.to_s
      @vcs = nil
      @command = :git
      @source = ""
      @version = nil
      @dir = "lib/#{@name}"
      @install_dir = "#{@dir}/build"
      @build_command = "make"

      @static_libraries = []

      Dependency[name] = self
      Dependency[name].instance_eval(&block)
    end

    def use(name)
      @vcs = name.to_sym
    end

    def source(_source)
      @source = _source.to_s
    end

    def dir(_dir)
      @dir = _dir.to_s
    end

    def install_dir(_dir)
      @install_dir = _dir.to_s
    end

    def version(_version)
      @version = _version.to_s
    end

    def command(_command)
      @build_command = _command.to_s
    end

    def static_library(*name)
      @static_libraries.push(*name.flatten)
    end

    def build(builder)
      root = Dir.pwd
      @vcs = builder.send(@command)
      clone
      Dir.chdir source_dir
      sh @build_command
      Dir.chdir root
    end

    def static_libraries
      @static_libraries.map do |library|
        File.join(*[Magica.root, @install_dir, library].flatten.reject(&:empty?))
      end
    end

    private
    def clone
      if Dir.exists?(source_dir)
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

  end
end
