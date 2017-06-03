module Magica
  # :nodoc:
  class PackageConfig
    class << self
      def [](name)
        @packages ||= {}
        config = @packages[name.to_s]
        config = @packages[name.to_s] = PackageConfig.new(name) if config.nil?
        config
      end
    end

    LIBRARY_PATH_RULE = /-L([^\s]+)/
    LIBRARY_RULE = /-l([^\s]+)/
    LIBRARY_FLAG_RULE = /-[^lL][^\s]+/
    INCLUDE_RULE = /-I([^\s]+)/
    DEFINE_RULE = /-D([^\s]+)/
    FLAG_RULE = /-[^ID][^\s]+/

    attr_reader :library_paths, :libraries, :library_flags,
                :include_paths, :defines, :flags, :version

    def initialize(name)
      raise "Cannot found library #{name}" unless package_exist?(name)
      @name = name

      @package_libraries = `pkg-config --libs #{@name}`.strip
      @package_cflags = `pkg-config --cflags #{@name}`.strip

      @version = `pkg-config --modversion #{@name}`.strip
    end

    def package_exist?(name)
      system "pkg-config --exists #{name}"
    end

    def libraries
      @libraries ||= @package_libraries.scan(LIBRARY_RULE).flatten
    end

    def library_flags
      @library_flags ||= @package_libraries.scan(LIBRARY_FLAG_RULE).flatten
    end

    def library_paths
      @library_paths ||= @package_libraries.scan(LIBRARY_PATH_RULE).flatten
    end

    def flags
      @flags ||= @package_cflags.scan(FLAG_RULE).flatten
    end

    def defines
      @defines ||= @package_cflags.scan(DEFINE_RULE).flatten
    end

    def include_paths
      @include_paths ||= @package_cflags.scan(INCLUDE_RULE).flatten
    end
  end
end
