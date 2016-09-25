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

    def handle_options
      options.rakelib = ["rakelib"]
      options.trace_output = $stderr

      OptionParser.new do |opts|
        opts.on_tail("-h", "--help", "-H", "Display this help message.") do
          puts opts
          exit
        end

        standard_rake_options.each { |args| opts.on(*args) }
        opts.environment("RAKEOPT")
      end.parse!
    end

    def sort_options(options)
      not_applicable_to_capistrano = %w(verbose execute execute-continue libdir no-search rakefile rakelibdir require system no-system where no-deprecation-warnings)

      options.reject! do |(switch, *)|
        switch =~ /--#{Regexp.union(not_applicable_to_capistrano)}/
      end

      super.push(version, clean, clean_all)
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

    def version
      ["--version", "-V",
       "Display the program version.",
       lambda do |_value|
         puts "Magica Version: #{Magica::VERSION} (Rake Version: #{Rake::VERSION})"
         exit
       end]
    end

    def clean
      ["--clean", nil,
       "Clean all files before build",
       lambda do |_value|
         options.clean = true
       end]
    end

    def clean_all
      ["--clean-all", nil,
       "Clean all files before build include dependency",
       lambda do |_value|
         options.clean = true
         options.clean_all = true
       end]
    end
  end
end
