Magica::Toolchain.new :gcc do |config, params|
  config.cc do |cc|
    cc.command = ENV['CC'] || "gcc"
    cc.flags = [ENV['CFLAGS'] || %w(-g -std=gnu99 -O3 -Wall -Werror-implicit-function-declaration -Wdeclaration-after-statement -Wwrite-strings)]
  end

  config.cxx do |cxx|
    cxx.command = ENV['CXX'] || "g++"
    cxx.flags = [ENV['CXXFLAGS'] || %w(-g -O3 -Wall -Werror-implicit-function-declaration)]
  end

  config.linker do |linker|
    linker.command = ENV['LD'] || "gcc"
    linker.flags = [ENV['LDFLAGS'] || %w()]
  end
end
