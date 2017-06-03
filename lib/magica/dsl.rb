module Magica
  # :nodoc:
  module DSL
    def toolchain(name, params = {})
      toolchain = Toolchain.toolchains[name.to_s]
      raise I18n.t('magica.unknow_toolchain', toolchain: name) if toolchain.nil?
      Magica.default_toolchain = toolchain
      Magica.toolchain_params = params
    end

    def build(name = 'host', options = { dest: 'build' }, &block)
      Build.new(name, options, &block)
    end

    def exefile(name = nil)
      Build.current.exefile(name)
    end
  end
end

extend Magica::DSL
