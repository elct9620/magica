Magica::Toolchain.new :gcc do |config, params|
  config.cxx.command = "g++"
  config.linker.command = "g++"
end
