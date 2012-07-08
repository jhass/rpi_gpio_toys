require './gpio'

module LCD
  ROWS = 19 # zero indexed 
  LINES = 1 # zero indexed

  PINS = {
    RS:	 0,
    E:	 1,
    D0:	17,
    D1:	18,
    D2:	21,
    D3:	22,
    D4:	23,
    D5:	24,
    D6:	25,
    D7:	 4
  }
  
  DATA_LINES = [:D0, :D1, :D2, :D3, :D4, :D5, :D6, :D7]

  COMMANDS = {
    LCD_CLEAR:		0x01,
    LCD_HOME:		0x02,
    LCD_ENTRY:		0x04,
    LCD_ON_OFF:		0x08,
    LCD_CDSHIFT:	0x10,
    LCD_FUNC:		0x20,
    LCD_CGRAM:		0x40,
    LCD_DGRAM:		0x80,

    LCD_ENTRY_SH:	0x01,
    LCD_ENTRY_ID:	0x02,

    LCD_ON_OFF_B:	0x01,
    LCD_ON_OFF_C:	0x02,
    LCD_ON_OFF_D:	0x04,

    LCD_FUNC_F:		0x04,
    LCD_FUNC_N:		0x08,
    LCD_FUNC_DL:	0x10,

    LCD_CDSHIFT_RL:	0x04
  }

  def self.session(&block)
    self.setup
    block.call
    self.cleanup
  rescue
    self.cleanup
  end

  def self.setup
    PINS.values.each do |pin|
      GPIO.output pin
      GPIO.write pin, :low
    end
   
    GPIO.write PINS[:E], :high
    3.times do
      self.command COMMANDS[:LCD_FUNC] | COMMANDS[:LCD_FUNC_DL] | COMMANDS[:LCD_FUNC_N]
    end

    self.command COMMANDS[:LCD_ON_OFF] | COMMANDS[:LCD_ON_OFF_D]
    self.command COMMANDS[:LCD_ENTRY] | COMMANDS[:LCD_ENTRY_ID]
    self.command COMMANDS[:LCD_CDSHIFT] | COMMANDS[:LCD_CDSHIFT_RL]
    self.clear
  end

  def self.cleanup
    PINS.values.each do |pin|
      GPIO.unexport pin
    end
  end
  
  def self.command(command)
    command = COMMANDS[command] if command.is_a? Symbol

    GPIO.write PINS[:RS], :low
    GPIO.write PINS[:E], :high

    DATA_LINES.each do |pin|
      GPIO.write PINS[pin], command & 1
      command = command >> 1
    end

    sleep 0.01
    GPIO.write PINS[:E], :low
    sleep 0.01
  end

  def self.position(x, y)
    command = COMMANDS[:LCD_DGRAM]
    command = command | 0x40 if y == 1
    self.command command+x
    @@current_line = y
    @@current_row = x
  end

  def self.puts(string)
    self.next_line unless self.clear?
    string.unpack("C*").each do |char|
      self.next_line if @@current_row > ROWS || char == 10 # 10 == \n
      next if char == 10
      @@clear = false

      GPIO.write PINS[:RS], :high
      GPIO.write PINS[:E], :high


      DATA_LINES.each do |pin|
        GPIO.write PINS[pin], char & 1
        char = char >> 1
      end

      GPIO.write PINS[:E], :low

      @@current_row = @@current_row+1
    end
  end

  def self.clear
    self.command :LCD_CLEAR
    self.position 0, 0
    @@clear = true
  end

  def self.next_line
    @@current_line = @@current_line+1
    if @@current_line > LINES
      self.clear
    else
      self.position 0, @@current_line
    end
  end

  def self.clear?
    @@clear
  end
end
