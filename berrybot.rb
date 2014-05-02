require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'blather/client/dsl'
require 'json'

# Heroku log flush
$stdout.sync = true


$catz   = File.read("catz.emoticons").split("\n")
$dances = File.read("dance.links"   ).split("\n")
$starz  = JSON.parse(File.read("stars_named.json"))

module App
  extend Blather::DSL


  def self.run
    EM.run do
      client.run

      EM.add_periodic_timer(17 * 60) { random_status if Random.rand > 0.75 }
    end
  end


  setup ENV["BERRI_LOGIN"], ENV["BERRI_PASSWORD"]


  when_ready do
    puts "CONNECTED"

    random_status
  end


  disconnected do
    puts "DISCONNECTED"
  end


  # Before all things
  before do |s|
    # puts "STANZA " + "[#{s.class}::#{s.type}]".red + " #{s.inspect}".cyan
  end


  ### TIME EVENTS ########################

  def self.random_status
    star = $starz.sample
    set_status :available, "Heading to #{star["starName"]}, see you in #{star["dist"]} light years."
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

  message :chat?, :body => /warp speed/i do |m|
    star = $starz.sample
    say m.from.strip!, "#{star["starName"]} is #{star["dist"]} light years away"
  end

  message :chat?, :body => /basik/i do |m|
    basik = Basik::BundledGem.new

    say m.from.strip!, basik.show_cext_greeting
    say m.from.strip!, basik.show_ruby_greeting
  end

  message :chat?, :body => /meow/i do |m|
    say m.from.strip!, $catz.sample
  end

  message :chat?, :body => /nyan/i do |m|
    say m.from.strip!, "http://fc00.deviantart.net/fs71/f/2011/310/5/a/giant_nyan_cat_by_daieny-d4fc8u1.png"
  end

  message :chat?, :body => /dance/i do |m|
    say m.from.strip!, $dances.sample
  end


  message :chat?, :body => 'roster' do |m|
    my_roster.grouped.each do |group, items|
      say m.from, "*** #{group || 'Ungrouped'} ***"

      items.each do |item|
        say m.from, "- #{item.name} (#{item.jid})"
      end
    end
  end


  # TODO message dictionary of user entered regex events. Store in json or text file?
  # TODO handle passing or halting message to other events in order
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
