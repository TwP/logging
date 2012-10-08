require 'rspec'
require 'logging'
#spec_helper - adjust path, because this is applicable to within the logging source-code.  Yours would be
#require 'logging/rspec/logging_helper'
require 'rspec/logging_helper'

RSpec.configure do |config|
  config.extend RSpec::LoggingHelper
end

# a spec file
describe 'Foo' do
	capture_log_messages
  it 'should be able to read a log message' do
		Logging.logger['root'].debug 'foo'
    @log_output.readline.strip.should =~ /foo/
  end
end

describe 'Bar' do
  it 'should not be able to read a log message because we did not call capture_log_messages' do
		Logging.logger['root'].debug 'foo'
    @log_output.should be_nil
  end
end

RSpec::Core::Runner.run([File.dirname(__FILE__)], $stderr, $stdout)
