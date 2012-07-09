require './gpio'

class LCD
  COLUMNS = 19 # zero indexed 
  ROWS = 1 # zero indexed

  PINS = {
    RS:   0,
    E:    1,
    D0:   17,
    D1:   18,
    D2:   21,
    D3:   22,
    D4:   23,
    D5:   24,
    D6:   25,
    D7:   4
  }
  
  DATA_LINES = [:D0, :D1, :D2, :D3, :D4, :D5, :D6, :D7]

  COMMANDS = {
    LCD_CLEAR:      0x01,
    LCD_HOME:       0x02,
    LCD_ENTRY:      0x04,
    LCD_ON_OFF:     0x08,
    LCD_CDSHIFT:    0x10,
    LCD_FUNC:       0x20,
    LCD_CGRAM:      0x40,
    LCD_DGRAM:      0x80,
    
    LCD_ENTRY_SH:   0x01,
    LCD_ENTRY_ID:   0x02,
    
    LCD_ON_OFF_B:   0x01,
    LCD_ON_OFF_C:   0x02,
    LCD_ON_OFF_D:   0x04,

    LCD_FUNC_F:     0x04,
    LCD_FUNC_N:     0x08,
    LCD_FUNC_DL:    0x10,

    LCD_CDSHIFT_RL: 0x04
  }

  def initialize(&block)
    setup
    if block_given?
      instance_eval &block
      cleanup
    end
  rescue Exception => e
    cleanup
    raise
  end

  def setup
    PINS.values.each do |pin|
      GPIO.output pin
      GPIO.write pin, :low
    end
   
    3.times do
      command COMMANDS[:LCD_FUNC] | COMMANDS[:LCD_FUNC_DL] | COMMANDS[:LCD_FUNC_N]
    end

    command COMMANDS[:LCD_ON_OFF] | COMMANDS[:LCD_ON_OFF_D]
    command COMMANDS[:LCD_ENTRY] | COMMANDS[:LCD_ENTRY_ID]
    command COMMANDS[:LCD_CDSHIFT] | COMMANDS[:LCD_CDSHIFT_RL]
    clear
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
    write_byte(command)
  end

  def position(x, y)
    command_byte = COMMANDS[:LCD_DGRAM]
    command_byte = command_byte | 0x40 if y == 1
    command command_byte+x
    @current_row = y
    @current_column = x
  end

  def puts(string)
    next_row unless clear?

    word_wrap(string).unpack("C*").each do |char|
      next_row if @current_column > COLUMNS || char == 10 # 10 == \n
      next if char == 10
      @clear = false

      GPIO.write PINS[:RS], :high
      write_byte(char)

      @current_column += 1
    end
  end

  def hscroll(string, opts={})
    speed = opts.delete(:speed) || 21
    times = opts.delete(:times) || 3
    direction = opts.delete(:direction) || :ltr

    speed = 100/(speed*5)

    unless string.size > COLUMNS+1
      puts string
      sleep times*speed
      return
    end
    
    string = ((string+" ")*times)[0..-2]
    
    if direction == :rtl
      start = string.size-COLUMNS-1
      stop = displayed_string.size-1
      increment = -1
    else
      start = 0
      stop = COLUMNS
      increment = 1
    end
    
    while (start >= 0 && direction == :rtl) ||
          (stop < string.size && direction != :rtl) do
      puts string[start..stop]
      clear_row(true)
      start += increment
      stop += increment
      sleep speed
    end
  end

  def clear
    command :LCD_CLEAR
    position 0, 0
    @clear = true
  end

  def clear_row(dirty=false)
    current_row = @current_row
    position 0, current_row
    @clear = true
    unless dirty
      puts " "*(COLUMNS)
      position 0, current_row
      @clear = true
    end
  end

  def next_row
    @current_row += 1
    if @current_row > ROWS
      clear
    else
      position 0, @current_row
    end
  end

  def clear?
    @clear
  end

  def columns
    COLUMNS+1
  end

  def rows
    ROWS+1
  end
  
  private
  
  def write_byte(byte)
    GPIO.write PINS[:E], :high
    
    DATA_LINES.each do |pin|
      GPIO.write PINS[pin], byte & 1
      byte = byte >> 1
    end
      
    GPIO.write PINS[:E], :low
  end
  
  def word_wrap(input)
    string = ""
    input.each_line do |line|
      if line.size > COLUMNS+1
        i = 0
        last_space = -1
        line.each_char do |char|
          last_space = string.size if char == " "
          if i < COLUMNS+1
            string << char
            i += 1
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
    
    return string.rstrip
  end
end
