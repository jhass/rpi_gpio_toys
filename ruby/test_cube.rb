#!/usr/bin/env ruby
require './cube'

Cube.new do
  loop do
    3.times do 
      [[:X1, :Y1],
       [:X2, :Y1],
       [:X3, :Y1],
       [:X3, :Y2],
       [:X3, :Y3],
       [:X2, :Y3],
       [:X1, :Y3],
       [:X1, :Y2]].each do |x, y|
        20.times do
          light_z_line(:X2, :Y2, 0.005)
          light_z_line(x, y, 0.005)
        end
      end
    end

    nested_each(z, y) do |y, z|
      light_x_line(y, z, 0.3)
    end

    nested_each(z, x) do |x, z|
      light_y_line(x, z, 0.3)
    end

    nested_each(y, x) do |x, y|
      light_z_line(x, y, 0.3)
    end

    [xy_area, xz_area, yz_area].each do |area|
      area.each do |level|
        light_area(level, 0.2)
      end
      
      area.reverse.each do |level|
        light_area(level, 0.2)
      end
    end
  end
end
