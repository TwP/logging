# $Id$

require 'test/setup.rb'

module TestLogging
module TestLayouts

  class TestBasic < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      ::Logging.define_levels %w(debug info warn error fatal)
      @layout = ::Logging::Layouts::Basic.new
    end

    def test_format
      event = ::Logging::LogEvent.new('ArrayLogger', 'INFO',
                                      ['log message'], false)
      assert_equal " INFO - ArrayLogger - log message\n", @layout.format(event)

      event.data = [[1, 2, 3, 4]]
      assert_equal " INFO - ArrayLogger - <Array> 1234\n", @layout.format(event)

      event.level = 'DEBUG'
      event.data = [[1, 2, 3, 4], 'and some message']
      log =  "DEBUG - ArrayLogger - <Array> 1234\n"
      log << "DEBUG - ArrayLogger - and some message\n"
      assert_equal log, @layout.format(event)

      event.logger = 'Test'
      event.level = 'FATAL'
      event.data = [[1, 2, 3, 4], 'and some message', Exception.new]
      log =  "FATAL - Test - <Array> 1234\n"
      log << "FATAL - Test - and some message\n"
      log << "FATAL - Test - <Exception> Exception\n"
      assert_equal log, @layout.format(event)
    end

  end  # class TestBasic

end  # module TestLayouts
end  # module TestLogging

# EOF
