task "compile" do |t|
  sources = FileList['src/**/*.cpp']

  Magica.each_target do
    FileUtils.rm_r("build", force: true)

    objects = objfile(sources)

    sources.each { |source| compile source }

    task "after_compile" => objects do |task|
      sh "g++ #{task.prerequisites.join(" ")} -o build/main"
    end
  end
end

task "run" => ["after_compile"] do |t|
  sh "build/main"
end
