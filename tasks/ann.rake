# $Id$

begin
  require 'bones/smtp_tls'
rescue LoadError
  require 'net/smtp'
end
require 'time'

namespace :ann do

  file PROJ.ann_file do
    puts "Generating #{PROJ.ann_file}"
    File.open(PROJ.ann_file,'w') do |fd|
      fd.puts("#{PROJ.name} version #{PROJ.version}")
      fd.puts("    by #{Array(PROJ.authors).first}") if PROJ.authors
      fd.puts("    #{PROJ.url}") if PROJ.url
      fd.puts("    (the \"#{PROJ.release_name}\" release)") if PROJ.release_name
      fd.puts
      fd.puts("== DESCRIPTION")
      fd.puts
      fd.puts(PROJ.description)
      fd.puts
      fd.puts(PROJ.changes.sub(%r/^.*$/, '== CHANGES'))
      fd.puts
      PROJ.ann_paragraphs.each do |p|
        fd.puts "== #{p.upcase}"
        fd.puts
        fd.puts paragraphs_of(PROJ.readme_file, p).join("\n\n")
        fd.puts
      end
      fd.puts PROJ.ann_text if PROJ.ann_text
    end
  end

  desc "Create an announcement file"
  task :announcement => PROJ.ann_file

  desc "Send an email announcement"
  task :email => PROJ.ann_file do
    from = PROJ.ann_email[:from] || PROJ.email
    to   = Array(PROJ.ann_email[:to])

    ### build a mail header for RFC 822
    rfc822msg =  "From: #{from}\n"
    rfc822msg << "To: #{to.join(',')}\n"
    rfc822msg << "Subject: [ANN] #{PROJ.name} #{PROJ.version}"
    rfc822msg << " (#{PROJ.release_name})" if PROJ.release_name
    rfc822msg << "\n"
    rfc822msg << "Date: #{Time.new.rfc822}\n"
    rfc822msg << "Message-Id: "
    rfc822msg << "<#{"%.8f" % Time.now.to_f}@#{PROJ.ann_email[:domain]}>\n\n"
    rfc822msg << File.read(PROJ.ann_file)

    params = [:server, :port, :domain, :acct, :passwd, :authtype].map do |key|
      PROJ.ann_email[key]
    end

    params[3] = PROJ.email if params[3].nil?

    if params[4].nil?
      STDOUT.write "Please enter your e-mail password (#{params[3]}): "
      params[4] = STDIN.gets.chomp
    end

    ### send email
    Net::SMTP.start(*params) {|smtp| smtp.sendmail(rfc822msg, from, to)}
  end
end  # namespace :ann

desc 'Alias to ann:announcement'
task :ann => 'ann:announcement'

CLOBBER << PROJ.ann_file

# EOF
