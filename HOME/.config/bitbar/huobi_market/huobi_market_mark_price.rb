#!/usr/bin/ruby -w

require 'rubygems'
require 'json'

config_path = ARGV[0]
puts "#{config_path}"
config_file = File.read(config_path)
config = JSON.parse(config_file)
old_mark_price = config['mark_price'].to_f

if old_mark_price < 0
    old_mark_price = -old_mark_price
end

config['mark_price'] = `osascript -e "display dialog \\\"Mark price\\\" buttons {\\\"Going Long\\\", \\\"Going Short\\\"} default button 1 default answer \\\"#{old_mark_price}\\\"" -e 'if the button returned of the result is "Going Long" then' -e 'return text returned of the result as real as text' -e 'else' -e 'return -(text returned of the result as real) as text' -e 'end if'`.to_f
File.open(config_path, 'w') { |file| file.write(JSON.generate(config)) }