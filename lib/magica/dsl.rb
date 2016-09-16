module Magica
  module DSL
    def toolchain(name, params = {})
      toolchain = Toolchain.toolchains[name.to_s]
      fail I18n.t("magica.unknow_toolchain", toolchain: name)
      Magica.default_toolchain = toolchain
      Magica.toolchain_params = params
    end

    def define_builder(name = 'host', dest = 'build', &block)
      Builder.new(name, dest, &block)
    end

    def build(name, options = {}, &block)
      builder = Magica.targets[name.to_s]
      fail I18n.t("magica.unknow_build", build: name) unless builder
      block = Magica.default_compile_task if block.nil?
      builder.instance_exec(options, &block)
    end
  end
end

extend Magica::DSL
