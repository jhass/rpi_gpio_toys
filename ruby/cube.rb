require './gpio'

class Cube
  PINS = {
    X1: 0,
    X2: 1,
    X3: 4,
    Y1: 14,
    Y3: 15,
    Y2: 17,
    Z3: 18,
    Z1: 21,
    Z2: 22
  }

  def initialize(&block)
    setup
    instance_eval &block if block_given?
  end

  def setup
    each do |pin|
      GPIO.output pin
    end

    all_off
  end

  def all_off
    each do |pin|
      GPIO.write pin, :low
    end
  end

  def each(&block)
    PINS.values.each(&block)
  end

  def light(x, y, z)
    write(x, y, z, :high)
  end

  def off(x, y, z)
    write(x, y, z, :low)
  end

  def blink(x, y, z, period=1)
    light(x, y, z)
    sleep period
    off(x, y, z)
  end

  def all_on
    loop do
      each_in_sequence do |x, y, z|
        blink(x, y, z, 0.0005)
      end
    end
  end

  def x
    [:X1, :X2, :X3]
  end
  alias_method :yz_area, :x

  def y
    [:Y1, :Y2, :Y3]
  end
  alias_method :xz_area, :y

  def z
    [:Z1, :Z2, :Z3]
  end
  alias_method :xy_area, :z

  def light_x_line(y, z, period=1)
    blink_period = 0.0005
    ((period/blink_period)/10).to_i.times do
      x.each do |x|
        blink(x, y, z, blink_period)
      end
    end
  end

  def light_y_line(x, z, period=1)
    blink_period = 0.0005
    ((period/blink_period)/10).to_i.times do
      y.each do |y|
        blink(x, y, z, blink_period)
      end
    end
  end

  def light_z_line(x, y, period=1)
    blink_period = 0.0005
    ((period/blink_period)/10).to_i.times do
      z.each do |z|
        blink(x, y, z, blink_period)
      end
    end
  end

  def light_area(level, period=1)
    if yz_area.include?(level)
      light_yz_area(level, period)
    elsif xz_area.include?(level) 
      light_xz_area(level, period)
    elsif xy_area.include?(level) 
       light_xy_area(level, period)
    end
  end

  def light_xz_area(y, period=1)
    blink_period = 0.0005
    ((period/blink_period)/30).to_i.times do
      each_in_xz_area(y) do |x, z|
        blink(x, y, z, blink_period)
      end
    end
  end

  def each_in_xz_area(y, &block)
    z.each do |z|
      x.each do |x|
        yield x, z
      end
    end
  end

  def light_yz_area(x, period=1)
    blink_period = 0.0005
    ((period/blink_period)/30).to_i.times do
      each_in_yz_area(x) do |y, z|
        blink(x, y, z, blink_period)
      end
    end
  end

  def each_in_yz_area(x, &block)
    z.each do |z|
      y.each do |y|
        yield y, z
      end
    end
  end

  def light_xy_area(z, period=1)
    blink_period = 0.0005
    ((period/blink_period)/30).to_i.times do
      each_in_xy_area(z) do |x, y|
        blink(x, y, z, blink_period)
      end
    end
  end

  def each_xy_area(&block)
    [:Z1, :Z2, :Z3].each(&block)
  end

  def each_in_xy_area(z, &block)
    y.each do |y|
      x.each do |x|
        yield x, y
      end
    end
  end

  def each_in_sequence(&block)
    z.each do |z|
      y.each do |y|
        x.each do |x|
          yield x, y, z
        end
      end
    end
  end

  def test
    each_in_sequence do |x, y, z|
      puts "#{x}, #{y}, #{z}"
      cube.light(x, y, z)
      gets
      cube.off(x, y, z)
    end
  end

  def write(x, y, z, value)
    [x, y, z].each do |pin|
      GPIO.write PINS[pin], value
    end
  end

end


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

    z.each do |z|
      y.each do |y|
        light_x_line(y, z, 0.3)
      end
    end

    z.each do |z|
      x.each do |x|
        light_y_line(x, z, 0.3)
      end
    end

    y.each do |y|
      x.each do |x|
        light_z_line(x, y, 0.3)
      end
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
