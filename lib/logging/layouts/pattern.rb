
module Logging
module Layouts

  # A flexible layout configurable with pattern string.
  #
  # The goal of this class is to format a LogEvent and return the results as
  # a String. The results depend on the conversion pattern.
  #
  # The conversion pattern is closely related to the conversion pattern of
  # the sprintf function. A conversion pattern is composed of literal text
  # and format control expressions called conversion specifiers.
  #
  # You are free to insert any literal text within the conversion pattern.
  #
  # Each conversion specifier starts with a percent sign (%) and is followed
  # by optional format modifiers and a conversion character. The conversion
  # character specifies the type of data, e.g. logger, level, date, thread
  # ID. The format modifiers control such things as field width, padding,
  # left and right justification. The following is a simple example.
  #
  # Let the conversion pattern be "%-5l [%c]: %m\n" and assume that the
  # logging environment was set to use a Pattern layout. Then the statements
  #
  #    root = Logging::Logger[:root]
  #    root.debug("Message 1")
  #    root.warn("Message 2")
  #
  # would yield the output
  #
  #    DEBUG [root]: Message 1
  #    WARN  [root]: Message 2
  #
  # Note that there is no explicit separator between text and conversion
  # specifiers. The pattern parser knows when it has reached the end of a
  # conversion specifier when it reads a conversion character. In the example
  # above the conversion specifier %-5l means the level of the logging event
  # should be left justified to a width of five characters. The recognized
  # conversion characters are 
  #
  #  [c]  Used to output the name of the logger that generated the log
  #       event.
  #  [d]  Used to output the date of the log event. The format of the
  #       date is specified using the :date_pattern option when the Layout
  #       is created. ISO8601 format is assumed if not date pattern is given.
  #  [F]  Used to output the file name where the logging request was issued.
  #  [l]  Used to output the level of the log event.
  #  [L]  Used to output the line number where the logging request was
  #       issued.
  #  [m]  Used to output the application supplied message associated with
  #       the log event.
  #  [M]  Used to output the method name where the logging request was
  #       issued.
  #  [p]  Used to output the process ID of the currently running program.
  #  [r]  Used to output the number of milliseconds elapsed from the
  #       construction of the Layout until creation of the log event.
  #  [t]  Used to output the object ID of the thread that generated the
  #       log event.
  #  [%]  The sequence '%%' outputs a single percent sign.
  #
  # The directives F, L, and M will only work if the Logger generating the
  # events is configured to generate tracing information. If this is not
  # the case these fields will always be empty.
  #
  # By default the relevant information is output as is. However, with the
  # aid of format modifiers it is possible to change the minimum field width,
  # the maximum field width and justification.
  #
  # The optional format modifier is placed between the percent sign and the
  # conversion character.
  #
  # The first optional format modifier is the left justification flag which
  # is just the minus (-) character. Then comes the optional minimum field
  # width modifier. This is a decimal constant that represents the minimum
  # number of characters to output. If the data item requires fewer
  # characters, it is padded on either the left or the right until the
  # minimum width is reached. The default is to pad on the left (right
  # justify) but you can specify right padding with the left justification
  # flag. The padding character is space. If the data item is larger than the
  # minimum field width, the field is expanded to accommodate the data. The
  # value is never truncated.
  #
  # This behavior can be changed using the maximum field width modifier which
  # is designated by a period followed by a decimal constant. If the data
  # item is longer than the maximum field, then the extra characters are
  # removed from the end of the data item.
  #
  # Below are various format modifier examples for the category conversion
  # specifier.
  # 
  #  [%20c]      Left pad with spaces if the logger name is less than 20
  #              characters long
  #  [%-20c]     Right pad with spaces if the logger name is less than 20
  #              characters long
  #  [%.30c]     Truncates the logger name if it is longer than 30 characters
  #  [%20.30c]   Left pad with spaces if the logger name is shorter than
  #              20 characters. However, if the logger name is longer than
  #              30 characters, then truncate the name.
  #  [%-20.30c]  Right pad with spaces if the logger name is shorter than
  #              20 characters. However, if the logger name is longer than
  #              30 characters, then truncate the name.
  #
  # Below are examples of some conversion patterns.
  #
  #    %.1l, [%d] %5l -- %c: %m\n
  #
  # This is how the Logger class in the Ruby standard library formats
  # messages. The main difference will be in the date format (the Pattern
  # Layout uses the ISO8601 date format). Set the :date_method on the
  # Pattern Layout to be 'to_s' and then the date formats will agree.
  #
  class Pattern < ::Logging::Layout

    # :stopdoc:

    # Arguments to sprintf keyed to directive letters
    DIRECTIVE_TABLE = {
      'c' => 'event.logger',
      'd' => 'format_date',
      'F' => 'event.file',
      'l' => '::Logging::LNAMES[event.level]',
      'L' => 'event.line',
      'm' => 'format_obj(event.data)',
      'M' => 'event.method',
      'p' => 'Process.pid',
      'r' => 'Integer((Time.now-@created_at)*1000).to_s',
      't' => 'Thread.current.object_id.to_s',
      '%' => :placeholder
    }

    # Matches the first directive encountered and the stuff around it.
    #
    # * $1 is the stuff before directive or "" if not applicable
    # * $2 is the %#.# match within directive group
    # * $3 is the directive letter
    # * $4 is the stuff after the directive or "" if not applicable
    DIRECTIVE_RGXP = %r/([^%]*)(?:(%-?\d*(?:\.\d+)?)([a-zA-Z%]))?(.*)/m

    # default date format
    ISO8601 = "%Y-%m-%d %H:%M:%S"

    # call-seq:
    #    Pattern.create_date_format_methods( pf )
    #
    # This method will create the +date_format+ method in the given Pattern
    # Layout _pf_ based on the configured date patten and/or date method
    # specified by the user.
    #
    def self.create_date_format_methods( pf )
      code = "undef :format_date if method_defined? :format_date\n"
      code << "def format_date\n"
      if pf.date_method.nil?
        if pf.date_pattern =~ %r/%s/
          code << <<-CODE
            now = Time.now
            dp = '#{pf.date_pattern}'.gsub('%s','%06d' % now.usec)
            now.strftime dp
          CODE
        else
          code << "Time.now.strftime '#{pf.date_pattern}'\n"
        end
      else
        code << "Time.now.#{pf.date_method}\n"
      end
      code << "end\n"

      pf._meta_eval(code, __FILE__, __LINE__)
    end

    # call-seq:
    #    Pattern.create_format_method( pf )
    #
    # This method will create the +format+ method in the given Pattern
    # Layout _pf_ based on the configured format pattern specified by the
    # user.
    #
    def self.create_format_method( pf )
      # Create the format(event) method
      code = "undef :format if method_defined? :format\n"
      code << "def format( event )\nsprintf(\""
      pattern = pf.pattern.dup
      args = []

      while true
        m = DIRECTIVE_RGXP.match(pattern)
        code << m[1] unless m[1].empty?

        case m[3]
        when '%'; code << '%%'
        when *DIRECTIVE_TABLE.keys
          code << m[2] + 's'
          args << DIRECTIVE_TABLE[m[3]]
        when nil; break
        else
          raise ArgumentError, "illegal format character - '#{m[3]}'"
        end

        break if m[4].empty?
        pattern = m[4]
      end

      code << '"'
      code << ', ' + args.join(', ') unless args.empty?
      code << ")\n"
      code << "end\n"

      pf._meta_eval(code, __FILE__, __LINE__)
    end
    # :startdoc:

    # call-seq:
    #    Pattern.new( opts )
    #
    # Creates a new Pattern layout using the following options.
    #
    #    :pattern       =>  "[%d] %-5l -- %c : %m\n"
    #    :date_pattern  =>  "%Y-%m-%d %H:%M:%S"
    #    :date_method   =>  'usec' or 'to_s'
    #
    # If used, :date_method will supersede :date_pattern.
    #
    def initialize( opts = {} )
      super
      @created_at = Time.now

      @date_pattern = opts.getopt(:date_pattern)
      @date_method = opts.getopt(:date_method)
      @date_pattern = ISO8601 if @date_pattern.nil? and @date_method.nil?

      @pattern = opts.getopt(:pattern,
          "[%d] %-#{::Logging::MAX_LEVEL_LENGTH}l -- %c : %m\n")

      Pattern.create_date_format_methods(self)
      Pattern.create_format_method(self)
    end

    attr_reader :pattern, :date_pattern, :date_method

    # call-seq:
    #    appender.pattern = "[%d] %-5l -- %c : %m\n"
    #
    # Set the message formatting pattern to be used by the layout.
    #
    def pattern=( var )
      @pattern = var
      Pattern.create_format_method(self)
    end

    # call-seq:
    #    appender.date_pattern = "%Y-%m-%d %H:%M:%S"
    #
    # Set the date formatting pattern to be used when outputting timestamps
    # in the log messages.
    #
    def date_pattern=( var )
      @date_pattern = var
      Pattern.create_date_format_methods(self)
    end

    # call-seq:
    #    appender.date_method = 'to_s'
    #    appender.date_method = :usec
    #
    # Set the date method to be used when outputting timestamps in the log
    # messages. If a date method is configured, the output of that method
    # will be used in leu of the date pattern.
    #
    def date_method=( var )
      @date_method = var
      Pattern.create_date_format_methods(self)
    end

    # :stopdoc:

    # call-seq:
    #    _meta_eval( code )
    #
    # Evaluates the given string of _code_ if the singleton class of this
    # Pattern Layout object.
    #
    def _meta_eval( code, file = nil, line = nil )
      meta = class << self; self end
      meta.class_eval code, file, line
    end
    # :startdoc:

  end  # class Pattern
end  # module Layouts
end  # module Logging

# EOF
