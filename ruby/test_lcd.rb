#!/usr/bin/env ruby
require './lcd'

LCD.session do
  LCD.position 0, 0
  LCD.puts "Hello World!\nHow are you?"
end
