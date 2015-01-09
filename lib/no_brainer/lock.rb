require 'digest/sha1'

class NoBrainer::Lock
  include NoBrainer::Document

  store_in :table => 'nobrainer_locks'

  # Since PKs are limited to 127 characters, we can't use the user's key as a PK
  # as it could be arbitrarily long.
  field :key_hash,   :type => String, :primary_key => true, :default => ->{ Digest::SHA1.base64digest(key) }
  field :key,        :type => String
  field :token,      :type => String
  field :expires_at, :type => Time

  # We always use a new token, even when reading from the DB, because that's
  # what represent our instance.
  after_initialize { self.token = NoBrainer::Document::PrimaryKey::Generator.generate }

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

  def lock(options={}, &block)
    if block
      lock(options)
      return block.call.tap { unlock }
    end

    options.assert_valid_keys(:expire, :timeout)
    timeout = NoBrainer::Config.lock_options.merge(options)[:timeout]
    sleep_amount = 0.1

    start_at = Time.now
    while Time.now - start_at < timeout
      return if try_lock(options.select { |k,_| k == :expire })
      sleep(sleep_amount)
      sleep_amount = [1, sleep_amount * 2].min
    end

    raise NoBrainer::Error::LockUnavailable.new("Lock on `#{key}' unavailable")
  end

  def try_lock(options={})
    options.assert_valid_keys(:expire)
    raise "Lock instance `#{key}' already locked" if @locked

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
    raise "Lock instance `#{key}' not locked" unless @locked

    result = NoBrainer.run do |r|
      selector.replace do |doc|
        r.branch(doc[:token].eq(self.token),
                 nil, doc)
      end
    end

    @locked = false
    raise NoBrainer::Error::LostLock.new("Lost lock on `#{key}'") unless result['deleted'] == 1
  end

  def refresh(options={})
    options.assert_valid_keys(:expire)
    raise "Lock instance `#{key}' not locked" unless @locked

    set_expiration(options)

    result = NoBrainer.run do |r|
      selector.update do |doc|
        r.branch(doc[:token].eq(self.token),
                 { :expires_at => self.expires_at }, nil)
      end
    end

    # Note: If we are too quick, expires_at may not change, and the returned
    # 'replaced' won't be 1. We'll generate a spurious error. This is very
    # unlikely to happen and should not harmful.
    unless result['replaced'] == 1
      @locked = false
      raise NoBrainer::Error::LostLock.new("Lost lock on `#{key}'")
    end
  end

  private

  def set_expiration(options)
    expire = NoBrainer::Config.lock_options.merge(options)[:expire]
    self.expires_at = RethinkDB::RQL.new.now + expire
  end

  def save?; raise; end
  def delete; raise; end
end
