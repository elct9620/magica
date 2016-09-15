rule "compile" do |t|
  FileUtils.remove_dir("build", true)
  sources = FileList['src/**/*.cpp']
  sources.each do |source|
    dest = source.sub(/\.[^.]+$/, '.o').sub(/^src/, 'build')
    FileUtils.mkdir_p File.dirname(dest)
    sh "g++ #{source} -c -o #{dest}"
  end
end

file "link" => ["compile"] do |t|
  objects = FileList['build/**/*.o']
  sh "g++ #{objects.join(" ")} -o build/main"
end

task "run" => ["link"] do |t|
  sh "build/main"
end
