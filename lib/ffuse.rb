require 'fiddle/import'
require 'ffuse/types'
require 'ffuse/filesystem'
require 'ffuse/callbacks'

module FFUSE
  extend Fiddle::Importer
  dlload "libfuse.so.2"
  extern "int fuse_version()"
  extern "int fuse_main_real(int, void *, void *, size_t, void *)"

  include FFUSE::Types

  FFUSE_OPERATIONS_COUNT = 45 # struct fuse_operations
  FFUSE_OPERATIONS_SIZE = FFUSE_OPERATIONS_COUNT * Fiddle::SIZEOF_VOIDP

  Stat =
    struct(["__dev_t     dev",
            "__ino_t     ino",
            "__nlink_t   nlink",
            "__mode_t    mode",
            "__uid_t     uid",
            "__gid_t     gid",
            "int         __pad0",
            "__dev_t     rdev",
            "__off_t     size",
            "__blksize_t blksize",
            "__blkcnt_t  blocks",
            "__time_t    atime",
            "__uint64_t  atimensec",
            "__time_t    mtime",
            "__uint64_t  mtimensec",
            "__time_t    ctime",
            "__uint64_t  ctimensec",
            "__int64_t   __glibc_reserved0",
            "__int64_t   __glibc_reserved1",
            "__int64_t   __glibc_reserved2"])

  FileInfo =
    struct(["int           flags",
            "unsigned long fh_old",
            "int           writepage",
            "unsigned int  flags",
            "uint64_t      fh",
            "uint64_t      lock_owner"])

  Timespec =
    struct(["__time_t tv_sec",
            "long     tv_nsec"]);

  class CArgs
    NULLP = "\0" * Fiddle::SIZEOF_VOIDP
    def initialize(args)
      @args = args
    end
    attr_reader :args

    def argv
      unless @argv
        size = (argc + 1) * Fiddle::SIZEOF_VOIDP
        address = Fiddle.malloc size
        @argv = Fiddle::Pointer.new address, size, Fiddle::RUBY_FREE
        @args.each_with_index do |a, i|
          @argv[i * Fiddle::SIZEOF_VOIDP, Fiddle::SIZEOF_VOIDP] =
            [Fiddle::Pointer[a].to_i].pack("J")
        end
        @argv[argc * Fiddle::SIZEOF_VOIDP, Fiddle::SIZEOF_VOIDP] = NULLP
      end
      @argv
    end

    def argc
      @args.size
    end
  end

  def self.main impl, args
    fs = case impl
         when Class
           impl.new(args)
         when Module
           Class.new{ include impl }.new(args)
         else
           impl
         end
    cargs = CArgs.new [::File.basename($0), "-s", "-f"] + args
    oprs_buf = "\0" * FFUSE_OPERATIONS_SIZE
    oprs = Fiddle::Pointer[oprs_buf]
    cb_list = []
    Callbacks.constants.each do |c|
      sym = c.downcase
      if fs.respond_to? sym
        cb_class = Callbacks.const_get c
        cb = cb_class.new *cb_class::SIG
        cb_list << cb
        cb.fs = fs
        oprs[cb_class::OFFSET, Fiddle::SIZEOF_VOIDP] = [cb.to_i].pack("J")
      end
    end
    fuse_main_real(cargs.argc, cargs.argv, oprs, oprs.size, nil)
  end
end
