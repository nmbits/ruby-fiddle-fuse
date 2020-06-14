require 'ffuse/filesystem'

module FFUSE
  module Filesystem
    class File < INode
      def mode
        super | S_IFREG
      end
    end
  end
end
