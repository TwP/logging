
require File.expand_path('../setup', File.dirname(__FILE__))

module TestLogging
module TestLayouts
  class TestNestedExceptions < Test::Unit::TestCase
    include LoggingTestCase

    def test_basic_format_obj
      begin
        raise StandardError, 'nested exception'
      rescue
        raise Exception, 'root exception'
      end
    rescue Exception => e
      layout = Logging.layouts.basic({})
      log = layout.format_obj(e)
      puts log.scan(/(?=<Exception> root exception)/)
      assert_not_nil log.index('<Exception> root exception')
      assert_not_nil log.index('<StandardError> nested exception')
      assert_operator log.index('<Exception> root exception'), :<, log.index('<StandardError> nested exception')
    end

    def test_parseable_format_obj
      begin
        raise StandardError, 'nested exception'
      rescue
        raise Exception, 'root exception'
      end
    rescue Exception => e
      layout = Logging.layouts.parseable.new
      log = layout.format_obj(e)
      assert_equal Exception.name, log[:class]
      assert_equal 'root exception', log[:message]
      assert_not_nil log[:cause]
      assert_operator log[:backtrace].size, :>, 0

      log = log[:cause]
      assert_equal StandardError.name, log[:class]
      assert_equal 'nested exception', log[:message]
      assert_nil log[:cause]
      assert_operator log[:backtrace].size, :>, 0
    end
  end  # class TestBasic

end  # module TestLayouts
end  # module TestLogging

