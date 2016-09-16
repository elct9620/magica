require 'forwardable'

module Magica
  class Command
    include Rake::DSL
    extend Forwardable

    def_delegators :@build, :filename, :objfile, :libfile, :exefile
    attr_accessor :build, :command

    def initialize(build)
      @build = build
    end

    private
    def _run(options, params = {})
      sh command + ' ' + (options % params)
    end

  end
end
