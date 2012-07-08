class GPIO
  @@exported_pins = []
  def self.export(pin)
    return if @@exported_pins.include? pin
    `echo #{pin} | sudo tee /sys/class/gpio/export`
    `sudo chgrp -RH --dereference users /sys/class/gpio/gpio#{pin}`
    `sudo chmod -R g+w+r /sys/class/gpio/gpio#{pin}/*`
    @@exported_pins.push pin
  end

  def self.unexport(pin)
    return unless @@exported_pins.include? pin
    `echo #{pin} | sudo tee /sys/class/gpio/unexport`
    @@exported_pins.delete pin
  end

  def self.output(pin)
    self.export pin
    open("/sys/class/gpio/gpio#{pin}/direction", "w") do |io|
      io.write("out")
    end
  end

  def self.input(pin)
    self.export pin
    open("/sys/class/gpio/gpio#{pin}/direction", "w") do |io|
      io.write("in")
    end
  end

  def self.write(pin, value=:high)
    value = ([:high, 1, "1", :on, "high", "on", "HIGH", "ON"].include?(value)) ? 1 : 0
    open("/sys/class/gpio/gpio#{pin}/value", "w") do |io|
      io.write(value)
    end
  end

  def self.on(pin=0)
    self.write(:high, pin)
  end
  
  def self.off(pin=0)
    self.write(:low, pin)
  end
end
