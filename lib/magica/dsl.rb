module Magica
  module DSL
    def build(name, sources, &block)
      builder = Magica.targets[name]
      fail "Unknow #{name} builder" unless builder
      builder.instance_eval do
        FileUtils.rm_r("build", force: true)

        objects = objfile(sources)
        sources.each { |source| compile source }

        task "compile" => objects do
          @linker.run "build/main", objects
        end
      end
    end
  end
end

extend Magica::DSL
