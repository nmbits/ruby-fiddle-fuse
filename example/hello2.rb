require 'ffuse'
require 'ffuse/filesystem'

class HelloWorld2 < FFUSE::Filesystem::AbstractFilesystem
  class Hello < FFUSE::Filesystem::File
    MESSAGE = "Hello, World.\n"
    def read(len, off, fh)
      MESSAGE.byteslice off, len
    end

    def size
      MESSAGE.bytesize
    end
  end

  def initialize
    @root = FFUSE::Filesystem::Directory.new
    @root.set_root
    @root.link "hello", Hello.new
  end
  attr_reader :root
  enable :getattr, :read, :readdir, :rename
end

if __FILE__ == $0
  FFUSE.main HelloWorld2.new, ARGV
end
