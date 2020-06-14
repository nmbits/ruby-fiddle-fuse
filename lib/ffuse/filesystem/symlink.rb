require 'ffuse/filesystem'

module FFUSE
  module Filesystem
    class Symlink < INode
      def initialize(target)
        super 0777
        @target = target
      end

      def mode
        super | S_IFLNK
      end

      def readlink
        @target
      end
    end
  end
end
