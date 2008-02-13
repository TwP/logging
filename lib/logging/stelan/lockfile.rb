# $Id$

# This file was stolen with permission from Ara T. Howrad's gem of the same
# name. The only difference is the removal of Ara's vim folding turds and
# making the code work with Ruby1.9

unless(defined?($__logging_lockfile__) or defined?(Logging::Lockfile))

  require 'socket'
  require 'timeout'
  require 'fileutils'

  module Logging
  class Lockfile

    VERSION = '1.4.3'
    def version() VERSION end

    class LockError < StandardError; end
    class StolenLockError < LockError; end
    class StackingLockError < LockError; end
    class StatLockError < LockError; end
    class MaxTriesLockError < LockError; end
    class TimeoutLockError < LockError; end
    class NFSLockError < LockError; end
    class UnLockError < LockError; end

    class SleepCycle < Array
      attr :min
      attr :max
      attr :range
      attr :inc

      def initialize( min, max, inc )
        @min, @max, @inc = Float(min), Float(max), Float(inc)
        @range = @max - @min
        raise RangeError, "max(#{ @max }) <= min(#{ @min })" if @max <= @min
        raise RangeError, "inc(#{ @inc }) > range(#{ @range })" if @inc > @range
        raise RangeError, "inc(#{ @inc }) <= 0" if @inc <= 0
        raise RangeError, "range(#{ @range }) <= 0" if @range <= 0
        s = @min
        push(s) and s += @inc while(s <= @max)
        self[-1] = @max if self[-1] < @max
        reset
      end

      def next
        ret = self[@idx]
        @idx = ((@idx + 1) % self.size)
        ret
      end

      def reset
        @idx = 0
      end
    end  # class SleepCycle

    HOSTNAME = Socket::gethostname

    DEFAULT_RETRIES          = nil    # maximum number of attempts
    DEFAULT_TIMEOUT          = nil    # the longest we will try
    DEFAULT_MAX_AGE          = 3600   # lockfiles older than this are stale
    DEFAULT_SLEEP_INC        = 2      # sleep cycle is this much longer each time
    DEFAULT_MIN_SLEEP        = 2      # shortest sleep time
    DEFAULT_MAX_SLEEP        = 32     # longest sleep time
    DEFAULT_SUSPEND          = 1800   # iff we steal a lock wait this long before we go on
    DEFAULT_REFRESH          = 8      # how often we touch/validate the lock
    DEFAULT_DONT_CLEAN       = false  # iff we leave lock files lying around
    DEFAULT_POLL_RETRIES     = 16     # this many polls makes one 'try'
    DEFAULT_POLL_MAX_SLEEP   = 0.08   # the longest we'll sleep between polls
    DEFAULT_DONT_SWEEP       = false  # if we cleanup after other process on our host
    DEFAULT_DONT_USE_LOCK_ID = false  # if we dump lock info into lockfile

    DEFAULT_DEBUG = ENV['LOCKFILE_DEBUG'] || false

    class << self
      attr_accessor :retries
      attr_accessor :max_age
      attr_accessor :sleep_inc
      attr_accessor :min_sleep
      attr_accessor :max_sleep
      attr_accessor :suspend
      attr_accessor :timeout
      attr_accessor :refresh
      attr_accessor :debug
      attr_accessor :dont_clean
      attr_accessor :poll_retries
      attr_accessor :poll_max_sleep
      attr_accessor :dont_sweep
      attr_accessor :dont_use_lock_id

      def init
        @retries          = DEFAULT_RETRIES
        @max_age          = DEFAULT_MAX_AGE
        @sleep_inc        = DEFAULT_SLEEP_INC
        @min_sleep        = DEFAULT_MIN_SLEEP
        @max_sleep        = DEFAULT_MAX_SLEEP
        @suspend          = DEFAULT_SUSPEND
        @timeout          = DEFAULT_TIMEOUT
        @refresh          = DEFAULT_REFRESH
        @dont_clean       = DEFAULT_DONT_CLEAN
        @poll_retries     = DEFAULT_POLL_RETRIES
        @poll_max_sleep   = DEFAULT_POLL_MAX_SLEEP
        @dont_sweep       = DEFAULT_DONT_SWEEP
        @dont_use_lock_id = DEFAULT_DONT_USE_LOCK_ID

        @debug          = DEFAULT_DEBUG

        STDOUT.sync = true if @debug
        STDERR.sync = true if @debug
      end
    end
    self.init

    attr :klass
    attr :path
    attr :opts
    attr :locked
    attr :thief
    attr :dirname
    attr :basename
    attr :clean
    attr :retries
    attr :max_age
    attr :sleep_inc
    attr :min_sleep
    attr :max_sleep
    attr :suspend
    attr :refresh
    attr :timeout
    attr :dont_clean
    attr :poll_retries
    attr :poll_max_sleep
    attr :dont_sweep
    attr :dont_use_lock_id

    attr_accessor :debug

    alias thief? thief
    alias locked? locked
    alias debug? debug

    def self::create( path, *a, &b )
      opts = {
        'retries' => 0,
        'min_sleep' => 0,
        'max_sleep' => 1,
        'sleep_inc' => 1,
        'max_age' => nil,
        'suspend' => 0,
        'refresh' => nil,
        'timeout' => nil,
        'poll_retries' => 0,
        'dont_clean' => true,
        'dont_sweep' => false,
        'dont_use_lock_id' => true
      }
      begin
        new(path, opts).lock
      rescue LockError
        raise Errno::EEXIST, path
      end
      open(path, *a, &b)
    end

    def initialize( path, opts = {}, &block )
      @klass = self.class
      @path  = path
      @opts  = opts

      @retries          = getopt 'retries'          , @klass.retries
      @max_age          = getopt 'max_age'          , @klass.max_age
      @sleep_inc        = getopt 'sleep_inc'        , @klass.sleep_inc
      @min_sleep        = getopt 'min_sleep'        , @klass.min_sleep
      @max_sleep        = getopt 'max_sleep'        , @klass.max_sleep
      @suspend          = getopt 'suspend'          , @klass.suspend
      @timeout          = getopt 'timeout'          , @klass.timeout
      @refresh          = getopt 'refresh'          , @klass.refresh
      @dont_clean       = getopt 'dont_clean'       , @klass.dont_clean
      @poll_retries     = getopt 'poll_retries'     , @klass.poll_retries
      @poll_max_sleep   = getopt 'poll_max_sleep'   , @klass.poll_max_sleep
      @dont_sweep       = getopt 'dont_sweep'       , @klass.dont_sweep
      @dont_use_lock_id = getopt 'dont_use_lock_id' , @klass.dont_use_lock_id
      @debug            = getopt 'debug'            , @klass.debug

      @sleep_cycle = SleepCycle::new @min_sleep, @max_sleep, @sleep_inc

      @clean    = @dont_clean ? nil : lambda{ File::unlink @path rescue nil }
      @dirname  = File::dirname @path
      @basename = File::basename @path
      @thief    = false
      @locked   = false

      lock(&block) if block
    end

    def lock
      raise StackingLockError, "<#{ @path }> is locked!" if @locked

      sweep unless @dont_sweep

      ret = nil

      attempt do
        begin
          @sleep_cycle.reset
          create_tmplock do |f|
            begin
              Timeout::timeout(@timeout) do
                tmp_path = f.path
                tmp_stat = f.lstat
                n_retries = 0
                trace{ "attempting to lock <#{ @path }>..." }
                begin
                  i = 0
                  begin
                    trace{ "polling attempt <#{ i }>..." }
                    begin
                      File::link tmp_path, @path
                    rescue Errno::ENOENT
                      try_again!
                    end
                    lock_stat = File::lstat @path
                    raise StatLockError, "stat's do not agree" unless
                      tmp_stat.rdev == lock_stat.rdev and tmp_stat.ino == lock_stat.ino
                    trace{ "aquired lock <#{ @path }>" }
                    @locked = true
                rescue => e
                  i += 1
                  unless i >= @poll_retries
                    t = [rand(@poll_max_sleep), @poll_max_sleep].min
                    trace{ "poll sleep <#{ t }>..." }
                    sleep t
                    retry
                  end
                  raise
                end

                rescue => e
                  n_retries += 1
                  trace{ "n_retries <#{ n_retries }>" }
                  case validlock?
                    when true
                      raise MaxTriesLockError, "surpased retries <#{ @retries }>" if
                        @retries and n_retries >= @retries
                      trace{ "found valid lock" }
                      sleeptime = @sleep_cycle.next
                      trace{ "sleep <#{ sleeptime }>..." }
                      sleep sleeptime
                    when false
                      trace{ "found invalid lock and removing" }
                      begin
                        File::unlink @path
                        @thief = true
                        warn "<#{ @path }> stolen by <#{ Process.pid }> at <#{ timestamp }>"
                        trace{ "i am a thief!" }
                      rescue Errno::ENOENT
                      end
                      trace{ "suspending <#{ @suspend }>" }
                      sleep @suspend
                    when nil
                      raise MaxTriesLockError, "surpased retries <#{ @retries }>" if
                        @retries and n_retries >= @retries
                  end
                  retry
                end # begin
              end # timeout
            rescue Timeout::Error
              raise TimeoutLockError, "surpassed timeout <#{ @timeout }>"
            end # begin
          end # create_tmplock

          if block_given?
            stolen = false
            refresher = (@refresh ? new_refresher : nil)
            begin
              begin
                ret = yield @path
              rescue StolenLockError
                stolen = true
                raise
              end
            ensure
              begin
                refresher.kill if refresher and refresher.status
              ensure
                unlock unless stolen
              end
            end
          else
            ObjectSpace.define_finalizer self, @clean if @clean
            ret = self
          end
        rescue Errno::ESTALE, Errno::EIO => e
          raise(NFSLockError, errmsg(e))
        end
      end

      return ret
    end

    def sweep
      begin
        glob = File::join(@dirname, ".*lck")
        paths = Dir[glob]
        paths.each do |path|
          begin
            basename = File::basename path
            pat = %r/^\s*\.([^_]+)_([^_]+)/o
            if pat.match(basename)
              host, pid = $1, $2
            else
              next
            end
            host.gsub!(%r/^\.+|\.+$/,'')
            quad = host.split %r/\./
            host = quad.first
            pat = %r/^\s*#{ host }/i
            if pat.match(HOSTNAME) and %r/^\s*\d+\s*$/.match(pid)
              unless alive?(pid)
                trace{ "process <#{ pid }> on <#{ host }> is no longer alive" }
                trace{ "sweeping <#{ path }>" }
                FileUtils::rm_f path
              else
                trace{ "process <#{ pid }> on <#{ host }> is still alive" }
                trace{ "ignoring <#{ path }>" }
              end
            else
              trace{ "ignoring <#{ path }> generated by <#{ host }>" }
            end
          rescue
            next
          end
        end
      rescue => e
        warn(errmsg(e))
      end
    end

    def alive?( pid )
      pid = Integer("#{ pid }")
      begin
        Process::kill 0, pid
        true
      rescue Errno::ESRCH
        false
      end
    end

    def unlock
      raise UnLockError, "<#{ @path }> is not locked!" unless @locked
      begin
        File::unlink @path
      rescue Errno::ENOENT
        raise StolenLockError, @path
      ensure
        @thief = false
        @locked = false
        ObjectSpace.undefine_finalizer self if @clean
      end
    end

    def new_refresher
      Thread::new(Thread::current, @path, @refresh, @dont_use_lock_id) do |thread, path, refresh, dont_use_lock_id|
        loop do
          begin
            touch path
            trace{"touched <#{ path }> @ <#{ Time.now.to_f }>"}
            unless dont_use_lock_id
              loaded = load_lock_id(IO.read(path))
              trace{"loaded <\n#{ loaded.inspect }\n>"}
              raise unless loaded == @lock_id
            end
            sleep refresh
          rescue Exception => e
            trace{errmsg e}
            thread.raise StolenLockError
            Thread::exit
          end
        end
      end
    end

    def validlock?
      if @max_age
        uncache @path rescue nil
        begin
          return((Time.now - File::stat(@path).mtime) < @max_age)
        rescue Errno::ENOENT
          return nil
        end
      else
        exist = File::exist?(@path)
        return(exist ? true : nil)
      end
    end

    def uncache( file )
      refresh = nil
      begin
        is_a_file = File === file
        path = (is_a_file ? file.path : file.to_s)
        stat = (is_a_file ? file.stat : File::stat(file.to_s))
        refresh = tmpnam(File::dirname(path))
        File::link path, refresh
        File::chmod stat.mode, path
        File::utime stat.atime, stat.mtime, path
      ensure
        begin
          File::unlink refresh if refresh
        rescue Errno::ENOENT
        end
      end
    end

    def create_tmplock
      tmplock = tmpnam @dirname
      begin
        create(tmplock) do |f|
          unless dont_use_lock_id
            @lock_id = gen_lock_id
            dumped = dump_lock_id
            trace{"lock_id <\n#{ @lock_id.inspect }\n>"}
            f.write dumped
            f.flush
          end
          yield f
        end
      ensure
        begin; File::unlink tmplock; rescue Errno::ENOENT; end if tmplock
      end
    end

    def gen_lock_id
      Hash[
        'host' => "#{ HOSTNAME }",
        'pid' => "#{ Process.pid }",
        'ppid' => "#{ Process.ppid }",
        'time' => timestamp
      ]
    end

    def timestamp
      time = Time.now
      usec = time.usec.to_s
      usec << '0' while usec.size < 6
      "#{ time.strftime('%Y-%m-%d %H:%M:%S') }.#{ usec }"
    end

    def dump_lock_id lock_id = @lock_id
      "host: %s\npid: %s\nppid: %s\ntime: %s\n" %
        lock_id.values_at('host','pid','ppid','time')
    end

    def load_lock_id( buf )
      lock_id = {}
      kv = %r/([^:]+):(.*)/o
      buf.each do |line|
        m = kv.match line
        k, v = m[1], m[2]
        next unless m and k and v
        lock_id[k.strip] = v.strip
      end
      lock_id
    end

    def tmpnam( dir, seed = File::basename($0) )
      pid = Process.pid
      time = Time.now
      sec = time.to_i
      usec = time.usec
      "%s%s.%s_%d_%s_%d_%d_%d.lck" %
        [dir, File::SEPARATOR, HOSTNAME, pid, seed, sec, usec, rand(sec)]
    end

    def create( path )
      umask = nil
      f = nil
      begin
        umask = File::umask 022
        f = open path, File::WRONLY|File::CREAT|File::EXCL, 0644
      ensure
        File::umask umask if umask
      end
      return(block_given? ? begin; yield f; ensure; f.close; end : f)
    end

    def touch( path )
      FileUtils.touch path
    end

    def getopt( key, default = nil )
      [ key, key.to_s, key.to_s.intern ].each do |k|
        return @opts[k] if @opts.has_key?(k)
      end
      return default
    end

    def to_str
      @path
    end
    alias to_s to_str

    def trace( s = nil )
      STDERR.puts((s ? s : yield)) if @debug
    end

    def errmsg( e )
      "%s (%s)\n%s\n" % [e.class, e.message, e.backtrace.join("\n")]
    end

    def attempt
      ret = nil
      loop{ break unless catch('attempt'){ ret = yield } == 'try_again' }
      ret
    end

    def try_again!
      throw 'attempt', 'try_again'
    end
    alias again! try_again!

    def give_up!
      throw 'attempt', 'give_up'
    end
  end  # class Lockfile
  end  # module Logging

  $__logging_lockfile__ = __FILE__
end
