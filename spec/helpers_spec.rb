require 'spec_helper'

describe Pony::TestHelpers do
  include Pony::TestHelpers

  RSpec::Matchers.define :match_email do |expected|
    match do |actual|
      actual == Pony.build_mail(expected)
    end
  end

  RSpec::Matchers.define :match_emails do |*expected|
    match do |actual|
      actual == expected.map{ |mail| Pony.build_mail(mail) }
    end
  end

  EMAIL_1   = { :to => 'foo@example.com', :from => 'bar@example.com', :subject => 'Hello there', :body => 'Hi' }
  EMAIL_2   = { :to => 'bob@example.com', :from => 'neb@example.com', :subject => 'Sup buddy', :body => 'Geez' }
  EMAIL_3   = { :to => 'rob@example.com', :from => 'nib@example.com', :subject => 'Come on already', :body => 'Man' }
  EMAIL_CC  = { :to => 'rob@example.com', :cc => 'foo@example.com', :from => 'nib@example.com', :subject => 'Come on already', :body => 'Geez' }
  EMAIL_BCC = { :to => 'neb@example.com', :bcc => 'foo@example.com', :from => 'nib@example.com', :subject => 'Hello joe', :body => 'Man' }
  
  LINKS = ['http://example.com/foobar', 'https://www.example.com', 'http://example.com/food/']
  EMAIL_LINKS_1 = { :to => 'foo@example.com', :from => 'bar@example.com', :subject => 'Coffee', :body => 'Hi ' + LINKS[0] + ' ' + LINKS[1] }
  EMAIL_LINKS_2 = { :to => 'bob@example.com', :from => 'neb@example.com', :subject => 'The goods', :body => 'Read this: ' + LINKS[2] }

  before(:each) do
    reset_mailer
    deliveries.empty?.should == true
  end

  describe 'deliveries' do
    it 'should capture Pony mail deliveries' do
      Pony.mail(EMAIL_1)
      deliveries.last.should match_email EMAIL_1
    end
  end

  describe 'current_email' do
    it 'should return the last email sent by default' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      current_email.should match_email EMAIL_3
    end

    it 'should raise an error when no email' do
      lambda {current_email}.should raise_error
    end
  end
  
  describe 'reset_mailer' do
    it 'should clear deliveries, current_email, and current_email_address' do
      Pony.mail(EMAIL_1)
      self.current_email_address = 'foo@example.com'
      deliveries.length.should == 1
      current_email.should_not == nil
      current_email_address.should_not == nil
      reset_mailer
      deliveries.empty?.should == true
      lambda {current_email}.should raise_error
      current_email_address.should == nil
    end
  end

  describe 'last_email_sent' do
    it 'should return the last email sent' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      last_email_sent.should match_email EMAIL_3
    end

    it 'should set current email to the last email sent' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      #change current_email to something else first
      open_email
      current_email.should match_email EMAIL_1
      last_email_sent
      current_email.should match_email EMAIL_3
    end

    it 'should raise an error when no email' do
      lambda {last_email_sent}.should raise_error
    end
  end

  describe 'inbox_for' do
    it 'should return only email for one email address' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      Pony.mail(EMAIL_CC) && Pony.mail(EMAIL_BCC)

      inbox_for(:address => 'foo@example.com').should match_emails EMAIL_1, EMAIL_CC, EMAIL_BCC
    end

    it 'should return all email when no address specified' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      Pony.mail(EMAIL_CC) && Pony.mail(EMAIL_BCC)
      email = inbox
      email.length.should == 5
    end

    it 'should set current_email_address' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      Pony.mail(EMAIL_CC) && Pony.mail(EMAIL_BCC)
      email = inbox_for(:address => 'foo@example.com')
      current_email_address.should == 'foo@example.com'
    end

    it 'should use current_email_address by default' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      Pony.mail(EMAIL_CC) && Pony.mail(EMAIL_BCC)
      #set current address first
      open_email_for(:address => 'foo@example.com')
      current_email_address.should == 'foo@example.com'

      inbox.should match_emails EMAIL_1, EMAIL_CC, EMAIL_BCC
    end

    it 'should not raise an error when there is no email' do
      inbox
    end
  end

  describe 'open_email_for' do
    it 'should return the first matching email' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      open_email_for(:address => 'bob@example.com').should match_email EMAIL_2
    end

    it 'should find an email by subject' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      open_email(:with_subject => 'already').should match_email EMAIL_3
    end

    it 'should find an email by body' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      open_email(:with_body => 'Geez').should match_email EMAIL_2
    end

    it 'should set current_email' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      open_email(:with_body => 'Geez').should match_email EMAIL_2
      current_email.should match_email EMAIL_2
    end

    it 'should set current_email_address' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      open_email_for(:address => 'bob@example.com').should match_email EMAIL_2
      current_email_address.should == 'bob@example.com'
    end

    it 'should use current_email_address by default' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      #set current address to something else
      inbox_for(:address => 'foo@example.com')
      current_email_address.should == 'foo@example.com'

      open_email_for(:address => 'bob@example.com').should match_email EMAIL_2
      current_email_address.should == 'bob@example.com'
    end

    it 'should return the first sent email when address not specified' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      open_email.should match_email EMAIL_1
      current_email_address.should == nil
    end

    it 'should raise an error when no matching email' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      lambda {open_email(:with_subject => 'viagra')}.should raise_error
    end

    it 'should raise an error when there is no email' do
      lambda {open_email}.should raise_error
    end
  end

  describe 'find_email_for' do
    it 'should return all matching email' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      Pony.mail(EMAIL_CC) && Pony.mail(EMAIL_BCC)

      find_email_for(:address => 'foo@example.com').should match_emails EMAIL_1, EMAIL_CC, EMAIL_BCC
    end

    it 'should find email by subject' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      Pony.mail(EMAIL_CC) && Pony.mail(EMAIL_BCC)

      find_email(:with_subject => 'Hello').should match_emails EMAIL_1, EMAIL_BCC
    end

    it 'should find email by body' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      Pony.mail(EMAIL_CC) && Pony.mail(EMAIL_BCC)

      find_email(:with_body => 'Man').should match_emails EMAIL_3, EMAIL_BCC
    end

    it 'should not set current_email' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      Pony.mail(EMAIL_CC) && Pony.mail(EMAIL_BCC)

      find_email(:with_body => 'Geez')
      current_email.should match_email EMAIL_BCC
    end

    it 'should set current_email_address' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      Pony.mail(EMAIL_CC) && Pony.mail(EMAIL_BCC)

      #set current address to something else
      inbox_for(:address => 'foo@example.com')
      current_email_address.should == 'foo@example.com'
      email = find_email_for(:address => 'neb@example.com')
      current_email_address.should == 'neb@example.com'
    end

    it 'should use current_email_address by default' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      Pony.mail(EMAIL_CC) && Pony.mail(EMAIL_BCC)

      open_email_for(:address => 'foo@example.com')
      find_email.should match_emails EMAIL_1, EMAIL_CC, EMAIL_BCC
    end

    it 'should return all email when address not specified' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      Pony.mail(EMAIL_CC) && Pony.mail(EMAIL_BCC)

      find_email.length.should == 5
    end

    it 'should raise an error when no matching email' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      Pony.mail(EMAIL_CC) && Pony.mail(EMAIL_BCC)
      lambda {find_email(:with_body => 'gold chains')}.should raise_error
    end

    it 'should raise an error when there is no email' do
      lambda {find_email}.should raise_error
    end
  end

  describe 'email_links' do
    it 'should return all links in current_email' do
      Pony.mail(EMAIL_LINKS_1)
      email_links.should == LINKS[0..1]
    end

    it 'should return all links in given email' do
      Pony.mail(EMAIL_LINKS_1) && Pony.mail(EMAIL_LINKS_2)
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      email = open_email(:with_subject => 'goods')

      #to ensure it is not just reading current_email
      open_email(:with_subject => 'Coffee')

      email_links(email).should == LINKS[2..2]
    end

    it 'should raise an error when no links' do
      Pony.mail(EMAIL_1) && Pony.mail(EMAIL_2) && Pony.mail(EMAIL_3)
      open_email
      current_email.should_not == nil
      lambda {email_links}.should raise_error
    end

    it 'should raise an error when no email specified, nor current_email' do
      lambda {email_links}.should raise_error
    end
  end

  describe 'email_links_matching' do
    it 'should return all matching links in current_email' do
      Pony.mail(EMAIL_LINKS_1) && Pony.mail(EMAIL_LINKS_2)
      open_email

      email_links_matching('foobar').should == LINKS[0..0]
    end

    it 'should return all matching links in an email' do
      Pony.mail(EMAIL_LINKS_1) && Pony.mail(EMAIL_LINKS_2)
      email = open_email                            
      
      #to ensure it is not just reading current_email
      last_email_sent
      email_links_matching('foobar', email).should == LINKS[0..0]
    end

    it 'should raise an error when no matching links' do
      Pony.mail(EMAIL_LINKS_1) && Pony.mail(EMAIL_LINKS_2)
      
      lambda {email_links_matching('food')}.should_not raise_error
      lambda {email_links_matching('wood')}.should raise_error
    end

    it 'should raise an error when no email specified, nor current_email' do
      lambda {email_links_matching('example')}.should raise_error
    end
  end
end
