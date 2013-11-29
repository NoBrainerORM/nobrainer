require 'thread'
require 'socket'
require 'digest/md5'

module NoBrainer::Document::Id
  extend ActiveSupport::Concern

  included do
    self.field :id
  end

  def reset_attributes
    super
    self.id = NoBrainer::Document::Id.generate
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
    # 4 bytes current time, 3 bytes machine, 2 bytes pid, 3 bytes inc
    oid = 
      [Time.now.to_i].pack("N") +
      @machine_id +
      [Process.pid % 0xFFFF].pack("n") +
      [get_inc].pack("N")[1, 3]

    oid.unpack("C12").map {|byte| 
      byte.to_s(16).rjust(2, '0')
    }.join
  end
end
