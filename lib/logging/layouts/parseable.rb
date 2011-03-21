
module Logging::Layouts

  # This layout will produce parseable log output in either JSON or YAML
  # format. This makes it much easier for machines to parse log files and
  # perform analysis on those logs.
  #
  # The information about the log event can be configured when the layout is
  # created. Any or all of the following labels can be set as the _items_ to
  # log:
  #
  #   'logger'     Used to output the name of the logger that generated the
  #                log event.
  #   'timestamp'  Used to output the timestamp of the log event.
  #   'level'      Used to output the level of the log event.
  #   'message'    Used to output the application supplied message
  #                associated with the log event.
  #   'file'       Used to output the file name where the logging request
  #                was issued.
  #   'line'       Used to output the line number where the logging request
  #                was issued.
  #   'method'     Used to output the method name where the logging request
  #                was issued.
  #   'pid'        Used to output the process ID of the currently running
  #                program.
  #   'millis'     Used to output the number of milliseconds elapsed from
  #                the construction of the Layout until creation of the log
  #                event.
  #   'thread_id'  Used to output the object ID of the thread that generated
  #                the log event.
  #   'thread'     Used to output the name of the thread that generated the
  #                log event. Name can be specified using Thread.current[:name]
  #                notation. Output empty string if name not specified. This
  #                option helps to create more human readable output for
  #                multithread application logs.
  #
  # These items are supplied to the layout as an array of strings. The items
  # 'file', 'line', and 'method' will only work if the Logger generating the
  # events is configured to generate tracing information. If this is not the
  # case these fields will always be empty.
  #
  # When configured to output log events in YAML format, each log message
  # will be formatted as a hash in it's own YAML document. The hash keys are
  # the name of the item, and the value is what you would expect it to be.
  # Therefore, for the default set of times log message would appear as
  # follows:
  #
  #   ---
  #   timestamp: 2009-04-17 16:15:42
  #   level: INFO
  #   logger: Foo::Bar
  #   message: this is a log message
  #   ---
  #   timestamp: 2009-04-17 16:15:43
  #   level: ERROR
  #   logger: Foo
  #   message: <RuntimeError> Oooops!!
  #
  # The output order of the fields is not guaranteed to be the same as the
  # order specified in the _items_ list. This is because Ruby hashes are not
  # ordered by default (unless your running this in Ruby 1.9).
  #
  # When configured to output log events in JSON format, each log message
  # will be formatted as an object (in the JSON sense of the work) on it's
  # own line in the log output. Therefore, to parse the output you must read
  # it line by line and parse the individual objects. Taking the same
  # example above the JSON output would be:
  #
  #   {"timestamp":"2009-04-17 16:15:42","level":"INFO","logger":"Foo::Bar","message":"this is a log message"}
  #   {"timestamp":"2009-04-17 16:15:43","level":"ERROR","logger":"Foo","message":"<RuntimeError> Oooops!!"}
  #
  # The output order of the fields is guaranteed to be the same as the order
  # specified in the _items_ list.
  #
  class Parseable < ::Logging::Layout

    # :stopdoc:
    # Arguments to sprintf keyed to directive letters
    DIRECTIVE_TABLE = {
      'logger'    => 'event.logger',
      'timestamp' => 'event.time.strftime(Pattern::ISO8601)',
      'level'     => '::Logging::LNAMES[event.level]',
      'message'   => 'format_obj(event.data)',
      'file'      => 'event.file',
      'line'      => 'event.line',
      'method'    => 'event.method',
      'pid'       => 'Process.pid',
      'millis'    => 'Integer((event.time-@created_at)*1000)',
      'thread_id' => 'Thread.current.object_id',
      'thread'    => 'Thread.current[:name]'
    }

    # call-seq:
    #    Pattern.create_yaml_format_methods( layout )
    #
    # This method will create the +format+ method in the given Parseable
    # _layout_ based on the configured items for the layout instance.
    #
    def self.create_yaml_format_method( layout )
      code = "undef :format if method_defined? :format\n"
      code << "def format( event )\nstr = {\n"

      code << layout.items.map {|name|
        "'#{name}' => #{Parseable::DIRECTIVE_TABLE[name]}"
      }.join(",\n")
      code << "\n}.to_yaml\nreturn str\nend\n"

      (class << layout; self end).class_eval(code, __FILE__, __LINE__)
    end

    # call-seq:
    #    Pattern.create_json_format_methods( layout )
    #
    # This method will create the +format+ method in the given Parseable
    # _layout_ based on the configured items for the layout instance.
    #
    def self.create_json_format_method( layout )
      code = "undef :format if method_defined? :format\n"
      code << "def format( event )\n\"{"

      args = []
      code << layout.items.map {|name|
        args << "format_as_json(#{Parseable::DIRECTIVE_TABLE[name]})"
        "\\\"#{name}\\\":%s"
      }.join(',')
      code << "}\\n\" % [#{args.join(', ')}]\nend"

      (class << layout; self end).class_eval(code, __FILE__, __LINE__)
    end
    # :startdoc:

    # call-seq:
    #    Parseable.json( opts )
    #
    # Create a new Parseable layout that outputs log events usig JSON style
    # formatting. See the initializer documentation for available options.
    #
    def self.json( opts = {} )
      opts[:style] = 'json'
      new(opts)
    end

    # call-seq:
    #    Parseable.yaml( opts )
    #
    # Create a new Parseable layout that outputs log events usig YAML style
    # formatting. See the initializer documentation for available options.
    #
    def self.yaml( opts = {} )
      opts[:style] = 'yaml'
      new(opts)
    end

    # call-seq:
    #    Parseable.new( opts )
    #
    # Creates a new Parseable layout using the following options:
    #
    #    :style  => :json or :yaml
    #    :items  => %w[timestamp level logger message]
    #
    def initialize( opts = {} )
      super
      @created_at = Time.now
      @style = opts.getopt(:style, 'json').to_s.intern
      self.items = opts.getopt(:items, %w[timestamp level logger message])
    end

    attr_reader :items

    # call-seq:
    #    layout.items = %w[timestamp level logger message]
    #
    # Set the log event items that will be formatted by this layout. These
    # items, and only these items, will appear in the log output.
    #
    def items=( ary )
      @items = Array(ary).map {|name| name.to_s.downcase}
      valid = DIRECTIVE_TABLE.keys
      @items.each do |name|
        raise ArgumentError, "unknown item - #{name.inspect}" unless valid.include? name
      end
      create_format_method
    end

  private

    # Take the given _value_ and format it into a JSON compatible string.
    #
    def format_as_json( value )
      case value
      when String, Integer, Float; value.inspect
      when nil; 'null'
      else value.to_s.inspect end
    end

    # Call the appropriate class level create format method based on the
    # style of this parseable layout.
    #
    def create_format_method
      case @style
      when :json; Parseable.create_json_format_method(self)
      when :yaml; Parseable.create_yaml_format_method(self)
      else raise ArgumentError, "unknown format style '#@style'" end
    end

  end  # Parseable
end  # Logging::Layouts

