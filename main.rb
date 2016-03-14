#!/usr/bin/env ruby

require 'mechanize'
require 'active_support/all'
require 'pathname'

class Reaper

  DOMAINS = %w(
    stgeorge
    banksa
    bankofmelbourne
  )

  VARS = %w(username password security_number)

  attr_reader :domain_index

  def initialize
    @domain_index = 0
    VARS.each do |var|
      raise "Expected #{var.upcase} to be set" unless __send__(var)
    end
  end

  def root
    if ENV['TEST_PORT']
      "http://localhost:#{ENV['TEST_PORT']}"
    else
      "https://ibanking.#{DOMAINS[domain_index]}.com.au"
    end
  end

  VARS.each { |var| define_method(var) { ENV[var.upcase] } }

  def cycle_domain
    @domain_index += 1
    @domain_index %= DOMAINS.length
    puts 'Domain cycled'
  end

  def store
    Pathname(Dir.pwd) + 'data'
  end

  def reap
    puts "Reaping from #{root}"

    a = Mechanize.new { |agent|
      agent.user_agent_alias = 'Mac Safari'
    }

    a.get "#{root}/ibank" do |login_page|
      puts 'Logging in'

      home_page = login_page.form_with(name: 'logonForm') { |form|
        form.userID         = username
        form.securityNumber = security_number
        form.password       = password
      }.submit

      headings = home_page / '#acctSummaryList h2'

      puts 'Accounts: '
      headings.each { |h| puts " - #{h.text}" }

      headings.each do |heading|
        name = heading.text.gsub(/\u00a0/, ' ').strip
        link = (heading / 'a').first
        index = link['href'][/index=(\d+)/, 1].to_i
        account_store = store + name
        statement_store = account_store + 'Statements'

        puts "Checking statements for #{name}"
        query = {
            method:    '',
            acctIndex: index.to_s,
            stmtType:  '0',
            dateFrom:  '01/01/2000',
            dateTo:    Time.now.strftime('%d/%m/%Y')
        }
        statements = a.post "#{root}/ibank/viewStmt_processSelectedAcct.action", query
        statements.links.each do |statement_link|
          if statement_link.href.starts_with? 'viewStmt_processStatement.action'
            date = Time.parse(statement_link.node.text.gsub(/\u00a0/, ' ').strip)
            path = statement_store + "#{name} #{date.strftime '%Y-%m-%d'}.pdf"
            unless path.exist?
              puts "Downloading #{path.basename} ..."
              statement_link.click.save path.to_s
            end
          end
        end

        # 6 Months of CSV data is stupidly optimistic.
        csv_store = account_store + 'CSV'

        (0..6).each do |offset|
          target = offset.months.ago
          threshold = Time.parse(target.strftime '%Y-%m-07')
          if Time.now > threshold
            path = csv_store + "#{name} #{target.strftime '%Y-%m'}.csv"
            unless path.exist?
              puts "Downloading #{path.basename} ..."
              query = {
                  newPage:            '1',
                  index:              index.to_s,
                  selectedOption:     '2',
                  dateFrom:           target.strftime('01/%m/%Y'),
                  dateTo:             (target + 1.month - 1.day).strftime('%d/%m/%Y'),
                  selectedDrCrOption: '0'
              }
              a.post "#{root}/ibank/showTransactionHistory.action", query # This does some session stuff
              query = {
                  newPage:          '1',
                  index:            index.to_s,
                  exportFileFormat: 'CSV',
                  exportDateFormat: 'yyyyMMdd',
                  action:           'exporttransactionHistory',
                  httpMethod:       'GET'
              }
              a.get("#{root}/ibank/exportTransactions.action", query).save path
            end
          end
        end
      end
    end
  rescue => e
    puts e
    STDERR.puts e.backtrace
    cycle_domain
  end

  INTERVAL = 2.hours

  def self.run
    reaper = new
    reaper.reap
    loop do
      puts "Next reap will be at #{Time.now + INTERVAL}"
      sleep INTERVAL
      reaper.reap
    end
  end

end

Reaper.run if __FILE__ == $0
