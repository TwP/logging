require File.expand_path('../setup', File.dirname(__FILE__))

module TestLogging
module TestLayouts

  class TestYaml < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @layout = Logging.layouts.yaml({})
      @levels = Logging::LEVELS
      @date_fmt = '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
      Thread.current[:name] = nil
    end

    def test_format
      h = {
        'level' => 'INFO',
        'logger' => 'ArrayLogger',
        'message' => 'log message'
      }

      event = Logging::LogEvent.new('ArrayLogger', @levels['info'],
                                    'log message', false)
      assert_yaml_match h, @layout.format(event)

      event.data = [1, 2, 3, 4]
      h['message'] = "<Array> #{[1,2,3,4]}"
      assert_yaml_match h, @layout.format(event)

      event.level = @levels['debug']
      event.data = 'and another message'
      h['level'] = 'DEBUG'
      h['message'] = 'and another message'
      assert_yaml_match h, @layout.format(event)

      event.logger = 'Test'
      event.level = @levels['fatal']
      event.data = Exception.new
      h['level'] = 'FATAL'
      h['logger'] = 'Test'
      h['message'] = '<Exception> Exception'
      assert_yaml_match h, @layout.format(event)
    end

    def test_items
      assert_equal %w[timestamp level logger message], @layout.items
    end

    def test_items_eq
      event = Logging::LogEvent.new('TestLogger', @levels['info'],
                                    ['log message'], false)

      @layout.items = %w[timestamp]
      assert_equal %w[timestamp], @layout.items

      expected = %r/--- \ntimestamp: #@date_fmt\n/
      if RUBY_VERSION >= '1.9' and YAML::ENGINE.yamler == 'psych' then
        expected = %r/---\ntimestamp: '#@date_fmt'\n/
      end

      assert_match expected, @layout.format(event)

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

      expected = { :logger    => %Q[--- \nlogger: TestLogger\n],
                   :file      => %Q[--- \nfile: test_file.rb\n],
                   :level     => %Q[--- \nlevel: INFO\n],
                   :line      => %Q[--- \nline: 123\n],
                   :message   => %Q[--- \nmessage: log message\n],
                   :method    => %Q[--- \nmethod: method_name\n],
                   :pid       => %r/\A--- \npid: \d+\n\z/,
                   :millis    => %r/\A--- \nmillis: \d+\n\z/,
                   :thread_id => %r/\A--- \nthread_id: -?\d+\n\z/,
                   :thread    => %Q[--- \nthread: \n],
                   :thread_m  => %Q[--- \nthread: Main\n]
                 }

      if RUBY_VERSION >= '1.9' and YAML::ENGINE.yamler == 'psych' then
        expected.each_pair do |k, v|
          if v.kind_of? String then
            v.sub!(/--- /, '---')
          else # Regexp
            expected[k] = Regexp.new(v.to_s.sub(/--- /, '---'))
          end
        end
      end

      assert_equal expected[:logger], @layout.format(event)

      @layout.items = %w[file]
      assert_equal expected[:file], @layout.format(event)

      @layout.items = %w[level]
      assert_equal expected[:level], @layout.format(event)

      @layout.items = %w[line]
      assert_equal expected[:line], @layout.format(event)

      @layout.items = %w[message]
      assert_equal expected[:message], @layout.format(event)

      @layout.items = %w[method]
      assert_equal expected[:method], @layout.format(event)

      @layout.items = %w[pid]
      assert_match expected[:pid], @layout.format(event)

      @layout.items = %w[millis]
      assert_match expected[:millis], @layout.format(event)

      @layout.items = %w[thread_id]
      assert_match expected[:thread_id], @layout.format(event)

      @layout.items = %w[thread]
      assert_equal expected[:thread], @layout.format(event)
      Thread.current[:name] = "Main"
      assert_equal expected[:thread_m], @layout.format(event)
    end

    private

    def assert_yaml_match( expected, actual )
      actual = YAML.load(actual)

      assert_match %r/#@date_fmt/o, actual['timestamp']
      assert_equal expected['level'], actual['level']
      assert_equal expected['logger'], actual['logger']
      assert_equal expected['message'], actual['message']
    end

  end  # class TestYaml
end  # module TestLayouts
end  # module TestLogging

# EOF
