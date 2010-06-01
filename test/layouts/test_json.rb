
require File.expand_path('../setup', File.dirname(__FILE__))

module TestLogging
module TestLayouts

  class TestJson < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @layout = Logging.layouts.json({})
      @levels = Logging::LEVELS
      @date_fmt = '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
      Thread.current[:name] = nil
    end

    def test_initializer
      assert_raise(ArgumentError) {
        Logging.layouts.parseable.new :style => :foo
      }
    end

    def test_format
      fmt = %Q[\\{"timestamp":"#@date_fmt","level":"%s","logger":"%s","message":"%s"\\}\\n]

      event = Logging::LogEvent.new('ArrayLogger', @levels['info'],
                                    'log message', false)
      rgxp  = Regexp.new(sprintf(fmt, 'INFO', 'ArrayLogger', 'log message'))
      assert_match rgxp, @layout.format(event)

      event.data = [1, 2, 3, 4]
      rgxp  = Regexp.new(sprintf(fmt, 'INFO', 'ArrayLogger',
                                 Regexp.escape("<Array> #{[1,2,3,4]}")))
      assert_match rgxp, @layout.format(event)

      event.level = @levels['debug']
      event.data = 'and another message'
      rgxp  = Regexp.new(sprintf(fmt, 'DEBUG', 'ArrayLogger',
                         'and another message'))
      assert_match rgxp, @layout.format(event)

      event.logger = 'Test'
      event.level = @levels['fatal']
      event.data = Exception.new
      rgxp  = Regexp.new(sprintf(fmt, 'FATAL', 'Test', '<Exception> Exception'))
      assert_match rgxp, @layout.format(event)
    end

    def test_items
      assert_equal %w[timestamp level logger message], @layout.items
    end

    def test_items_eq
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    ['log message'], false)

      @layout.items = %w[timestamp]
      assert_equal %w[timestamp], @layout.items
      assert_match %r/\{"timestamp":"#@date_fmt"\}\n/, @layout.format(event)

      # 'foo' is not a recognized item
      assert_raise(ArgumentError) {
        @layout.items = %w[timestamp logger foo]
      }
    end

    def test_items_all
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    'log message', false)
      event.file = 'test_file.rb'
      event.line = 123
      event.method = 'method_name'

      @layout.items = %w[logger]
      assert_equal %Q[{"logger":"TestLogger"}\n], @layout.format(event)

      @layout.items = %w[file]
      assert_equal %Q[{"file":"test_file.rb"}\n], @layout.format(event)

      @layout.items = %w[level]
      assert_equal %Q[{"level":"INFO"}\n], @layout.format(event)

      @layout.items = %w[line]
      assert_equal %Q[{"line":123}\n], @layout.format(event)

      @layout.items = %w[message]
      assert_equal %Q[{"message":"log message"}\n], @layout.format(event)

      @layout.items = %w[method]
      assert_equal %Q[{"method":"method_name"}\n], @layout.format(event)

      @layout.items = %w[pid]
      assert_match %r/\A\{"pid":\d+\}\n\z/, @layout.format(event)

      @layout.items = %w[millis]
      assert_match %r/\A\{"millis":\d+\}\n\z/, @layout.format(event)

      @layout.items = %w[thread_id]
      assert_match %r/\A\{"thread_id":-?\d+\}\n\z/, @layout.format(event)

      @layout.items = %w[thread]
      assert_equal %Q[{"thread":null}\n], @layout.format(event)
      Thread.current[:name] = "Main"
      assert_equal %Q[{"thread":"Main"}\n], @layout.format(event)
    end

  end  # class TestJson
end  # module TestLayouts
end  # module TestLogging

# EOF
