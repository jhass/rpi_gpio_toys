#!/usr/bin/env ruby
require 'rubygems'
require 'barometer'
require './lcd'

Barometer.config = { 1 => :wunderground }

barometer = Barometer.new("Hannover, Germany")

LCD.new(:mode => :'4bit') do
  wheater = barometer.measure
  wheater.current.temperature.metric!

  puts "Location: #{wheater.measurements.first.station.city}"

  loop do
    wheater = barometer.measure
    wheater.current.temperature.metric!

    condition = wheater.current.icon.dup
    condition.gsub!(/^t/, "thunder")
    condition.gsub!("ly", "ly ")
    condition.gsub!("chance", "chance of ")
    hscroll "Temperature: #{wheater.current.temperature} - Condition: #{condition} - At: #{wheater.current.current_at.to_t.strftime("%H:%m")} -",
            :speed => 60, :times => 5
  end
end
