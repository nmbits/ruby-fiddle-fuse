require 'ffuse/filesystem'

module FFUSE
  module Filesystem
    class AbstractFilesystem
      def lookup(path)
        if path == '/'
          return root, "."
        end
        inode = root
        name = nil
        loop do
          m = /\/([^\/]+)/.match path
          name = m[1]
          path = m.post_match
          break if path.empty?
          inode = inode[name]
          raise Errno::EINVAL if inode.nil? || (!inode.respond_to? :[])
        end
        return inode, name
      end

      def noent_and_raise(dir, name)
        unless dir[name]
          raise Errno::ENOENT
        end
      end
      private :noent_and_raise

      def exist_and_raise(dir, name)
        if dir[name]
          raise Errno::EEXIST
        end
      end
      private :exist_and_raise

      def check_respond_to(inode, sym)
        unless inode.respond_to? sym
          raise Errno::ENOTSUP
        end
      end
      private :check_respond_to

      def check_not_dir(inode)
        if inode.respond_to? :[]
          raise Errno::EISDIR
        end
      end
      private :check_not_dir

      def self.enable(*methods)
        methods.each do |sym|
          case sym
          when :getattr,  :readlink, :chmod, :chown,
               :truncate, :open,     :read,  :write,
               :flush,    :release,  :fsync, :utimens,
               :opendir,  :readdir,  :releasedir               
            define_method sym do |path, *a|
              dir, name = lookup path
              noent_and_raise dir, name
              inode = dir[name]
              check_respond_to inode, sym
              inode.__send__ sym, *a
            end
          when :mkdir, :create
            define_method sym do |path, *a|
              dir, name = lookup path
              check_respond_to dir, sym
              exist_and_raise dir, name
              dir.__send__ sym, name, *a
            end
          when :unlink, :rmdir
            define_method sym do |path, *a|
              dir, name = lookup path
              check_respond_to dir, sym
              noent_and_raise dir, name
              dir.__send__ sym, name, *a
            end
          when :rename
            def rename(path1, path2)
              dir1, name1 = lookup path1
              check_respond_to dir1, :rename
              noent_and_raise dir1, name1
              dir2, name2 = lookup path2
              exist_and_raise dir2, name2
              dir1.rename name1, dir2, name2
            end
          when :link
            def link(path1, path2)
              dir1, name1 = lookup path1
              check_respond_to dir1, :link
              noent_and_raise dir1, name1
              dir2, name2 = lookup path2
              exist_and_raise dir2, name2
              inode = dir1[name1]
              check_not_dir inode
              dir2.link name2, inode
            end
          when :symlink
            def symlink(path1, path2)
              dir2, name2 = lookup path2
              check_respond_to dir2, :symlink
              exist_and_raise dir2, name2
              dir2.symlink name2, path1
            end
          end
        end
      end
    end
  end
end
