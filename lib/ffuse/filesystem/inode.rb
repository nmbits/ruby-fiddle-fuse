require 'ffuse/filesystem'

module FFUSE
  module Filesystem
    class INode
      TIME_DEFAULT = Time.at 0

      S_IFBLK  = 0060000
      S_IFDIR  = 0040000
      S_IFCHR  = 0020000
      S_IFIFO  = 0010000
      S_IFREG  = 0100000
      S_IFSOCK = 0140000
      S_IFLNK  = 0120000

      def initialize(mode)
        @mode = mode
        @uid = Process.uid
        @gid = Process.gid
        @nlink = 0
        @atime = @mtime = @ctime = Time.now
      end
      attr_reader :mode, :uid, :gid, :nlink, :atime, :mtime, :ctime

      def chmod(mode)
        @mode = mode
      end

      def chown(uid, gid)
        @uid = uid
        @gid = gid
      end

      def size; 0 end

      def getattr
        {
          :mtime     => mtime.tv_sec,
          :mtimensec => mtime.tv_nsec,
          :ctime     => ctime.tv_sec,
          :ctimensec => ctime.tv_nsec,
          :atime     => atime.tv_sec,
          :atimensec => atime.tv_nsec,
          :nlink     => nlink,
          :uid       => uid,
          :gid       => gid,
          :mode      => mode,
          :size      => size
        }
      end

      def utimens(atime, mtime)
        @atime = atime
        @mtime = mtime
      end

      def inc
        @nlink ||= 0
        @nlink += 1
      end

      def dec
        @nlink -= 1
      end

      def linked(dir, name)
        inc
      end

      def unlinked(dir, name)
        dec
      end
    end
  end
end
