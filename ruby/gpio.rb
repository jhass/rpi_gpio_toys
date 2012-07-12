class GPIO
  @@exported_pins = []
  @@value_map = nil
  @@descriptors = {}
  def self.export(pin, direction="out")
    return if self.exported?(pin)
    `gpio export #{pin} #{direction}`
    @@exported_pins.push pin
  end

  def self.unexport(pin)
    return unless self.exported?(pin)
    `gpio unexport #{pin}`
    @@exported_pins.delete pin
  end

  def self.exported?(pin)
    return true if @@exported_pins.include?(pin)
    if File.exists?('/sys/class/gpio/gpio#{pin}')
      @@exported_pins.push pin
      return true
    end
    false
  end

  def self.output(pin)
    self.export pin, "out"
  end

  def self.input(pin)
    self.export pin, "in"
  end

  def self.write(pin, value)
    value = self.value_map[value] || value 
    self.get_descriptor_for(pin) do |io|
      io.write(value)
    end
  end

  def self.on(pin)
    self.write(pin, :high)
  end
  
  def self.off(pin)
    self.write(pin, :low)
  end

  private
  def self.get_descriptor_for(pin, &block)
    @@descriptors[pin] ||= Pin.new(pin)
    if block_given?
      block.call(@@descriptors[pin])
    else
      return @@descriptors[pin]
    end
  end

  def self.value_map
    return @@value_map unless @@value_map.nil?
    @@value_map = {}
    [["high", "low"], ["on", "off"]].each do |high, low|
      [:upcase!, :downcase!].each do |meth|
        high.send meth
        low.send meth
        [:to_s, :to_sym].each do |meth|
          @@value_map.merge!({high.send(meth) => "1", low.send(meth) => "0"})
        end
      end
    end
    @@value_map
  end



  class Pin
    def initialize(pin)
      @pin = pin
    end

    def write(value)
      return if @value == value
      @descriptor.seek(0)
      @descriptor.write(value)
      @value = value
    rescue NoMethodError, Errno::ENODEV
      @descriptor = open("/sys/class/gpio/gpio#{@pin}/value", "w")
      @descriptor.sync = true
      self.write(value)
    end
  end
end
