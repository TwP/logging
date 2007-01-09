# $Id$

require 'test/setup.rb'
require 'stringio'

module TestLogging

  class TestLogger < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @repo = ::Logging::LoggerRepository.instance
    end

    def test_initialize
      assert_raise(RuntimeError) {::Logging::Logger.new('test')}
    end

    def test_add
      log = @repo['A']

      appenders = lambda {log.instance_variable_get :@appenders}
      assert_equal [], appenders[]

      assert_raise(TypeError) {log.add Object.new}
      assert_raise(TypeError) {log.add 'not an appender'}

      a = ::Logging::Appender.new 'test_appender_1'
      b = ::Logging::Appender.new 'test_appender_2'
      c = ::Logging::Appender.new 'test_appender_3'

      log.add a
      assert_equal [a], appenders[]

      log.add a
      assert_equal [a], appenders[]

      log.add b
      assert_equal [a,b], appenders[]

      log.add c
      assert_equal [a,b,c], appenders[]

      log.add a, c
      assert_equal [a,b,c], appenders[]

      log.clear
      assert_equal [], appenders[]

      log.add a, c
      assert_equal [a,c], appenders[]
    end

    def test_additive
      root = @repo[:root]
      log  = @repo['A']

      assert_raise(NoMethodError) {root.additive}
      assert_equal true, log.additive
    end

    def test_additive_eq
      root = @repo[:root]
      log  = @repo['A']

      assert_raise(NoMethodError) {root.additive = false}
      assert_equal true, log.additive

      log.additive = false
      assert_equal false, log.additive
    end

    def test_appenders_eq
      log = @repo['42']

      appenders = lambda {log.instance_variable_get :@appenders}
      assert_equal [], appenders[]

      assert_raise(TypeError) {log.appenders = Object.new}
      assert_raise(TypeError) {log.appenders = 'not an appender'}

      a = ::Logging::Appender.new 'test_appender_1'
      b = ::Logging::Appender.new 'test_appender_2'
      c = ::Logging::Appender.new 'test_appender_3'

      log.appenders = a, b, c
      assert_equal [a, b, c], appenders[]

      log.appenders = b
      assert_equal [b], appenders[]

      log.appenders = c, a, b
      assert_equal [c,a,b], appenders[]

      log.appenders = nil
      assert_equal [], appenders[]
    end

    def test_class_aref
      root = ::Logging::Logger[:root]
      assert_same root, ::Logging::Logger[:root]

      a = []
      assert_same ::Logging::Logger['Array'], ::Logging::Logger[Array]
      assert_same ::Logging::Logger['Array'], ::Logging::Logger[a]

      assert_not_same ::Logging::Logger['Array'], ::Logging::Logger[:root]
      assert_not_same ::Logging::Logger['A'], ::Logging::Logger['A::B']
    end

    def test_class_fetch
      assert_raise(IndexError) {::Logging::Logger.fetch 'A'}
      assert_same ::Logging::Logger[:root], ::Logging::Logger.fetch(:root)
    end

    def test_clear
      log = @repo['Elliott']

      appenders = lambda {log.instance_variable_get :@appenders}
      assert_equal [], appenders[]

      a = ::Logging::Appender.new 'test_appender_1'
      b = ::Logging::Appender.new 'test_appender_2'
      c = ::Logging::Appender.new 'test_appender_3'

      log.add a, b, c
      assert_equal [a,b,c], appenders[]

      log.clear
      assert_equal [], appenders[]
    end

    def test_concat
      a1 = SioAppender.new 'a1'
      a2 = SioAppender.new 'a2'
      log = @repo['A']

      @repo[:root].add a1
      assert_nil a1.readline
      assert_nil a2.readline

      log << "this is line one of the log file\n"
      assert_equal "this is line one of the log file\n", a1.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log << "this is line two of the log file\n"
      log << "this is line three of the log file\n"
      assert_equal "this is line two of the log file\n", a1.readline
      assert_equal "this is line three of the log file\n", a1.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.add a2
      log << "this is line four of the log file\n"
      assert_equal "this is line four of the log file\n", a1.readline
      assert_equal "this is line four of the log file\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.additive = false
      log << "this is line five of the log file\n"
      assert_equal "this is line five of the log file\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.add a1
      log << "this is line six of the log file\n"
      assert_equal "this is line six of the log file\n", a1.readline
      assert_equal "this is line six of the log file\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline
    end

    def test_level
      root = @repo[:root]
      log  = @repo['A']

      assert_equal 0, root.level
      assert_equal 0, log.level

      root.level = :warn
      assert_equal 2, root.level
      assert_equal 2, log.level

      log.level = :error
      assert_equal 2, root.level
      assert_equal 3, log.level
    end

    def test_level_eq
      root = @repo[:root]
      log  = @repo['A']

      assert_equal 0, root.level
      assert_equal 0, log.level

      assert_raise(ArgumentError) {root.level = -1}
      assert_raise(ArgumentError) {root.level =  6}
      assert_raise(ArgumentError) {root.level = Object}
      assert_raise(ArgumentError) {root.level = 'bob'}
      assert_raise(ArgumentError) {root.level = :wtf}

      root.level = 'INFO'
      assert_equal 1, root.level
      assert_equal 1, log.level

      root.level = :warn
      assert_equal 2, root.level
      assert_equal 2, log.level

      root.level = 'error'
      assert_equal 3, root.level
      assert_equal 3, log.level

      root.level = 4
      assert_equal 4, root.level
      assert_equal 4, log.level

      log.level = :DEBUG
      assert_equal 4, root.level
      assert_equal 0, log.level

      log.level = :off
      assert_equal 4, root.level
      assert_equal 5, log.level

      root.level = :all
      assert_equal 0, root.level
      assert_equal 5, log.level

      log.level = nil
      assert_equal 0, root.level
      assert_equal 0, log.level

      root.level = :warn
      assert_equal 2, root.level
      assert_equal 2, log.level

      root.level = nil
      assert_equal 0, root.level
      assert_equal 0, log.level
    end

    def test_log
      a1 = SioAppender.new 'a1'
      a2 = SioAppender.new 'a2'
      log = @repo['A Logger']

      @repo[:root].level = 'info'
      @repo[:root].add a1
      assert_nil a1.readline
      assert_nil a2.readline

      log.debug 'this should NOT be logged'
      assert_nil a1.readline
      assert_nil a2.readline

      log.info 'this should be logged'
      assert_equal " INFO - A Logger - this should be logged\n", a1.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.warn 'this is a warning', [1,2,3,4]
      assert_equal " WARN - A Logger - this is a warning\n", a1.readline
      assert_equal " WARN - A Logger - <Array> 1234\n", a1.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.add a2
      log.error 'an error has occurred'
      assert_equal "ERROR - A Logger - an error has occurred\n", a1.readline
      assert_equal "ERROR - A Logger - an error has occurred\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.additive = false
      log.error 'another error has occurred'
      assert_equal "ERROR - A Logger - another error has occurred\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.add a1
      log.fatal 'fatal exception'
      assert_equal "FATAL - A Logger - fatal exception\n", a1.readline
      assert_equal "FATAL - A Logger - fatal exception\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline

      assert_equal false, log.debug
      assert_equal true, log.info
      assert_equal true, log.warn
      assert_equal true, log.error
      assert_equal true, log.fatal

      log.level = :warn
      assert_equal false, log.debug
      assert_equal false, log.info
      assert_equal true, log.warn
      assert_equal true, log.error
      assert_equal true, log.fatal

      assert_raise(NoMethodError) {log.critical 'this log level does not exist'}

      log.warn do
        str = 'a string of data'
        str
      end
      assert_equal " WARN - A Logger - a string of data\n", a1.readline
      assert_equal " WARN - A Logger - a string of data\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.info do
        rb_raise(RuntimeError, "this block should not be executed")
      end
      assert_nil a1.readline
      assert_nil a2.readline
    end

    def test_name
      root = @repo[:root]
      log  = @repo['A']

      assert_equal '', root.name
      assert_equal 'A', log.name
    end

    def test_parent
      root = @repo[:root]

      assert_raise(NoMethodError) {root.parent}

      assert_same root, @repo['A'].parent
      assert_same @repo['A'], @repo['A::B'].parent
      assert_same @repo['A::B'], @repo['A::B::C::D'].parent
      assert_same @repo['A::B'], @repo['A::B::C::E'].parent
      assert_same @repo['A::B'], @repo['A::B::C::F'].parent


      assert_same @repo['A::B'], @repo['A::B::C'].parent
      assert_same @repo['A::B::C'], @repo['A::B::C::D'].parent
      assert_same @repo['A::B::C'], @repo['A::B::C::E'].parent
      assert_same @repo['A::B::C'], @repo['A::B::C::F'].parent

      assert_same @repo['A::B::C::E'], @repo['A::B::C::E::G'].parent
    end

    def test_remove
      log = @repo['X']

      appenders = lambda {log.instance_variable_get :@appenders}
      assert_equal [], appenders[]

      a = ::Logging::Appender.new 'test_appender_1'
      b = ::Logging::Appender.new 'test_appender_2'
      c = ::Logging::Appender.new 'test_appender_3'

      log.add a, b, c
      assert_equal [a,b,c], appenders[]

      assert_raise(TypeError) {log.remove Object.new}
      assert_raise(TypeError) {log.remove 10}

      log.remove b
      assert_equal [a,c], appenders[]

      log.remove 'test_appender_1'
      assert_equal [c], appenders[]

      log.remove c
      assert_equal [], appenders[]

      log.remove a, b, c
      assert_equal [], appenders[]

      log.add a, b, c
      assert_equal [a,b,c], appenders[]

      log.remove a, c
      assert_equal [b], appenders[]
    end

    def test_spaceship
      logs = %w(
        A  A::B  A::B::C  A::B::C::D  A::B::C::E  A::B::C::E::G  A::B::C::F
      ).map {|x| @repo[x]}
      logs.unshift @repo[:root]

      logs.inject do |a,b|
        assert_equal -1, a <=> b
        b
      end

      assert_raise(NoMethodError) {logs[1] <=> Object.new}
    end

  end  # class TestLogger

  class SioAppender < ::Logging::Appenders::IO

    def initialize( name, opts = {} )
      @sio = StringIO.new
      super(name, @sio, opts)
      begin readline rescue EOFError end
    end

    def readline
      @pos ||= 0
      @sio.seek @pos
      begin
        line = @sio.readline
        @pos = @sio.tell
        line
      rescue EOFError
        nil
      end
    end

  end  # class SioAppender

end  # module TestLogging

# EOF
