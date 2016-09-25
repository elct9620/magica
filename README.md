# Magica
[![Gem Version](https://badge.fury.io/rb/magica.svg)](https://badge.fury.io/rb/magica)

Magica is a build script based on Rake, it helps you compile C and C++ project with easier way.

## Installation

    $ gem install magica

## Usage

Like Rake, you need a `Magicafile` to setup your build task.

The magica provides `magica init` command helps your start your first project.

### Build Task

To define a new build task, you can use the `build` DSL to create it.

`build :main`

If you want to do more setting for your project, you can do like below.

```ruby
build :main do
  dynamic_library "sdl2" # Use pkg-config to find dependency and add to build command
  include_path "extra/include" # Add include path
  define :debug # Add defines when build
  flag "-Wall" # Add build flags
  source "src/**/*.cpp" # Define source file, it will use FileList to scan it
  dest "build" # Define the build files to place
  use :cxx # If your project is C++ project, set it to use C++ compiler instead C compiler
end
```

### Dependency

If you have some 3rd-party library wants to include, the `dependency` can help you compile it.

**WARNING**: Current only support git as version control

```ruby
build :main do
  dependency :mruby do
    source "git@github.com:mruby/mruby.git" # Define source
    version "1.2.0" # Define version ( tag or branch )
    command "./minirake" # The build command

    env :MRUBY_CONFIG, File.join(Dir.pwd, 'mruby_config.rb') # Build environment variable

    install_dir "#{@dir}/build/host/lib" # The compiled files path
    static_library "libmruby.a", "libmruby_core.a" # The library name
  end
end
```

**NOTICE**: Current the build task will direct use install directory's file as link object.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/elct9620/magica.

