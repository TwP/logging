
require 'net/smtp'
require 'time' # get rfc822 time format

# a replacement EmailOutputter.  This is essentially the default EmailOutptter from Log4r but with the following
# changes:
#   1) if there is data to send in an email, then do not send anything
#   2) connect to the smtp server at the last minute, do not connect at startup and then send later on.
#   3) Fix the To: field so that it looks alright.
module Logging::Appenders

class Email < ::Logging::Appender
  include Buffering

  attr_reader :server, :port, :domain, :acct, :authtype, :subject

  # TODO: make the from/to fields modifiable
  #       possibly the subject, too

  def initialize( name, opts = {} )
    super(name, opts)

    af = opts.getopt(:buffsize) ||
         opts.getopt(:buffer_size) ||
         100
    configure_buffering({:auto_flushing => af}.merge(opts))

    # get the SMTP parameters
    @from = opts.getopt(:from)
    raise ArgumentError, 'Must specify from address' if @from.nil?

    @to = opts.getopt(:to, '').split(',')
    raise ArgumentError, 'Must specify recipients' if @to.empty?

    @server   = opts.getopt :server, 'localhost'
    @port     = opts.getopt :port, 25, :as => Integer
    @domain   = opts.getopt(:domain, ENV['HOSTNAME']) || 'localhost.localdomain'
    @acct     = opts.getopt :acct
    @passwd   = opts.getopt :passwd
    @authtype = opts.getopt :authtype, :cram_md5, :as => Symbol
    @subject  = opts.getopt :subject, "Message of #{$0}"
    @params   = [@server, @port, @domain, @acct, @passwd, @authtype]
  end


private

  # This method is called by the buffering code when messages need to be
  # sent out as an email.
  #
  def canonical_write( str )
    ### build a mail header for RFC 822
    rfc822msg =  "From: #{@from}\n"
    rfc822msg << "To: #{@to.join(",")}\n"
    rfc822msg << "Subject: #{@subject}\n"
    rfc822msg << "Date: #{Time.new.rfc822}\n"
    rfc822msg << "Message-Id: <#{"%.8f" % Time.now.to_f}@#{@domain}>\n\n"
    rfc822msg << str

    ### send email
    Net::SMTP.start(*@params) {|smtp| smtp.sendmail(rfc822msg, @from, @to)}
    self
  rescue StandardError, TimeoutError => err
    self.level = :off
    ::Logging.log_internal {'e-mail notifications have been disabled'}
    ::Logging.log_internal(-2) {err}
  end

end   # class Email
end   # module Logging::Appenders

