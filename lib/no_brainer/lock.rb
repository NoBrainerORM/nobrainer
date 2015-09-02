require 'digest/sha1'

class NoBrainer::Lock
  include NoBrainer::Document

  table_config :name => 'nobrainer_locks'

  # Since PKs are limited to 127 characters, we can't use the user's key as a PK
  # as it could be arbitrarily long.
  field :key_hash,       :type => String, :primary_key => true, :default => ->{ Digest::SHA1.base64digest(key) }
  field :key,            :type => String
  field :instance_token, :type => String
  field :expires_at,     :type => Time

  # We always use a new instance_token, even when reading from the DB. Which is what
  # distingushes locks.
  after_initialize { self.instance_token = NoBrainer::Document::PrimaryKey::Generator.generate }

  scope :expired, where(:expires_at.lt(RethinkDB::RQL.new.now))

  def initialize(key, options={})
    return super if options[:from_db]

    key = case key
      when Symbol then key.to_s
      when String then key
      else raise ArgumentError
    end

    super(options.merge(:key => key))
  end

  def synchronize(options={}, &block)
    lock(options)
    begin
      block.call
    ensure
      unlock if @locked
    end
  end

  def lock(options={})
    options.assert_valid_keys(:expire, :timeout)
    timeout = NoBrainer::Config.lock_options.merge(options)[:timeout]
    sleep_amount = 0.1

    start_at = Time.now
    while Time.now - start_at < timeout
      return if try_lock(options.slice(:expire))
      sleep(sleep_amount)
      sleep_amount = [1, sleep_amount * 2].min
    end

    raise_lock_unavailable!
  end

  def try_lock(options={})
    options.assert_valid_keys(:expire)
    raise_if_locked!

    set_expiration(options)

    result = NoBrainer.run do |r|
      selector.replace do |doc|
        r.branch(doc.eq(nil).or(doc[:expires_at] < r.now),
                 self.attributes, doc)
      end
    end

    return @locked = (result['inserted'] + result['replaced']) == 1
  end

  def unlock
    raise_unless_locked!

    result = NoBrainer.run do |r|
      selector.replace do |doc|
        r.branch(doc[:instance_token].eq(self.instance_token),
                 nil, doc)
      end
    end

    @locked = false
    raise_lost_lock! unless result['deleted'] == 1
  end

  def refresh(options={})
    options.assert_valid_keys(:expire)
    raise_unless_locked!

    set_expiration(options)

    result = NoBrainer.run do |r|
      selector.update do |doc|
        r.branch(doc[:instance_token].eq(self.instance_token),
                 { :expires_at => self.expires_at }, nil)
      end
    end

    # Note: If we are too quick, expires_at may not change, and the returned
    # 'replaced' won't be 1. We'll generate a spurious error. This is very
    # unlikely to happen and should not harmful.
    unless result['replaced'] == 1
      @locked = false
      raise_lost_lock!
    end
  end

  def save?(*);  raise NotImplementedError; end
  def delete(*); raise NotImplementedError; end

  private

  def set_expiration(options)
    expire = NoBrainer::Config.lock_options.merge(options)[:expire]
    self.expires_at = RethinkDB::RQL.new.now + expire
  end

  def raise_if_locked!
    raise NoBrainer::Error::LockInvalidOp.new("Lock instance `#{key}' already locked") if @locked
  end

  def raise_unless_locked!
    raise NoBrainer::Error::LockInvalidOp.new("Lock instance `#{key}' not locked") unless @locked
  end

  def raise_lost_lock!
    raise NoBrainer::Error::LostLock.new("Lost lock on `#{key}'")
  end

  def raise_lock_unavailable!
    raise NoBrainer::Error::LockUnavailable.new("Lock on `#{key}' unavailable")
  end
end
