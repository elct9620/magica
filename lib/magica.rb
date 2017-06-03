require 'magica/version'
require 'magica/all'

# Magica
module Magica
  class << self
    attr_accessor :default_toolchain, :toolchain_params

    def builds
      @builds ||= {}
    end

    def each_build(&block)
      return to_enum(:each_build) if block.nil?
      @builds.each do |_, build|
        build.instance_eval(&block)
      end
    end

    def root
      Dir.pwd
    end

    def default_compile_task
      proc { |options|
        clean if options[:clean]

        do_target(options[:target])

        objects = objfile(@sources)
        @sources.each { |source| compile source }

        link exefile, objects
      }
    end
  end
end
