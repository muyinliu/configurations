#!/usr/bin/ruby -w
# 
# Huobi Market Monitor plugin for BitBar on macOS's menu bar
# 
#   author: Muyinliu Xing <muyinliu@gmail.com>
#     date: 2019-07-30
# modified: 2020-09-04
#
# dependencies:
#   - curl
#   - https proxy listen on port 1087
#   - jq
#   - ruby
require 'rubygems'
require 'json'

config_path = ENV['HOME'] + '/.config/bitbar/huobi_market/huobi_market.json'
config_file = File.read(config_path)
config = JSON.parse(config_file)
symbol          = config['symbol']
symbol_icon     = config['symbol_icon']
mark_price      = config['mark_price']   # plus for goling long, minus for goling short
up_color        = config['up_color']
down_color      = config['down_color']
default_color   = config['default_color']
price_precision = config['price_precision']

current_price = `ALL_PROXY="http://127.0.0.1:1087" curl --connect-timeout 5 -s "https://api.huobi.pro/market/trade?symbol=#{symbol}" | /usr/local/bin/jq ".tick.data[0].price"`.to_f

if mark_price == 0
    color = default_color
elsif mark_price > 0
    # going long
    gains = (current_price - mark_price) * 100 / mark_price
    if current_price > mark_price
        color = up_color
    else
        color = down_color
    end
else
    # going short
    gains = (current_price + mark_price) * 100 / mark_price
    if current_price < -mark_price
        color = up_color
    else
        color = down_color
    end
end

current_price_string = format("%.#{price_precision}f", current_price)

if mark_price == 0
    puts "#{symbol_icon} #{current_price_string} | color=#{color}"
else
    price_fixed_formatter = "%.#{price_precision}f"
    puts "#{symbol_icon} #{price_fixed_formatter % current_price}(#{'%.2f' % gains}%) | color=#{color}"
end
puts "---"

mark_price_script_path = ENV['HOME'] + '/.config/bitbar/huobi_market/huobi_market_mark_price.rb'
puts "Mark price, current: #{mark_price} | refresh=true terminal=false bash=/usr/bin/ruby param1=\"#{mark_price_script_path}\" param2=\"#{config_path}\"";