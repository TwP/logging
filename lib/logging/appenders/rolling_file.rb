
require 'lockfile'

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
    #  [:safe]      When set to true, extra checks are made to ensure that
    #               only once process can roll the log files; this option
    #               should only be used when multiple processes will be
    #               logging to the same log file (does not work on Windows)
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

      # grab our options
      @keep = opts.getopt(:keep, :as => Integer)
      @size = opts.getopt(:size, :as => Integer)

      @lockfile = if opts.getopt(:safe, false) and !::Logging::WIN32
        ::Lockfile.new(
            @fn + '.lck',
            :retries => 1,
            :timeout => 2
        )
      end

      code = 'def sufficiently_aged?() false end'
      @age_fn = @fn + '.age'

      case @age = opts.getopt(:age)
      when 'daily'
        FileUtils.touch(@age_fn) unless test(?f, @age_fn)
        code = <<-CODE
        def sufficiently_aged?
          now = Time.now
          start = ::File.mtime(@age_fn)
          if (now.day != start.day) or (now - start) > 86400
            return true
          end
          false
        end
        CODE
      when 'weekly'
        FileUtils.touch(@age_fn) unless test(?f, @age_fn)
        code = <<-CODE
        def sufficiently_aged?
          if (Time.now - ::File.mtime(@age_fn)) > 604800
            return true
          end
          false
        end
        CODE
      when 'monthly'
        FileUtils.touch(@age_fn) unless test(?f, @age_fn)
        code = <<-CODE
        def sufficiently_aged?
          now = Time.now
          start = ::File.mtime(@age_fn)
          if (now.month != start.month) or (now - start) > 2678400
            return true
          end
          false
        end
        CODE
      when Integer, String
        @age = Integer(@age)
        FileUtils.touch(@age_fn) unless test(?f, @age_fn)
        code = <<-CODE
        def sufficiently_aged?
          if (Time.now - ::File.mtime(@age_fn)) > @age
            return true
          end
          false
        end
        CODE
      end
      meta = class << self; self end
      meta.class_eval code, __FILE__, __LINE__

      # if the truncate flag was set to true, then roll 
      roll_now = opts.getopt(:truncate, false)
      roll_files if roll_now

      super(name, open_logfile, opts)
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

      check_logfile
      super(str)

      if roll_required?(str)
        return roll unless @lockfile

        @lockfile.lock {
          check_logfile
          roll if roll_required?
        }
      end
    end

    # call-seq:
    #    roll
    #
    # Close the currently open log file, roll all the log files, and open a
    # new log file.
    #
    def roll
      @io.close rescue nil
      roll_files
      open_logfile
    end

    # call-seq:
    #    roll_required?( str )    => true or false
    #
    # Returns +true+ if the log file needs to be rolled.
    #
    def roll_required?( str = nil )
      # check if max size has been exceeded
      s = if @size 
        @file_size = @stat.size if @stat.size > @file_size
        @file_size += str.size if str
        @file_size > @size
      end

      # check if max age has been exceeded
      a = sufficiently_aged?

      return (s || a)
    end

    # call-seq:
    #    roll_files
    #
    # Roll the log files. This is accomplished by renaming the log files
    # starting with the oldest and working towards the youngest.
    #
    #    test.10.log  =>  deleted (we are only keeping 10)
    #    test.9.log   =>  test.10.log
    #    test.8.log   =>  test.9.log
    #    ...
    #    test.1.log   =>  test.2.log
    #    
    # Lastly the current log file is rolled to a numbered log file.
    #
    #    test.log     =>  test.1.log
    #
    # This method leaves no <tt>test.log</tt> file when it is done. This
    # file will be created elsewhere.
    #
    def roll_files
      return unless ::File.exist?(@fn)

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

      # finally reanme the base log file
      ::File.rename(@fn, sprintf(@logname_fmt, 1))

      # touch the age file if needed
      FileUtils.touch(@age_fn) if @age
    end

    # call-seq:
    #    open_logfile    => io
    #
    # Opens the logfile and stores the current file szie and inode.
    #
    def open_logfile
      @io = ::File.new(@fn, 'a')
      @io.sync = true

      @stat = ::File.stat(@fn)
      @file_size = @stat.size
      @inode = @stat.ino

      return @io
    end

    #
    #
    def check_logfile
      retry_cnt ||= 0

      if ::File.exist?(@fn) then
        @stat = ::File.stat(@fn)
        return unless @lockfile
        return if @inode == @stat.ino

        @io.close rescue nil
      end
      open_logfile
    rescue SystemCallError
      raise if retry_cnt > 3
      retry_cnt += 1
      sleep 0.08
      retry
    end

  end  # class RollingFile
end  # module Logging::Appenders

# EOF
