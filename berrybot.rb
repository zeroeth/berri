require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'blather/client/dsl'

# Heroku log flush
$stdout.sync = true

module App
  extend Blather::DSL

  def self.run
    EM.run { client.run }
  end


  setup ENV["BERRI_LOGIN"], ENV["BERRI_PASSWORD"]

  catz = File.read("catz.emoticons").split("\n")


  when_ready do
    puts "CONNECTED"
  end


  disconnected do
    puts "DISCONNECTED"
  end


  # Before all things
  before do |s|
    # puts "STANZA " + "[#{s.class}::#{s.type}]".red + " #{s.inspect}".cyan
  end


  ### BUDDY LIST #########################

  subscription :request? do |s|
    puts "SUBSCRIBE REQUEST #{s.from}"
    write_to_stream s.approve!
  end

  presence do |s|
    # Separate event for google multi user chat
    if !s.from.node.match /private-chat/
      puts "PRESENCE #{s.from} (#{[s.state,s.message].compact.join('|')})".green+"\n"
    end
  end



  ### NORMAL CHAT ########################

  message :chat?, :body => 'meow' do |m|
    say m.from.strip!, catz.sample
  end


  message :chat?, :body => 'roster' do |m|
    my_roster.grouped.each do |group, items|
      say m.from, "*** #{group || 'Ungrouped'} ***"

      items.each do |item|
        say m.from, "- #{item.name} (#{item.jid})"
      end
    end
  end


  message :chat?, :body do |m|
    # The request that comes from google hangouts
    if m.class != Blather::Stanza::Message::MUCUser
      puts "CHAT #{m.class} #{m.from}: #{m.body}".blue
    end
  end



  ### MULTI USER CHAT ####################

  muc_user_message do |s|
    puts "MUCMESSAGE #{s.class} #{s.from} #{s.body}".magenta
    join s.from, jid.node
  end


  muc_user_presence do |s|
    puts "MUC::PRESENCE #{s.class} #{s.from} #{s.state}".yellow
  end


  message :groupchat?, :body do |m|
    if m.from.resource != jid.node
      puts "GROUPCHAT #{m.from}: #{m.body}".cyan
    end
  end

  message :groupchat?, :body => 'meow' do |m|
    say m.from.strip!, ":3", :groupchat
  end
end

trap(:INT)  { EM.stop }
trap(:TERM) { EM.stop }

App.run
