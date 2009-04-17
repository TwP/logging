
module Logging::Layouts

  #
  class Parseable < ::Logging::Layout

    # Arguments to sprintf keyed to directive letters
    DIRECTIVE_TABLE = {
      'logger'    => 'event.logger',
      'timestamp' => 'Time.now.strftime(Pattern::ISO8601)',
      'level'     => '::Logging::LNAMES[event.level]',
      'message'   => 'format_obj(event.data)',
      'file'      => 'event.file',
      'line'      => 'event.line',
      'method'    => 'event.method',
      'pid'       => 'Process.pid',
      'millis'    => 'Integer((Time.now-@created_at)*1000)',
      'thread_id' => 'Thread.current.object_id',
      'thread'    => 'Thread.current[:name]'
    }

    def self.create_yaml_format_method( layout )
      code = "undef :format if method_defined? :format\n"
      code << "def format( event )\nstr = {\n"

      code << layout.items.map {|name|
        "'#{name}' => #{Parseable::DIRECTIVE_TABLE[name]}"
      }.join(",\n")
      code << "\n}.to_yaml\nreturn str\nend\n"

      (class << layout; self end).class_eval(code, __FILE__, __LINE__)
    end

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

    #
    #
    def self.json( opts = {} )
      opts[:style] = 'json'
      new(opts)
    end

    #
    #
    def self.yaml( opts = {} )
      opts[:style] = 'yaml'
      new(opts)
    end

    #
    #
    def initialize( opts = {} )
      super
      @created_at = Time.now
      @style = opts.getopt(:style, 'json').to_s.intern
      self.items = opts.getopt(:items, %w[timestamp level logger message])
    end

    attr_reader :items

    #
    #
    def items=( ary )
      @items = Array(ary).map {|name| name.to_s.downcase}
      create_format_method
    end


    private

    #
    #
    def format_as_json( value )
      case value
      when String; value.inspect
      when nil; 'null'
      else value.to_s.inspect end
    end

    #
    #
    def create_format_method
      case @style
      when :json; Parseable.create_json_format_method(self)
      when :yaml; Parseable.create_yaml_format_method(self)
      else raise ArgumentError, "unknown format style '#@style'" end
    end

  end  # class Parseable
end  # module Logging::Layouts

# EOF
