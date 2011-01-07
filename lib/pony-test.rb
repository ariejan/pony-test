require 'uri'

unless defined?(Pony)
  raise("pony-test requires Pony")
end

#reopen Pony module and replace mail method
module Pony
  def self.mail(options)
    TestHelpers.deliver(build_mail(options))
  end

  module TestHelpers
    @@deliveries = []
    @@current_email = nil
    @@current_email_address = nil

    def self.deliver(email)
      @@deliveries << email
      @@current_email = email
    end

    def deliveries
      @@deliveries
    end
    alias_method :all_email, :deliveries

    def current_email
      @@current_email || raise('No current email')
    end

    def current_email=(email)
      @@current_email = email
    end

    def current_email_address
      @@current_email_address
    end

    def current_email_address=(address)
      @@current_email_address = address
    end

    def reset_mailer
      self.deliveries.clear
      self.current_email_address = nil
      self.current_email = nil
    end

    def last_email_sent
      self.current_email = deliveries.last
      self.current_email
    end

    def inbox_for(opts = {})
      address = opts[:address]
      if address.nil? || address.empty?
        address = self.current_email_address
      end

      unless address.nil? || address.empty?
        self.current_email_address = address
      end

      #current_email_address should either be nil or have a specific address
      if current_email_address.nil?
        deliveries
      else
        deliveries.select do |email| 
          (email.to && email.to.include?(address)) || 
            (email.bcc && email.bcc.include?(address)) || 
            (email.cc && email.cc.include?(address))
        end
      end
    end
    alias_method :inbox, :inbox_for

    def open_email_for(opts = {})
      self.current_email = find_email(opts).first
    end
    alias_method :open_email, :open_email_for

    def find_email_for(opts = {})
      email = inbox_for(opts)

      if opts[:with_subject]
        email = email.select { |m| m.subject =~ Regexp.new(opts[:with_subject]) }
      end

      if opts[:with_body]
        email = email.select { |m| m.body.to_s =~ Regexp.new(opts[:with_body]) }
      end

      if email.empty?
        raise "Could not find email. \n Found the following email:\n\n #{deliveries.to_s}"
      end

      email
    end
    alias_method :find_email, :find_email_for

    def email_links(email = current_email)
      links = URI.extract(email.body.to_s, ['http', 'https'])
      raise "No links found in #{email.body}" if links.nil? || links.empty?
      links
    end

    def email_links_matching(pattern, email = current_email)
      pattern = /#{Regexp.escape(pattern)}/ unless pattern.is_a?(Regexp)
      links   = email_links(email).select { |link| link =~ pattern }
      raise "No link found matching #{pattern.inspect} in #{email.body}" if links.nil? || links.empty?
      links
    end
  end
end
