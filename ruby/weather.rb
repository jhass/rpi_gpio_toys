#!/usr/bin/env ruby
require 'rubygems'
require 'barometer'
require './lcd'

Barometer.config = { 1 => :wunderground }

barometer = Barometer.new("Hannover, Germany")

LCD.new do
  first_time = true
  loop do
    wheater = barometer.measure
    wheater.current.temperature.metric!

    clear if first_time
    puts "Location: #{wheater.measurements.first.station.city}" if first_time
    clear_row unless first_time
    hscroll "Temperature: #{wheater.current.temperature}  Condition: #{wheater.current.icon}", :speed => 20.8
    first_time = false
  end
end
