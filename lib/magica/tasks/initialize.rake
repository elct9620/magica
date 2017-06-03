task :init do
  magicafile = File.expand_path('../../templates/Magicafile', __FILE__)

  if File.exist?('Magicafile')
    warn '[Skip] Magica is already exists'
  else
    FileUtils.cp(magicafile, 'Magicafile')
    puts "create\tMagicafile"
    puts "Magica\tInitialized"
  end
end
