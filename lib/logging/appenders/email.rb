
require 'net/smtp'
require 'time' # get rfc822 time format

# a replacement EmailOutputter.  This is essentially the default EmailOutptter from Log4r but with the following
# changes:
#   1) if there is data to send in an email, then do not send anything
#   2) connect to the smtp server at the last minute, do not connect at startup and then send later on.
#   3) Fix the To: field so that it looks alright.
module Logging::Appenders

class Email < ::Logging::Appender

  attr_reader :server, :port, :domain, :acct, :authtype, :subject

  def initialize( name, opts = {} )
    super(name, opts)

    @buff = []
    @buffsize = opts.getopt :buffsize, 100, :as => Integer

    # get the immediate levels -- no buffering occurs at these levels, and
    # an e-mail is sent as soon as possible
    @immediate = []
    opts.getopt(:immediate_at, '').split(',').each do |lvl|
      num = ::Logging.level_num(lvl.strip)
      next if num.nil?
      @immediate[num] = true
    end

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
  
  # call-seq:
  #    flush
  #
  # Create and send an email containing the current message buffer.
  #
  def flush
    sync { send_mail }
    self
  end

  # call-seq:
  #    close( footer = true )
  #
  # Close the e-mail appender and then flush the message buffer. This will
  # ensure that a final e-mail is sent with any remaining messages.
  #
  def close( footer = true )
    super
    flush
  end

  # cal-seq:
  #    queued_messages    => integer
  #
  # Returns the number of messages in the buffer.
  #
  def queued_messages
    @buff.length
  end


  private

  # call-seq:
  #    write( event )
  #
  # Write the given _event_ to the e-mail message buffer. The log event will
  # be processed through the Layout associated with this appender.
  #
  def write( event )
    immediate = false
    str = if event.instance_of?(::Logging::LogEvent)
        immediate = @immediate[event.level]
        @layout.format(event)
      else
        event.to_s
      end
    return if str.empty?

    @buff << str
    send_mail if @buff.length >= @buffsize || immediate
    self
  end

  # Connect to the mail server and send out any buffered messages.
  #
  def send_mail
    return if @buff.empty?

    ### build a mail header for RFC 822
    rfc822msg =  "From: #{@from}\n"
    rfc822msg << "To: #{@to.join(",")}\n"
    rfc822msg << "Subject: #{@subject}\n"
    rfc822msg << "Date: #{Time.new.rfc822}\n"
    rfc822msg << "Message-Id: <#{"%.8f" % Time.now.to_f}@#{@domain}>\n\n"
    rfc822msg << @buff.join

    ### send email
    begin 
      Net::SMTP.start(*@params) {|smtp| smtp.sendmail(rfc822msg, @from, @to)}
    rescue StandardError => err
      self.level = :off
      ::Logging.log_internal {'e-mail notifications have been disabled'}
      ::Logging.log_internal(-2) {err}
    ensure
      @buff.clear
    end
  end

end   # class Email
end   # module Logging::Appenders

# EOF
