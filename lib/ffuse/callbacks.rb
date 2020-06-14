require 'fiddle'

module FFUSE
  class Invoker < Fiddle::Closure
    include Fiddle
    attr_accessor :fs
    def call(*a)
      ret = 0
      begin
        ret = invoke *a
      rescue SystemCallError => e
        ret = 0 - e.class::Errno
      rescue Exception => e
        bt = e.backtrace.join("\n\t")
        STDERR.puts "Error: #{$!}"
        STDERR.print "Backtrace:\n\t"
        STDERR.puts bt
        ret = 0 - Errno::ENOSYS::Errno
      end
      return ret
    end
  end

  module Callbacks
    class GETATTR < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP]]
      OFFSET = 0 * SIZEOF_VOIDP
      def invoke(path, stat_ptr)
        stat = fs.getattr path.to_s
        fuse_stat = FFUSE::Stat.new stat_ptr
        if File::Stat === stat
          fuse_stat.dev       = stat.dev
          fuse_stat.ino       = stat.ino
          fuse_stat.nlink     = stat.nlink
          fuse_stat.uid       = stat.uid
          fuse_stat.gid       = stat.gid
          fuse_stat.rdev      = stat.rdev
          fuse_stat.size      = stat.size
          fuse_stat.blksize   = stat.blksize
          fuse_stat.blocks    = stat.blocks
          fuse_stat.atime     = stat.atime.tv_sec
          fuse_stat.atimensec = stat.atime.tv_nsec
          fuse_stat.mtime     = stat.mtime.tv_sec
          fuse_stat.mtimensec = stat.mtime.tv_nsec
          fuse_stat.ctime     = stat.ctime.tv_sec
          fuse_stat.ctimensec = stat.ctime.tv_nsec
        elsif stat.respond_to? :[]
          [:dev, :ino, :mode, :nlink,
           :uid, :gid, :rdev, :size,
           :blksize, :blocks,
           :atime, :mtime, :ctime,
           :atimensec, :mtimensec, :ctimensec].each do |s|
            aset = "#{s}=".to_s
            fuse_stat.__send__ aset, stat[s] if stat[s]
          end
        else
          raise TypeError
        end
        return 0
      end
    end

    class READLINK < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP, TYPE_SIZE_T]]
      OFFSET = 1 * SIZEOF_VOIDP
      def invoke(path, buffer, size)
        r = fs.readlink path.to_s
        buffer[0, size] = r
        return 0
      end
    end

    class MKNOD < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, -TYPE_INT, -TYPE_LONG_LONG]]
      OFFSET = 3 * SIZEOF_VOIDP
      def invoke(path, mode, dev)
        fs.mknod path.to_s, mode, dev
        return 0
      end
    end

    class MKDIR < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, -TYPE_INT]]
      OFFSET = 4 * SIZEOF_VOIDP
      def invoke(path, mode)
        fs.mkdir path.to_s, mode
        return 0
      end
    end

    class UNLINK < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP]]
      OFFSET = 5 * SIZEOF_VOIDP
      def invoke(path)
        fs.unlink path.to_s
        return 0
      end
    end

    class RMDIR < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP]]
      OFFSET = 6 * SIZEOF_VOIDP
      def invoke(path)
        fs.rmdir path.to_s
        return 0
      end
    end

    class SYMLINK < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP]]
      OFFSET = 7 * SIZEOF_VOIDP
      def invoke(path1, path2)
        fs.symlink path1.to_s, path2.to_s
        return 0
      end
    end

    class RENAME < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP]]
      OFFSET = 8 * SIZEOF_VOIDP
      def invoke(path1, path2)
        fs.rename path1.to_s, path2.to_s
        return 0
      end
    end

    class LINK < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP]]
      OFFSET = 9 * SIZEOF_VOIDP
      def invoke(path1, path2)
        fs.link path1.to_s, path2.to_s
        return 0
      end
    end

    class CHMOD < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, -TYPE_INT]]
      OFFSET = 10 * SIZEOF_VOIDP
      def invoke(path, mode)
        fs.chmod path.to_s, mode
        return 0
      end
    end

    class CHOWN < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, -TYPE_INT, -TYPE_INT]]
      OFFSET = 11 * SIZEOF_VOIDP
      def invoke(path, uid, gid)
        fs.chown path.to_s, uid, gid
        return 0
      end
    end

    class TRUNCATE < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_LONG_LONG]]
      OFFSET = 12 * SIZEOF_VOIDP
      def invoke(path, off)
        fs.truncate path.to_s, off
        return 0
      end
    end

    class OPEN < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP]]
      OFFSET = 14 * SIZEOF_VOIDP
      def invoke(path, fiptr)
        fi = FileInfo.new(fiptr)
        fh = fs.open path.to_s, fi.flags
        fi.fh = Fiddle.dlwrap fh
        return 0
      end
    end

    class READ < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP,
                        TYPE_SIZE_T, TYPE_LONG_LONG,
                        TYPE_VOIDP]]
      OFFSET = 15 * SIZEOF_VOIDP
      def invoke(path, buff, size, off, fi)
        fh = Fiddle.dlunwrap FileInfo.new(fi).fh
        data = fs.read path.to_s, size, off, fh
        data_size = data.bytesize < size ? data.bytesize : size
        buff[0, data_size] = data
        data_size
      end
    end

    class WRITE < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP,
                        TYPE_SIZE_T, TYPE_LONG_LONG,
                        TYPE_VOIDP]]
      OFFSET = 16 * SIZEOF_VOIDP
      def invoke(path, buff, size, off, fi)
        fh = Fiddle.dlunwrap FileInfo.new(fi).fh
        return fs.write(path.to_s, buff[0, size], off, fh)
      end
    end

    # TODO statfs
    
    class FLUSH < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP]]
      OFFSET = 18 * SIZEOF_VOIDP
      def invoke(path, fi)
        fh = Fiddle.dlunwrap FileInfo.new(fi).fh
        fs.flush path.to_s, fh
        return 0
      end
    end

    class RELEASE < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP]]
      OFFSET = 19 * SIZEOF_VOIDP
      def invoke(path, fi)
        fh = Fiddle.dlunwrap FileInfo.new(fi).fh
        fs.release path.to_s, fh
        return 0
      end
    end

    class FSYNC < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_INT, TYPE_VOIDP]]
      OFFSET = 20 * SIZEOF_VOIDP
      def invoke(path, sync, fi)
        fh = Fiddle.dlunwrap FileInfo.new(fi).fh
        fs.fsync path.to_s, sync, fh
        return 0
      end
    end

    # TODO xattr

    class OPENDIR < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP]]
      OFFSET = 25 * SIZEOF_VOIDP
      def invoke(path, fiptr)
        fi = FileInfo.new(fiptr)
        fh = fs.opendir path.to_s
        fi.fh = Fiddle.dlwrap fh
        return 0
      end
    end
    
    class READDIR < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP, TYPE_VOIDP,
                        TYPE_LONG_LONG, TYPE_VOIDP]]
      OFFSET = 26 * SIZEOF_VOIDP
      def invoke(path, buf, filler, off, fi)
        f = Function.new(filler, [TYPE_VOIDP, TYPE_VOIDP, TYPE_VOIDP, TYPE_LONG_LONG],
                                 TYPE_INT)
        fh = Fiddle.dlunwrap FileInfo.new(fi).fh
        ret = fs.readdir path.to_s, fh
        ret.each do |r|
          f.call buf, r.to_s, nil, 0
        end
        return 0
      end
    end

    class RELEASEDIR < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP]]
      OFFSET = 27 * SIZEOF_VOIDP
      def invoke(path, fi)
        fh = Fiddle.dlunwrap FileInfo.new(fi).fh
        fs.releasedir path.to_s, fh
        return 0
      end
    end

    class CREATE < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, -TYPE_INT, TYPE_VOIDP]]
      OFFSET = 32 * SIZEOF_VOIDP
      def invoke(path, mode, fiptr)
        fi = FileInfo.new fiptr
        flags = fi.flags
        fh = fs.create path.to_s, mode, flags
        fi.fh = Fiddle.dlwrap fh
        return 0
      end
    end

    class UTIMENS < Invoker
      SIG = [TYPE_INT, [TYPE_VOIDP, TYPE_VOIDP]]
      OFFSET = 36 * SIZEOF_VOIDP
      def invoke(path, ts_ptr)
        ts1 = Timespec.new ts_ptr
        ts2 = Timespec.new ts_ptr + Timespec.size
        time1 = Time.at ts1.tv_sec, ts1.tv_nsec, :nsec
        time2 = Time.at ts2.tv_sec, ts2.tv_nsec, :nsec
        fs.utimens path.to_s, time1, time2
        return 0
      end
    end
  end
end
