module Magica
  class Command::Git < Command
    attr_accessor :flags
    attr_accessor :clone_options, :pull_options, :checkout_options

    def initialize(build)
      super

      @command = "git"
      @flags = %w[]
      @clone_options = "clone %{flags} %{url} %{dir}"
      @pull_options = "pull %{flags} %{remote} %{branch}"
      @checkout_options = "checkout %{flags} %{checksum_hash}"
    end

    def clone(dir, url, _flags = [])
      _run @clone_options % {
        flags: [@flags, _flags].flatten.join(" "),
        dir: filename(dir),
        url: url
      }
    end

    def pull(dir, remote = 'origin', branch = 'master')
      workin dir do
        _run @pull_options % {remote: remote, branch: branch, flags: @flags.join(" ")}
      end
    end

    def checkout(dir, checksum_hash)
      workin dir do
        _run @checkout_options % {checksum_hash: checksum_hash, flags: @flags.join(" ")}
      end
    end

    private
    def workin(dir)
      root = Dir.pwd
      Dir.chdir dir
      yield if block_given?
      Dir.chdir root
    end

  end
end
