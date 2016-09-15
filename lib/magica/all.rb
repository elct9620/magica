require "rake"

require "magica/i18n"
require "magica/dsl"
require "magica/toolchain"
require "magica/builder"
require "magica/application"

module Magica
  class << self
    def targets
      @targets ||= {}
    end

    def each_target(&block)
      return to_enum(:each_target) if block.nil?
      @targets.each do |key, target|
        target.instance_eval(&block)
      end
    end
  end
end
