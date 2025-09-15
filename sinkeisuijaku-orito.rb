require 'gosu'

class Card
  attr_reader :value, :x, :y, :size, :is_flipped

  def initialize(value, x, y, size)
    @value = value
    @x, @y = x, y
    @size = size
    @is_flipped = false
    @is_matched = false
    @font = Gosu::Font.new(self, Gosu::default_font_name, size * 0.8)
  end

  def flip!
    @is_flipped = !@is_flipped
  end

  def match!
    @is_matched = true
  end

  def matched?
    @is_matched
  end

  def flip_back!
    @is_flipped = false
  end

  def draw
    color = @is_flipped ? Gosu::Color::WHITE : Gosu::Color::GRAY
    Gosu.draw_rect(@x, @y, @size, @size, color)
    Gosu.draw_rect(@x + 2, @y + 2, @size - 4, @size - 4, Gosu::Color::BLACK)

    if @is_flipped || @is_matched
      text_x = @x + (@size - @font.text_width(@value.to_s)) / 2
      text_y = @y + (@size - @font.height) / 2
      @font.draw_text(@value.to_s, text_x, text_y, 0, 1.0, 1.0, Gosu::Color::WHITE)
    end
  end

  def contains?(mouse_x, mouse_y)
    mouse_x.between?(@x, @x + @size) && mouse_y.between?(@y, @y + @size)
  end
end

class MemoryGame < Gosu::Window
  def initialize
    super(600, 600)
    self.caption = "神経衰弱"
    @cards = []
    @flipped_cards = []
    @matched_pairs = 0
    @game_over = false
    @timer = 0
    @message = "カードをクリックしてね"
    @font = Gosu::Font.new(20)
    setup_board
  end

  def setup_board
    values = (1..8).to_a * 2
    values.shuffle!
    card_size = 120
    padding = 10
    (0..3).each do |row|
      (0..3).each do |col|
        x = col * (card_size + padding) + padding * 3
        y = row * (card_size + padding) + padding * 3
        @cards << Card.new(values.pop, x, y, card_size)
      end
    end
  end

  def needs_cursor?
    true
  end

  def draw
    @cards.each(&:draw)
    @font.draw_text(@message, 10, 560, 0, 1.0, 1.0, Gosu::Color::YELLOW)
  end

  def update
    if @flipped_cards.size == 2
      if Gosu.milliseconds - @timer > 1000
        card1, card2 = @flipped_cards
        if card1.value == card2.value
          card1.match!
          card2.match!
          @matched_pairs += 1
          @message = "ペアが見つかりました！"
          if @matched_pairs == 8
            @game_over = true
            @message = "ゲームクリア！"
          end
        else
          card1.flip_back!
          card2.flip_back!
          @message = "ちがいます..."
        end
        @flipped_cards = []
      end
    end
  end

  def button_down(id)
    return if @game_over
    return unless id == Gosu::MS_LEFT

    @cards.each do |card|
      if card.contains?(mouse_x, mouse_y) && !card.is_flipped && @flipped_cards.size < 2
        card.flip!
        @flipped_cards << card
        @message = "めくっています..."
        if @flipped_cards.size == 2
          @timer = Gosu.milliseconds
        end
        break
      end
    end
  end
end

MemoryGame.new.show