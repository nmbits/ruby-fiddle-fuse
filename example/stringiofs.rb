# coding: utf-8
require 'stringio'
require 'ffuse'
require 'ffuse/filesystem'

class StringIOFilesystem < FFUSE::Filesystem::AbstractFilesystem
  class File < FFUSE::Filesystem::File
    def initialize(mode)
      super
      @io = StringIO.new
    end

    def write(str, pos, fh)
      @io.pos = pos
      @io.write str
      str.length
    end

    def read(len, pos, fh)
      @io.pos = pos
      @io.read(len) || ""
    end

    def truncate(size)
      @io.truncate size
    end

    def size
      @io.size
    end
  end

  class Directory < FFUSE::Filesystem::Directory
    def mkdir(name, mode)
      set name, Directory.new(mode)
    end

    def create(name, mode, flags)
      set name, File.new(mode)
    end
  end

  # Filesystem initialization.
  def initialize(args)
    @root = Directory.new(0600)
    @root.set_root
  end
  attr_reader :root

  # Filesystem operaions suppoted by StringIO FS.
  #
  # AbstractFilesystem class implements default Filesystem operaions,
  # which are not exposed to the fuse library by default.
  # 
  # By using 'enable' class method, you can expose filesystem
  # operations you want.
  #
  # When an exposed operation with path argument is called
  # (e.g. write), the target INode object related to the path argument
  # is detected, then the operation is redirected to the object.
  enable :getattr, :read, :write, :truncate, :readdir, :rename, :create,
         :unlink, :link, :chmod, :chown, :mkdir, :rmdir, :utimens, :symlink,
         :readlink
end

if __FILE__ == $0
  # Start
  FFUSE.main StringIOFilesystem, ARGV
end
