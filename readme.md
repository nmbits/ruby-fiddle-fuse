# ruby-fiddle-fuse

## About

ruby-fiddle-fuse is an implementation of FUSE (Filesystem in Userspace) binding for Ruby language.

## Prerequisites

   1. libfuse.so.2 of your environment (e.g. sudo apt install fuse)
   2. Ruby 2.5 or above

## Example

    $ cd ruby-fiddle-fuse
    $ mkdir mnt
    $ ruby -I lib example/hello2.rb mnt &
    [1] 11111
    $ cat mnt/hello
    Hello, world.
    $ fusermount -u mnt
