
require 'drb'
require 'yaml'
require 'uri'

source_number = ARGV[0]
dest_number = ARGV[1]

# Execute this by running "ruby initiate.rb 2065551212 2095551212"
unless dest_number
  puts "Usage: #{$0} <first_number> <second_number>"
  exit 1
end

local_config = YAML::load(File.read(File.dirname(__FILE__) + '/local_config.yml')) rescue {}
agi_config = local_config['agi'] || {}
drb_config = local_config['drb'] || {}

agi_url = URI::Generic.build :scheme => 'agi', :port => agi_config['listening_port'],
  :host => agi_config['listening_host'] || Socket.gethostname,
  :path => '/',
  :query => "context=default&connect_to=#{dest_number}"

puts "agi_url: #{agi_url}"
puts "drb_config: #{drb_config.inspect}"

Adhearsion = DRbObject.new_with_uri "druby://localhost:#{drb_config['port']}"

Adhearsion.proxy.call_and_exec "Local/#{source_number}@#{local_config['outgoing_context']}",
  'AGI', :args => agi_url.to_s, :caller_id => local_config['caller_id']
