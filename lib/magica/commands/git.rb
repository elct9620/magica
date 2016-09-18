module Magica
  class Command::Git < Command
    attr_accessor :flags
    attr_accessor :clone_options, :pull_options, :checkout_options

    def initialize(build)
      super

      @command = "git"
      @flags = %w[]
      @clone_options = "clone %{flags} %{url} %{dir}"
      @pull_options = "pull %{remote} %{branch}"
      @checkout_options = "checkout %{checksum_hash}"
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
        _run @pull_options % {remote: remote, branch: branch}
      end
    end

    def checkout(dir, checksum_hash)
      workin dir do
        _run @checkout_options % {checksum_hash: checksum_hash}
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
