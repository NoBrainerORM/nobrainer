module NoBrainer::Document::PrimaryKey::Generator
  class Retry < RuntimeError; end

  LOOKUP_TABLE = (('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a + ['-', '_']).sort.join

  TIME_OFFSET = Time.parse('2014-01-01').to_i

  # 30 bits timestamp with 1s resolution -> We overflow in year 2048. Good enough.
  # Math.log(Time.parse('2048-01-01').to_f - TIME_OFFSET)/Math.log(2) = 29.999
  TIMESTAMP_BITS = 30

  # 24 bits of machine id
  # 0.1% of chance to have a collision with 183 servers:
  # Math.sqrt(-2*(2**24)*Math.log(0.999)) = 183.2
  # 1% of chance to have a collision with ~580 servers.
  # When using more than 1000 machines, it's recommanded to fix the machine_id to avoid collisions.
  MACHINE_ID_BITS = 24

  # 16 bits for the current pid. We wouldn't need it if the sequence number was
  # on a piece of shared memory :)
  PID_BITS = 16

  # 14 bits of sequence number. max 16k values per 1s slices.
  # We want something >10k because we want to be able to do high speed inserts
  # on a single process for future benchmarks.
  SEQUENCE_BITS = 14

  # Total: 84 bits
  # We can do 6 bits per chars with [A-Za-z0-9_\-], so that's 14 chars for our ID.
  ID_NUM_CHARS = ((TIMESTAMP_BITS + MACHINE_ID_BITS + PID_BITS + SEQUENCE_BITS)/6.0).ceil

  TIMESTAMP_MASK  = (1 <<  TIMESTAMP_BITS)-1
  MACHINE_ID_MASK = (1 << MACHINE_ID_BITS)-1
  PID_MASK        = (1 <<        PID_BITS)-1
  SEQUENCE_MASK   = (1 <<   SEQUENCE_BITS)-1

  SEQUENCE_SHIFT   = 0
  PID_SHIFT        = SEQUENCE_SHIFT + SEQUENCE_BITS
  MACHINE_ID_SHIFT = PID_SHIFT + PID_BITS
  TIMESTAMP_SHIFT  = MACHINE_ID_SHIFT + MACHINE_ID_BITS

  def self._generate
    timestamp = (Time.now.to_i - TIME_OFFSET) & TIMESTAMP_MASK

    # adding some offset to avoid "---" in the middle of IDs when machine_id == 0
    machine_id = (NoBrainer::Config.machine_id + 12250030) & MACHINE_ID_MASK

    pid = Process.pid & PID_MASK

    unless @last_timestamp == timestamp
      @first_sequence = sequence = rand(SEQUENCE_MASK+1)
      @last_timestamp = timestamp
    else
      sequence = (@sequence + 1) & SEQUENCE_MASK
      raise Retry if @first_sequence == sequence
    end
    @sequence = sequence

    (timestamp << TIMESTAMP_SHIFT) | (machine_id << MACHINE_ID_SHIFT) |
      (pid << PID_SHIFT) | (sequence << SEQUENCE_SHIFT)
  rescue Retry
    sleep 0.1
    retry
  end

  def self.convert_to_alphanum(id)
    ID_NUM_CHARS.times.map { |i| LOOKUP_TABLE[(id >> (6*i)) & 0x3F] }.reverse.join
  end

  @lock = Mutex.new
  def self.generate
    convert_to_alphanum(@lock.synchronize { _generate })
  end
end
