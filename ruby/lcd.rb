require './gpio'

class LCD
  COLUMNS = 19 # zero indexed 
  ROWS = 1 # zero indexed

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

  def columns
    COLUMNS+1
  end

  def rows
    ROWS+1
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
    @current_row = y
    @current_column = x
  end

  def puts(input)
    self.next_row unless self.clear?

    string = ""
    input.each_line do |line|
      if line.size > COLUMNS+1
        i = 0
        last_space = -1
        line.each_char do |char|
          last_space = string.size if char == " "
          if i < COLUMNS+1
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
      self.next_row if @current_column > COLUMNS || char == 10 # 10 == \n
      next if char == 10
      @clear = false

      GPIO.write PINS[:RS], :high
      GPIO.write PINS[:E], :high


      DATA_LINES.each do |pin|
        GPIO.write PINS[pin], char & 1
        char = char >> 1
      end

      GPIO.write PINS[:E], :low

      @current_column = @current_column+1
    end
  end

  def hscroll(string, opts={})
    speed = opts.delete(:speed) || 21
    times = opts.delete(:times) || 3
    direction = opts.delete(:direction) || :ltr

    speed = 100/(speed*5)

    unless string.size > COLUMNS+1
      self.puts string
      sleep times*speed
      return
    end
    
    displayed_string = string
    (times-1).times { displayed_string = "#{displayed_string} #{string}" }

    start = (direction == :rtl) ? displayed_string.size-COLUMNS-1 : 0
    stop = (direction == :rtl) ? displayed_string.size-1 : COLUMNS
    increment = (direction == :rtl) ? -1 : 1
    while (start >= 0 && direction == :rtl) || (stop < displayed_string.size && direction != :rtl) do
      puts displayed_string[start..stop]
      clear_row(true)
      start = start+increment
      stop = stop+increment
      sleep speed
    end
  end

  def clear
    self.command :LCD_CLEAR
    self.position 0, 0
    @clear = true
  end

  def clear_row(dirty=false)
    current_row = @current_row
    self.position 0, current_row
    @clear = true
    unless dirty
      self.puts " "*(COLUMNS)
      self.position 0, current_row
      @clear = true
    end
  end

  def next_row
    @current_row = @current_row+1
    if @current_row > ROWS
      self.clear
    else
      self.position 0, @current_row
    end
  end

  def clear?
    @clear
  end
end
