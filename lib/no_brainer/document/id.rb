require 'thread'
require 'socket'
require 'digest/md5'

module NoBrainer::Document::Id
  extend ActiveSupport::Concern

  DEFAULT_PK_NAME = :id

  def pk_value
    __send__(self.class.pk_name)
  end

  def pk_value=(value)
    __send__("#{self.class.pk_name}=", value)
  end

  def ==(other)
    return super unless self.class == other.class
    !pk_value.nil? && pk_value == other.pk_value
  end
  alias_method :eql?, :==

  delegate :hash, :to => :pk_value

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

  module ClassMethods
    def define_default_pk
      class_variable_set(:@@pk_name, nil)
      field NoBrainer::Document::Id::DEFAULT_PK_NAME, :primary_key => :default,
        :type => String, :default => ->{ NoBrainer::Document::Id.generate }
    end

    def define_pk(attr)
      if fields[pk_name].try(:[], :primary_key) == :default
        remove_field(pk_name, :set_default_pk => false)
      end
      class_variable_set(:@@pk_name, attr)
    end

    def pk_name
      class_variable_get(:@@pk_name)
    end

    def _field(attr, options={})
      super
      define_pk(attr) if options[:primary_key]
    end

    def field(attr, options={})
      if options[:primary_key]
        options = options.merge(:readonly => true) if options[:readonly].nil?
        options = options.merge(:index => true)
      end
      super
    end

    def _remove_field(attr, options={})
      super
      if fields[attr][:primary_key] && options[:set_default_pk] != false
        define_default_pk
      end
    end
  end
end
