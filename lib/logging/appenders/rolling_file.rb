
module Logging::Appenders

  # An appender that writes to a file and ensures that the file size or age
  # never exceeds some user specified level.
  #
  # The goal of this class is to write log messages to a file. When the file
  # age or size exceeds a given limit then the log file is closed, the name
  # is changed to indicate it is an older log file, and a new log file is
  # created.
  #
  # The name of the log file is changed by inserting the age of the log file
  # (as a single number) between the log file name and the extension. If the
  # file has no extension then the number is appended to the filename. Here
  # is a simple example:
  #
  #    /var/log/ruby.log   =>   /var/log/ruby.1.log
  #
  # New log messages will be appended to a newly opened log file of the same
  # name (<tt>/var/log/ruby.log</tt> in our example above). The age number
  # for all older log files is incremented when the log file is rolled. The
  # number of older log files to keep can be given, otherwise all the log
  # files are kept.
  #
  # The actual process of rolling all the log file names can be expensive if
  # there are many, many older log files to process.
  #
  class RollingFile < ::Logging::Appenders::IO

    # call-seq:
    #    RollingFile.new( name, opts )
    #
    # Creates a new Rolling File Appender. The _name_ is the unique Appender
    # name used to retrieve this appender from the Appender hash. The only
    # required option is the filename to use for creating log files.
    #
    #  [:filename]  The base filename to use when constructing new log
    #               filenames.
    #
    # The following options are optional:
    #
    #  [:layout]    The Layout that will be used by this appender. The Basic
    #               layout will be used if none is given.
    #  [:truncate]  When set to true any existing log files will be rolled
    #               immediately and a new, empty log file will be created.
    #  [:size]      The maximum allowed size (in bytes) of a log file before
    #               it is rolled.
    #  [:age]       The maximum age (in seconds) of a log file before it is
    #               rolled. The age can also be given as 'daily', 'weekly',
    #               or 'monthly'.
    #  [:keep]      The number of rolled log files to keep.
    #
    def initialize( name, opts = {} )
      # raise an error if a filename was not given
      @fn = opts.getopt(:filename, name)
      raise ArgumentError, 'no filename was given' if @fn.nil?
      ::Logging::Appenders::File.assert_valid_logfile(@fn)

      # grab the information we need to properly roll files
      ext = ::File.extname(@fn)
      bn = ::File.join(::File.dirname(@fn), ::File.basename(@fn, ext))
      @rgxp = %r/\.(\d+)#{Regexp.escape(ext)}\z/
      @glob = "#{bn}.*#{ext}"
      @logname_fmt = "#{bn}.%d#{ext}"
      @fn_copy = @fn + '.copy'

      # grab our options
      @keep = opts.getopt(:keep, :as => Integer)
      @size = opts.getopt(:size, :as => Integer)

      code = 'def sufficiently_aged?() false end'
      @age_fn = @fn + '.age'
      @age_fn_mtime = nil
      @roll = false

      case @age = opts.getopt(:age)
      when 'daily'
        code = <<-CODE
        def sufficiently_aged?
          @age_fn_mtime ||= ::File.mtime(@age_fn)
          now = Time.now
          if (now.day != @age_fn_mtime.day) or (now - @age_fn_mtime) > 86400
            return true
          end
          false
        end
        CODE
      when 'weekly'
        code = <<-CODE
        def sufficiently_aged?
          @age_fn_mtime ||= ::File.mtime(@age_fn)
          if (Time.now - @age_fn_mtime) > 604800
            return true
          end
          false
        end
        CODE
      when 'monthly'
        code = <<-CODE
        def sufficiently_aged?
          @age_fn_mtime ||= ::File.mtime(@age_fn)
          now = Time.now
          if (now.month != @age_fn_mtime.month) or (now - @age_fn_mtime) > 2678400
            return true
          end
          false
        end
        CODE
      when Integer, String
        @age = Integer(@age)
        code = <<-CODE
        def sufficiently_aged?
          @age_fn_mtime ||= ::File.mtime(@age_fn)
          if (Time.now - @age_fn_mtime) > @age
            return true
          end
          false
        end
        CODE
      end

      FileUtils.touch(@age_fn) if @age and !test(?f, @age_fn)

      meta = class << self; self end
      meta.class_eval code, __FILE__, __LINE__

      super(name, ::File.new(@fn, 'a'), opts)

      # if the truncate flag was set to true, then roll
      roll_now = opts.getopt(:truncate, false)
      if roll_now
        copy_truncate
        roll_files
      end
    end

    # Returns the path to the logfile.
    #
    def filename() @fn.dup end

    # Reopen the connection to the underlying logging destination. If the
    # connection is currently closed then it will be opened. If the connection
    # is currently open then it will be closed and immediately opened.
    #
    def reopen
      @mutex.synchronize {
        if defined? @io and @io
          flush
          @io.close rescue nil
        end
        @closed = false
        @io = ::File.new(@fn, 'a')
        @io.sync = true
      }
      self
    end


    private

    # call-seq:
    #    write( event )
    #
    # Write the given _event_ to the log file. The log file will be rolled
    # if the maximum file size is exceeded or if the file is older than the
    # maximum age.
    #
    def write( event )
      str = event.instance_of?(::Logging::LogEvent) ?
            @layout.format(event) : event.to_s
      return if str.empty?

      @io.flock_sh { super(str) }

      if roll_required?
        @io.flock? {
          @age_fn_mtime = nil
          copy_truncate if roll_required?
        }
        roll_files
      end
    ensure
      @roll = false
    end

    # Returns +true+ if the log file needs to be rolled.
    #
    def roll_required?
      return false if ::File.exist? @fn_copy

      # check if max size has been exceeded
      s = @size ? ::File.size(@fn) > @size : false

      # check if max age has been exceeded
      a = sufficiently_aged?

      return (s || a)
    end

    # Copy the contents of the logfile to another file. Truncate the logfile
    # to zero length. This method will set the roll flag so that all the
    # current logfiles will be rolled along with the copied file.
    #
    def copy_truncate
      return unless ::File.exist?(@fn)
      FileUtils.copy @fn, @fn_copy
      @io.truncate 0

      # touch the age file if needed
      if @age
        FileUtils.touch @age_fn
        @age_fn_mtime = nil
      end

      @roll = true
    end

    # Roll the log files. This is accomplished by renaming the log files
    # starting with the oldest and working towards the youngest.
    #
    #    test.10.log  =>  deleted (we are only keeping 10)
    #    test.9.log   =>  test.10.log
    #    test.8.log   =>  test.9.log
    #    ...
    #    test.1.log   =>  test.2.log
    #
    # Lastly the copied log file is rolled to a numbered log file.
    #
    #    test.log.copy  =>  test.1.log
    #
    def roll_files
      return unless @roll and ::File.exist?(@fn_copy)

      files = Dir.glob(@glob).find_all {|fn| @rgxp =~ fn}
      unless files.empty?
        # sort the files in revese order based on their count number
        files = files.sort do |a,b|
                  a = Integer(@rgxp.match(a)[1])
                  b = Integer(@rgxp.match(b)[1])
                  b <=> a
                end

        # for each file, roll its count number one higher
        files.each do |fn|
          cnt = Integer(@rgxp.match(fn)[1])
          if @keep and cnt >= @keep
            ::File.delete fn
            next
          end
          ::File.rename fn, sprintf(@logname_fmt, cnt+1)
        end
      end

      # finally reanme the copied log file
      ::File.rename(@fn_copy, sprintf(@logname_fmt, 1))
    end

  end  # class RollingFile
end  # module Logging::Appenders

# EOF
