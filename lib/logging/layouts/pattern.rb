# $Id$

require 'logging'
require 'logging/layout'

module Logging
module Layouts

  #
  #
  #
  class Pattern < ::Logging::Layout

    # Arguments to sprintf keyed to directive letters
    DIRECTIVE_TABLE = {
      'c' => 'event.logger',   # %c => logger name
      'C' => 'event.logger',   # %C => logger name
      'd' => 'format_date',    # %d => timestamp
      'm' => :placeholder,     # %m => log event data
      'M' => :placeholder,     # %M => log event data
      'l' => 'event.level',    # %l => log level
      '%' => :placeholder      # %% => literal '%' character
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
        when 'm', 'M'
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

    #
    # call-seq:
    #    Pattern.new( opts )
    #
    def initialize( opts = {} )
      f = opts.delete(:obj_format)
      super(f)

      pattern = "[%d] %#{::Logging::MAX_LEVEL_LENGTH}l -- %c : %m"
      opts[:pattern] = pattern if opts[:pattern].nil?
      opts[:date_pattern] = ISO8601 if opts[:date_pattern].nil? and
                                       opts[:date_method].nil?
      Pattern.create_format_methods(self, opts)
    end

  end  # class Pattern
end  # module Layouts
end  # module Logging

# EOF
