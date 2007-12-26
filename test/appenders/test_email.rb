# $Id$

require 'test/setup.rb'

module TestLogging
module TestAppenders

  class TestEmail < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      ::Logging.define_levels %w(debug info warn error fatal)
    end

    def test_initialize
      assert_raise(ArgumentError, 'Must specify from address') {
        ::Logging::Appenders::Email.new('email')
      }
      assert_raise(ArgumentError, 'Must specify to address') {
        ::Logging::Appenders::Email.new('email', :from => 'me')
      }
      assert_nothing_raised {
        ::Logging::Appenders::Email.new('email', :from => 'me', :to => 'you')
      }

      appender = ::Logging::Appenders::Email.new('email',
          'from' => 'me', 'to' => 'you'
      )

      assert_equal(100, appender.instance_variable_get(:@buffsize))
      assert_equal([], appender.instance_variable_get(:@immediate))
      assert_equal('localhost', appender.server)
      assert_equal(25, appender.port)
      assert_equal(ENV['HOSTNAME'], appender.domain)
      assert_equal(nil, appender.acct)
      assert_equal(:cram_md5, appender.authtype)
      assert_equal("Message of #{$0}", appender.subject)

      appender = ::Logging::Appenders::Email.new('email',
          'from' => 'lbrinn@gmail.com', 'to' => 'everyone',
          :buffsize => '1000', :immediate_at => 'error, fatal',
          :server => 'smtp.google.com', :port => '443',
          :domain => 'google.com', :acct => 'lbrinn',
          :passwd => '1234', :authtype => 'tls',
          :subject => "I'm rich and you're not"
      )

      assert_equal('lbrinn@gmail.com', appender.instance_variable_get(:@from))
      assert_equal(['everyone'], appender.instance_variable_get(:@to))
      assert_equal(1000, appender.instance_variable_get(:@buffsize))
      assert_equal('1234', appender.instance_variable_get(:@passwd))
      assert_equal([nil, nil, nil, true, true],
                   appender.instance_variable_get(:@immediate))
      assert_equal('smtp.google.com', appender.server)
      assert_equal(443, appender.port)
      assert_equal('google.com', appender.domain)
      assert_equal('lbrinn', appender.acct)
      assert_equal(:tls, appender.authtype)
      assert_equal("I'm rich and you're not", appender.subject)
    end

  end  # class TestEmail

  class Smtp
    attr_accessor :server, :port, :domain, :acct, :passwd, :authtype,
                  :from, :to, :message

    def initialize( *args )
      smtp.server = args.shift
      smtp.port = args.shift
      smtp.domain = args.shift
      smtp.acct = args.shift
      smtp.passwd = args.shift
      smtp.authtype = args.shift
    end

    def sendmail( *args )
      smtp.message = args.shift
      smtp.from = args.shift
      smtp.to = args.shift
    end
  end  # class Smtp

end  # module TestLogging
end  # module TestAppenders


class Net::SMTP
  def self.start( *args ) 
    smtp = TestLogging::TestAppenders::Smtp.new(*args)
    yield smtp
  end
end

# EOF
