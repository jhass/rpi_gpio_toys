#!/usr/bin/env ruby
require './lcd'

LCD.new do
  puts "Hello World!\nHow are you?"
  sleep 2
  puts "I'm fine, thanks!"
end

lcd = LCD.new
lcd.puts "That's great to hear!"
lcd.close
