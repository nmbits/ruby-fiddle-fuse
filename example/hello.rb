require 'ffuse'

module HelloWorld
  S_IFREG = 0100000
  S_IFDIR = 0040000
  MESSAGE = "Hello, World.\n"
  def getattr(path)
    stat = {}
    case path
    when "/"
      return {:mode => S_IFDIR | 0755, :nlink => 2 }
    when "/hello"
      t = Time.now.to_i
      return {
        :mode => S_IFREG | 0444,
        :nlink => 1,
        :size => MESSAGE.bytesize,
        :uid => Process.uid,
        :gid => Process.gid,
        :atime => t,
        :mtime => t,
        :ctime => t
      }
    else
      raise Errno::ENOENT
    end
    return stat
  end

  def readdir(path, fh)
    [".", "..", "hello"]
  end

  def read(path, size, offset, fh)
    MESSAGE.byteslice offset, size
  end
end

if __FILE__ == $0
  FFUSE.main HelloWorld, ARGV
end
