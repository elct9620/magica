module Magica
  class PackageConfig
    class << self
      def [](name)
        @packages ||= {}
        config = @packages[name.to_s]
        config = @packages[name.to_s] = PackageConfig.new(name) if config.nil?
        config
      end
    end

    LIBARY_PATH_RULE = /-L([^\s]+)/
    LIBARY_RULE = /-l([^\s]+)/
    LIBARY_FLAG_RULE = /-[^lL][^\s]+/
    INCLUDE_RULE = /-I([^\s]+)/
    DEFINE_RULE = /-D([^\s]+)/
    FLAG_RULE = /-[^ID][^\s]+/

    attr_reader :libary_paths, :libaries, :libary_flags, :include_paths, :defines, :flags

    def initialize(name)
      fail "Cannot found library #{name}" unless system "pkg-config --exists #{name}"

      @package_libaries = `pkg-config --libs #{name}`.strip

      @libary_paths = @package_libaries.scan(LIBARY_PATH_RULE).flatten
      @libaries = @package_libaries.scan(LIBARY_RULE).flatten
      @libary_flags = @package_libaries.scan(LIBARY_FLAG_RULE).flatten

      @package_cflags = `pkg-config --cflags #{name}`.strip
      @include_paths = @package_cflags.scan(INCLUDE_RULE).flatten
      @defines = @package_cflags.scan(DEFINE_RULE).flatten
      @flags = @package_cflags.scan(FLAG_RULE).flatten

      @version = `pkg-config --modversion #{name}`.strip
    end
  end
end
