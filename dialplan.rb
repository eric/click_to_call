local_config = YAML::load(File.read(File.dirname(__FILE__) + '/local_config.yml')) rescue {}

module DialplanHelper
  attr_accessor :default_swift_voice
  attr_accessor :default_outgoing_context

  def input_phone_number(timeout)
    phone_number = wait_for_digit(timeout).to_s
    phone_number << input(phone_number == '1' ? 10 : 9, :timeout => timeout).to_s
  
    phone_number
  end
  
  def swift(message, options = {})
    voice = options[:voice] || default_swift_voice
    message = "#{voice}^#{message}" unless voice.empty?
    
    execute('swift', '%p' % message)
  end
  
  def cloudvox_dial(number, options = {})
    dial("Local/#{number}@#{default_outgoing_context}", options)
  end
end

default {
  # Include some helpers to make our life easier
  extend DialplanHelper
  
  # Setup our default voice and default outgoing context
  self.default_swift_voice = 'Callie'
  self.default_outgoing_context = local_config['outgoing_context']
  
  unless connect_to = call.variables[:connect_to]
     swift 'Please enter the number you wish to call.'

    connect_to = input_phone_number(10.seconds)
  end
  
  # Detect if we got a valid phone number or not
  unless connect_to.to_s.match(/^1?\d{10}$/)
    ahn_log "Could not call #{connect_to.inspect}."
    
    play 'cannot-complete-as-dialed'
    sleep 0.3
    play 'check-number-dial-again'
  else
    # Get swift to speak each number separately
    spaced_numbers = connect_to.split(//).join(' ')

    swift "Calling '#{spaced_numbers}'. Please wait..."
    cloudvox_dial connect_to, :caller_id => local_config['caller_id']
  end
}
