module Magica
  class << self
    attr_accessor :default_toolchain, :toolchain_params

    def targets
      @targets ||= {}
    end

    def each_target(&block)
      return to_enum(:each_target) if block.nil?
      @targets.each do |key, target|
        target.instance_eval(&block)
      end
    end

    def default_compile_task
      proc { |options|
        FileUtils.rm_r(@dest, force: true) if options[:clean]

        objects = objfile(@sources)
        @sources.each { |source| compile source }

        link exefile("#{@dest}/#{@name}"), objects
      }
    end
  end
end
