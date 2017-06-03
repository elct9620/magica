# :nodoc:
module Magica
  # :nodoc:
  class Toolchain
    include Rake::DSL

    class << self
      attr_accessor :toolchains
    end

    def initialize(name, &block)
      @name = name.to_s
      @initializer = block
      Toolchain.toolchains ||= {}
      Toolchain.toolchains[@name] = self
    end

    def setup(builder, options = {})
      builder.instance_exec(builder, options, &@initializer)
    end

    def self.load
      builtin_path = File.join(File.dirname(__FILE__), 'toolchains')
      Dir.glob("#{builtin_path}/*.rake").each do |file|
        Kernel.load file
      end
    end
  end

  Toolchain.load
end
