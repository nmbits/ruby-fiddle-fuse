module FUSE
  module Filesystem
    S_IFDIR  = 0040000
    S_IFCHR  = 0020000
    S_IFBLK  = 0060000
    S_IFREG  = 0100000
    S_IFIFO  = 0010000
    S_IFLNK  = 0120000
    S_IFSOCK = 0140000
  end
end

require 'ffuse/filesystem/abstract_filesystem'
require 'ffuse/filesystem/inode'
require 'ffuse/filesystem/directory'
require 'ffuse/filesystem/file'
require 'ffuse/filesystem/symlink'
