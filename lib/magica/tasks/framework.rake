task default: :_all

task :_all do
  if Rake::Task.task_defined?(:all)
    Rake::Task[:all].invoke
  else
    Magica.each_build do
      Rake::Task[@name.to_s].invoke
    end
  end
end
