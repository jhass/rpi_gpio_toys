#!/usr/bin/env ruby
require './lcd'

LCD.new do
  puts "Hello World!\nHow are you?"
  sleep 2
  puts "I'm fine, thanks!"
  sleep 2
  puts "  Space test"
  puts " Is it working?"
end

lcd = LCD.new
lcd.puts "That's great to hear!"
sleep 4
lcd.puts "01234567890123456789 01234567890123456789"
lcd.close
