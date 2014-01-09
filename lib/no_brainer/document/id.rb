require 'thread'
require 'socket'
require 'digest/md5'

module NoBrainer::Document::Id
  extend ActiveSupport::Concern

  included do
    self.field :id, :type => String, :default => ->{ NoBrainer::Document::Id.generate }
  end

  def ==(other)
    return super unless self.class == other.class
    !id.nil? && id == other.id
  end
  alias_method :eql?, :==

  delegate :hash, :to => :id

  # The following code is inspired by the mongo-ruby-driver

  @machine_id = Digest::MD5.digest(Socket.gethostname)[0, 3]
  @lock = Mutex.new
  @index = 0

  def self.get_inc
    @lock.synchronize do
      @index = (@index + 1) % 0xFFFFFF
    end
  end

  # TODO Unit test that thing
  def self.generate
    oid = ''
    # 4 bytes current time
    oid += [Time.now.to_i].pack("N")

    # 3 bytes machine
    oid += @machine_id

    # 2 bytes pid
    oid += [Process.pid % 0xFFFF].pack("n")

    # 3 bytes inc
    oid += [get_inc].pack("N")[1, 3]

    oid.unpack("C12").map {|e| v=e.to_s(16); v.size == 1 ? "0#{v}" : v }.join
  end
end
