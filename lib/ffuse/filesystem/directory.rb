require 'ffuse/filesystem'

module FFUSE
  module Filesystem
    class Directory < INode
      def initialize(mode)
        super(mode)
        @entries = {}
        set '.', self
      end

      def mode
        super | S_IFDIR
      end

      def set_root
        set '..', PSEUDO_PARENT_OF_ROOT
      end

      def readdir(fh)
        @entries.keys
      end

      def mkdir(name, mode)
        set name, Directory.new(mode)
      end

      def unlink(name)
        set name, nil
      end

      def rmdir(name)
        set name, nil
      end

      def symlink(name, path)
        set name, Symlink.new(path)
      end

      def rename(name1, dir2, name2)
        inode = self[name1]
        set name1, nil
        dir2.set name2, inode
      end

      def link(name, inode)
        set name, inode
      end

      def [](name)
        @entries[name]
      end

      def set(name, inode)
        case name
        when '.'
          raise Errno::EINVAL if @entries['.'] || (inode != self)
          @entries['.'] = self
        when '..'
          if inode
            raise Errno::EINVAL if @entries['..']
            @entries['..'] = inode
            inode.linked self, '..'
          else
            dir = @entries['..']
            @entries.delete '..'
            dir&.unlinked self, '..'
          end
        else
          old = @entries[name]
          if inode
            @entries[name] = inode            
            inode.linked self, name
          else
            @entries.delete name
          end
          old&.unlinked self, name
        end
      end

      def linked(dir, name)
        if name != '.' && name != '..'
          set '..', dir
        end
        super
      end

      def unlinked(dir, name)
        if name != '.' && name != '..'
          set '..', nil
        end
        super
      end
    end
    PSEUDO_PARENT_OF_ROOT = Directory.new(0600)
  end
end
