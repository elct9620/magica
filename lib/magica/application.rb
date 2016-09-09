module Magica
  class Application < Rake::Application
    def initialize
      super
      @rakefiles = %w{magicafile Magicafile magicafile.rb Magicafile.rb} << magicafile
    end

    def name
      "magica"
    end

    def run
      Rake.application = self
      super
    end

    def top_level_tasks
      unless File.exists?("Magicafile")
        @top_level_tasks.unshift(warning_not_init.to_s) unless %{init}.include?(@top_level_tasks.first)
      end
      @top_level_tasks
    end

    private
    def magicafile
      File.expand_path("../../Magicafile", __FILE__)
    end

    def warning_not_init
      Rake::Task.define_task(:warning_not_init) do
        puts "Please run init before use magica"
        exit 1
      end
    end
  end
end
