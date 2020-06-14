require 'fiddle'

module FFUSE
  module Types
    def define64(m)
      m.module_eval {
        typealias "__uint32_t",  "unsigned int"
        typealias "__int64_t",   "long"
        typealias "__uint64_t",  "unsigned long"
        typealias "uint32_t",    "__uint32_t"
        typealias "uint64_t",    "uint64_t"
        typealias "__dev_t",     "uint64_t"
        typealias "__ino_t",     "uint64_t"
        typealias "__nlink_t",   "uint64_t"
        typealias "__mode_t",    "uint32_t"
        typealias "__uid_t",     "uint32_t"
        typealias "__gid_t",     "uint32_t"
        typealias "__dev_t",     "uint64_t"
        typealias "__off_t",     "int64_t"
        typealias "__blksize_t", "int64_t"
        typealias "__blkcnt_t",  "int64_t"
        typealias "__time_t",    "int64_t"
      }
    end
    module_function :define64

    def included(m)
      case Fiddle::SIZEOF_LONG
      when 8
        define64(m)
      else
        raise "unsupported platform"
      end
    end
    module_function :included
  end
end
