module Magica
  class Application < Rake::Application

    DEFAULT_MAGICAFILES = [
      "magicafile",
      "Magicafile",
      "magicafile.rb",
      "Magicafile.rb"
    ].freeze

    def initialize
      super
      @rakefiles = DEFAULT_MAGICAFILES.dup << magicafile
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
        @top_level_tasks.unshift(warning_not_init.to_s) unless default_tasks.include?(@top_level_tasks.first)
      end
      @top_level_tasks
    end

    private
    def magicafile
      File.expand_path("../../Magicafile", __FILE__)
    end

    def warning_not_init
      Rake::Task.define_task(:warning_not_init) do
        puts I18n.t("not_init_project", scope: :magica)
        exit 1
      end
    end

    def default_tasks
      %{init}
    end
  end
end
