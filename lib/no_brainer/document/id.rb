require 'thread'
require 'socket'
require 'digest/md5'

# Code inspired by the mongo-ruby-driver

module NoBrainer::Document::Id
  extend ActiveSupport::Concern

  @machine_id = Digest::MD5.digest(Socket.gethostname)[0, 3]
  @lock = Mutex.new
  @index = 0

  def self.get_inc
    @lock.synchronize do
      @index = (@index + 1) % 0xFFFFFF
    end
  end

  # TODO Unit test that thing
  # XXX FIXME the compares of strings in rethinkdb might not work at all
  def self.generate
    oid = ''
    # 4 bytes current time
    t = Time.new.to_i
    oid += [t].pack("N")

    # 3 bytes machine
    oid += @machine_id

    # 2 bytes pid
    oid += [Process.pid % 0xFFFF].pack("n")

    # 3 bytes inc
    oid += [get_inc].pack("N")[1, 3]

    oid.unpack("C12").map {|e| v=e.to_s(16); v.size == 1 ? "0#{v}" : v }.join
  end

  module ClassMethods
    def generate_id
      NoBrainer::Document::Id.generate
    end
  end
end
