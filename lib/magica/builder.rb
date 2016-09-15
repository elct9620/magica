module Magica
  class Builder

    include Rake::DSL

    def initialize(name = 'host', dest = 'build', &block)
      @name = name.to_s
      @dest = dest.to_s
      @toolchain = Toolchain.toolchains.first[1]

      Magica.targets[@name] = self
      Magica.targets[@name].instance_eval(&block)
    end

    def objfile(name)
      if name.is_a?(Array)
        name.flatten.map { |n| objfile(n) }
      else
        "build/#{name}.o"
      end
    end

    def toolchain(name)
      @toolchain = Toolchain.toolchains[name] || Toolchain.toolchains.first[1]
    end

    def compile(source)
      file objfile(source) => source do |t|
        FileUtils.mkdir_p File.dirname(t.name)
        @toolchain.compile t.name, t.prerequisites.first
      end
    end
  end
end
