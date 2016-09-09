task :init do
  magicafile = File.expand_path("../../templates/Magicafile", __FILE__)

  if File.exists?("Magica")
    warn "[Skip] Magica is already exists"
  else
    FileUtils.cp(magicafile, "Magicafile")
  end
end
