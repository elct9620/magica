include Magica::DSL

require 'magica/framework'

module Magica
  # :nodoc:
  class Target < Build
    def target(name, **options, &block)
      return if block.nil?
      name = name.to_sym
      @targets[name] = block
      @default_target = name if options[:default]
    end

    def dependency(name, options = {}, &block)
      Dependency.new(name, options, &block)
      task "#{@name}:dependency:#{name}" do
        Dependency[name].build(self)
      end
      @dependencies << "#{@name}:dependency:#{name}"
      @static_libraries.push(*Dependency[name].static_libraries)
    end
  end
end
