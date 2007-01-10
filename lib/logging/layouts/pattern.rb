# $Id$

require 'logging'
require 'logging/layout'

module Logging
module Layouts

  #
  #
  #  [c]  Used to output the name of the logger that generated the logging
  #       event.
  #  [d]  Used to output the date of the logging event. The format of the
  #       date is specified using the :date_pattern option when the Layout
  #       is created. ISO8601 format is assumed if not date pattern is given.
  #  [F]  Used to output the file name where the logging request was issued.
  #  [l]  Used to output the level of the logging event.
  #  [L]  Used to output the line number where the logging request was
  #       issued.
  #  [m]  Used to output the application supplied message associated with
  #       the logging event.
  #  [M]  Used to output the method name where the logging request was
  #       issued.
  #  [p]  Used to output the process ID of the currently running program.
  #  [r]  Used to output the number of milliseconds elapsed from the
  #       construction of the Layout until creation of the logging event.
  #  [t]  Used to output the object ID of the thread that generated the
  #       logging event.
  #  [%]  The sequence '%%' outputs a single percent sign.
  #
  #  The directives F, L, and M will only work if the Logger generating the
  #  events is configured to generate tracing information. If this is not
  #  the case these fields will always be empty.
  #
  class Pattern < ::Logging::Layout

    # :stopdoc:

    # Arguments to sprintf keyed to directive letters
    DIRECTIVE_TABLE = {
      'c' => 'event.logger',
      'd' => 'format_date',
      'F' => 'event.file',
      'l' => 'event.level',
      'L' => 'event.line',
      'm' => :placeholder,
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
    DIRECTIVE_RGXP = %r/([^%]*)(?:(%-?\d*(?:\.\d+)?)([a-zA-Z%]))?(.*)/

    # default date format
    ISO8601 = "%Y-%m-%d %H:%M:%S"

    #
    # call-seq:
    #    Pattern.create_format_methods( pf, opts )
    #
    def self.create_format_methods( pf, opts )
      # first, define the format_date method
      unless opts[:date_method].nil?
        module_eval <<-CODE
          def pf.format_date
            Time.now.#{opts[:date_method]}
          end
        CODE
      else
        module_eval <<-CODE
          def pf.format_date
            Time.now.strftime "#{opts[:date_pattern]}"
          end
        CODE
      end

      # Create the format_str(event) method. This method will return format
      # string that can be used with +sprintf+ to format the data objects in
      # the given _event_.
      code = "def pf.format_str( event )\nsprintf(\""
      pattern = opts[:pattern]
      have_m_directive = false
      args = []

      while true
        m = DIRECTIVE_RGXP.match(pattern)
        code << m[1] unless m[1].empty?

        case m[3]
        when '%'
          code << '%%%%'   # this results in a %% in the format string
        when 'm'
          code << '%' + m[2] + 's'
          have_m_directive = true
        when *DIRECTIVE_TABLE.keys
          code << m[2] + 's'
          args << DIRECTIVE_TABLE[m[3]]
        else
          raise ArgumentError, "illegal format character - #{m[3]}"
        end

        break if m[4].empty?
        pattern = m[4]
      end

      code << '\n", ' + args.join(', ') + ")\n"
      code << "end\n"
      module_eval code

      # Create the format(event) method
      if have_m_directive
        module_eval <<-CODE
          def pf.format( event )
            fmt = format_str(event)
            buf = ''
            event.data.each {|obj| buf << sprintf(fmt, format_obj(obj))}
            buf
          end
        CODE
      else
        class << pf; alias :format :format_str; end
      end
    end
    # :startdoc:

    #
    # call-seq:
    #    Pattern.new( opts )
    #
    def initialize( opts = {} )
      f = opts.delete(:obj_format)
      super(f)

      @created_at = Time.now

      pattern = "[%d] %-#{::Logging::MAX_LEVEL_LENGTH}l -- %c : %m"
      opts[:pattern] = pattern if opts[:pattern].nil?
      opts[:date_pattern] = ISO8601 if opts[:date_pattern].nil? and
                                       opts[:date_method].nil?
      Pattern.create_format_methods(self, opts)
    end

  end  # class Pattern
end  # module Layouts
end  # module Logging

# EOF
