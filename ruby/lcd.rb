require './gpio'

class LCD
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

  def initialize(&block)
    self.setup
    if block_given?
      instance_eval &block
      self.cleanup
    end
  rescue Exception => e
    self.cleanup
    raise e
  end

  def setup
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

  def cleanup
    PINS.values.each do |pin|
      GPIO.unexport pin
    end
  end
  alias_method :close, :cleanup  

  def command(command)
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

  def position(x, y)
    command = COMMANDS[:LCD_DGRAM]
    command = command | 0x40 if y == 1
    self.command command+x
    @current_line = y
    @current_row = x
  end

  def puts(input)
    self.next_line unless self.clear?

    string = ""
    input.each_line do |line|
      if line.size > ROWS+1
        i = 0
        last_space = -1
        line.each_char do |char|
          last_space = string.size if char == " "
          if i < ROWS+1
            string << char
            i = i+1
          else
            string << char
            string[last_space] = "\n" unless last_space == -1
            i = 0
          end
        end
      else
        string << line   
      end
    end
    string.rstrip!
    string.unpack("C*").each do |char|
      self.next_line if @current_row > ROWS || char == 10 # 10 == \n
      next if char == 10
      @clear = false

      GPIO.write PINS[:RS], :high
      GPIO.write PINS[:E], :high


      DATA_LINES.each do |pin|
        GPIO.write PINS[pin], char & 1
        char = char >> 1
      end

      GPIO.write PINS[:E], :low

      @current_row = @current_row+1
    end
  end

  def clear
    self.command :LCD_CLEAR
    self.position 0, 0
    @clear = true
  end

  def next_line
    @current_line = @current_line+1
    if @current_line > LINES
      self.clear
    else
      self.position 0, @current_line
    end
  end

  def clear?
    @clear
  end
end
