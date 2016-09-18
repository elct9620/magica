task default: :_all

task :_all do |t|
  if Rake::Task.task_defined?(:all)
    Rake::Task[:all].invoke
  else
    Magica.each_target do
      Rake::Task["build:#{@name}"].invoke
    end
  end
end
