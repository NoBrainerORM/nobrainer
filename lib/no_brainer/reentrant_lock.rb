class NoBrainer::ReentrantLock < NoBrainer::Lock
  field :lock_count, :type => Integer

  def try_lock(options={})
    options.assert_valid_keys(:expire)
    set_expiration(options)

    result = NoBrainer.run do |r|
      selector.replace do |doc|
        r.branch(doc.eq(nil).or(doc[:expires_at] < r.now),
                 self.attributes.merge(:lock_count => 1),
                 r.branch(doc[:instance_token].default(nil).eq(self.instance_token),
                          doc.merge(:expires_at => self.expires_at,
                                    :lock_count => doc[:lock_count] + 1), doc))
      end
    end

    @locked = true # to make refresh() and synchronize() happy, somewhat hacky
    return (result['inserted'] + result['replaced']) == 1
  end

  def unlock
    set_expiration(:use_previous_expire => true)

    result = NoBrainer.run do |r|
      selector.replace do |doc|
        r.branch(doc[:instance_token].default(nil).eq(self.instance_token),
                 r.branch(doc[:lock_count] > 1,
                          doc.merge(:expires_at => self.expires_at,
                                    :lock_count => doc[:lock_count] - 1), nil), doc)
      end
    end

    raise_lost_lock! unless (result['deleted'] + result['replaced']) == 1
  end
end
