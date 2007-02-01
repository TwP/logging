# $Id$

require 'logging/appenders/file'

module Logging::Appenders

  #
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
  class RollingFile < ::Logging::Appenders::File

    #
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
    #  [:max_size]  The maximum allowed size (in bytes) of a log file before
    #               it is rolled.
    #  [:max_age]   The maximum age (in seconds) of a log file before it is
    #               rolled.
    #  [:keep]      The number of rolled log files to keep.
    #
    def initialize( name, opts = {} )
      # raise an error if a filename was not given
      @fn = opts[:filename] || opts['filename']
      raise ArgumentError, 'no filename was given' if @fn.nil?

      # grab the information we need to properly roll files
      ext = ::File.extname(@fn)
      bn = ::File.join(::File.dirname(@fn), ::File.basename(@fn, ext))
      @rgxp = %r/\.(\d+)#{Regexp.escape(ext)}\z/
      @glob = "#{bn}.*#{ext}"
      @logname_fmt = "#{bn}.%d#{ext}"

      # if the truncate flag was set to true, then roll 
      roll_now = opts.delete(:truncate) || opts.delete('truncate')
      roll_files if roll_now

      # grab out our options
      @keep = opts.delete(:keep) || opts.delete('keep')
      @max_size = opts.delete(:max_size) || opts.delete('max_size')
      @max_age = opts.delete(:max_age) || opts.delete('max_age')

      @keep = Integer(@keep) unless @keep.nil?
      @max_size = Integer(@max_size) unless @max_size.nil?
      unless @max_age.nil?
        @max_age = Integer(@max_age)
        @start_time = Time.now
      end

      @file_size = (::File.exist?(@fn) ? ::File.size(@fn) : 0)
      super(name, opts)
    end

    private
    #
    # call-seq:
    #    write( str )
    #
    # Write the given string to the log file. The log file will be rolled
    # if the maximum file size is exceeded or if the file is older than the
    # maximum age.
    #
    def write( str )
      super
      @file_size += str.size  # keep track of the size internally since
      roll if roll_required?  # the file IO stream is probably not being 
    end                       # flushed to disk immediately

    #
    # call-seq:
    #    roll
    #
    # Close the currently open log file, roll all the log files, and open a
    # new log file.
    #
    def roll
      begin; @io.close; rescue; end
      roll_files
      @io = ::File.new(@fn, 'w')
    end

    #
    # call-seq:
    #    roll_required?
    #
    # Returns +true+ if the log file needs to be rolled.
    #
    def roll_required?
      # check if max size has been exceeded
      if @max_size and @file_size > @max_size
        @file_size = 0
        return true
      end

      # check if max age has been exceeded
      if @max_age and (Time.now - @start_time) > @max_age
        @start_time = Time.now
        return true
      end

      false
    end

    #
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
    end

  end  # class RollingFile
end  # module Logging::Appenders

# EOF
