# :nodoc:
class Object
  class << self
    # rubocop:disable Metrics/LineLength
    def attr_block(*syms)
      syms.flatten.each do |sym|
        class_eval "def #{sym}(&block); block.call(#{sym}) if block_given?; @#{sym}; end"
      end
    end
  end
end
