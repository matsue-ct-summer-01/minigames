require 'gosu'

class Card
  attr_reader :value, :x, :y, :size, :is_flipped, :is_matched, :id

  def initialize(value, x, y, size, id)
    @value = value
    @x, @y = x, y
    @size = size
    @is_flipped = false
    @is_matched = false
    @id = id
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

  def draw(font)
    color = @is_flipped ? Gosu::Color::WHITE : Gosu::Color::GRAY
    Gosu.draw_rect(@x, @y, @size, @size, color)
    Gosu.draw_rect(@x + 2, @y + 2, @size - 4, @size - 4, Gosu::Color::BLACK)

    if @is_flipped || @is_matched
      text_x = @x + (@size - font.text_width(@value.to_s)) / 2
      text_y = @y + (@size - font.height) / 2
      font.draw_text(@value.to_s, text_x, text_y, 0, 1.0, 1.0, Gosu::Color::WHITE)
    end
  end

  def contains?(mouse_x, mouse_y)
    mouse_x.between?(@x, @x + @size) && mouse_y.between?(@y, @y + @size)
  end
end

class MemoryGame < Gosu::Window
  def initialize
    super(640, 480)
    self.caption = "神経衰弱 (AI対戦)"

    @cards = []
    @flipped_cards = []
    @matched_pairs = 0
    @game_over = false
    @message = "あなたのターン"
    @current_turn = :player
    @known_cards = {}
    
    @player_score = 0
    @computer_score = 0
    @timer = 0
    @ai_action = nil
    
    @card_size = 90
    @card_font = Gosu::Font.new(self, "Arial", (@card_size * 0.8).to_i)
    @message_font = Gosu::Font.new(self, "Arial", 20)
    
    setup_board
  end

  def setup_board
    values = (1..8).to_a * 2
    values.shuffle!
    padding = 10
    
    start_x = (self.width - (4 * (@card_size + padding))) / 2
    start_y = (self.height - (4 * (@card_size + padding))) / 2
    
    (0..3).each do |row|
      (0..3).each do |col|
        card_id = row * 4 + col
        x = col * (@card_size + padding) + start_x
        y = row * (@card_size + padding) + start_y
        @cards << Card.new(values.pop, x, y, @card_size, card_id)
      end
    end
  end

  def needs_cursor?
    true
  end

  def draw
    @cards.each { |card| card.draw(@card_font) }
    
    # 常にスコアを表示する
    @message_font.draw_text("あなたのスコア: #{@player_score}", 10, 10, 0, 1.0, 1.0, Gosu::Color::YELLOW)
    @message_font.draw_text("コンピュータのスコア: #{@computer_score}", 10, 30, 0, 1.0, 1.0, Gosu::Color::YELLOW)
    
    # ゲーム終了時のメッセージ
    if @game_over
      win_message = ""
      if @player_score > @computer_score
        win_message = "あなたの勝ちです！"
      elsif @player_score < @computer_score
        win_message = "コンピュータの勝ちです！"
      else
        win_message = "引き分けです！"
      end
      
      # 画面中央に大きく表示
      @message_font.draw_text("ゲーム終了！", self.width / 2 - 50, self.height / 2 - 30, 0, 2.0, 2.0, Gosu::Color::WHITE)
      @message_font.draw_text(win_message, self.width / 2 - 50, self.height / 2, 0, 2.0, 2.0, Gosu::Color::WHITE)
      @message_font.draw_text("Escキーを押して終了", self.width / 2 - 80, self.height / 2 + 30, 0, 1.0, 1.0, Gosu::Color::YELLOW)
    else
      # 通常時のメッセージ
      @message_font.draw_text(@message, 10, 450, 0, 1.0, 1.0, Gosu::Color::YELLOW)
    end
  end

  def update
    if @game_over
      return
    end

    if @flipped_cards.size == 2
      if Gosu.milliseconds - @timer > 1500
        is_pair_found = check_pair
        @flipped_cards = []
        switch_turn unless is_pair_found || @game_over
      end
    elsif @current_turn == :computer
      handle_computer_turn
    end
  end

  def handle_computer_turn
    if @flipped_cards.empty?
      @ai_action = find_card_to_flip
      flip_card(@ai_action[0])
      @message = "コンピュータがめくったカード: #{@flipped_cards[0].value}"
      @timer = Gosu.milliseconds
      return
    end

    if @flipped_cards.size == 1 && Gosu.milliseconds - @timer > 1000
      flip_card(@ai_action[1])
      @message = "コンピュータがめくったカード: #{@flipped_cards[0].value} と #{@flipped_cards[1].value}"
      @timer = Gosu.milliseconds
    end
  end

  def flip_card(card)
    card.flip!
    @flipped_cards << card
    @known_cards[card.id] = card.value
  end
  
  def check_pair
    card1, card2 = @flipped_cards
    
    if card1.value == card2.value
      card1.match!
      card2.match!
      @matched_pairs += 1
      
      if @current_turn == :player
        @player_score += 1
      else
        @computer_score += 1
      end
      
      @message = "#{@current_turn == :player ? 'あなた' : 'コンピュータ'}がペアを見つけました！"
      if @matched_pairs == 8
        @game_over = true
      end
      return true
    else
      card1.flip_back!
      card2.flip_back!
      @message = "ちがいます..."
      return false
    end
  end

  def switch_turn
    @current_turn = (@current_turn == :player ? :computer : :player)
    @message = @current_turn == :player ? "あなたのターン" : "コンピュータのターン"
  end

  def button_down(id)
    if @game_over
      close if id == Gosu::KB_ESCAPE
      return
    end
    
    return if @current_turn == :computer || @flipped_cards.size == 2
    return unless id == Gosu::MS_LEFT

    @cards.each do |card|
      if card.contains?(mouse_x, mouse_y) && !card.is_flipped
        flip_card(card)
        
        if @flipped_cards.size == 1
            @message = "めくったカード: #{card.value}"
        elsif @flipped_cards.size == 2
            @timer = Gosu.milliseconds
            card1, card2 = @flipped_cards
            @message = "めくったカード: #{card1.value} と #{card2.value}"
        end
        break
      end
    end
  end

  def find_card_to_flip
    found_pair = find_known_pair
    if found_pair
      return found_pair
    else
      unflipped_cards = @cards.select { |c| !c.is_flipped && !c.is_matched }
      return unflipped_cards.sample(2)
    end
  end

  def find_known_pair
    @known_cards.keys.combination(2).each do |id1, id2|
      if @known_cards[id1] == @known_cards[id2]
        card1 = @cards.find { |c| c.id == id1 && !c.is_matched }
        card2 = @cards.find { |c| c.id == id2 && !c.is_matched }
        if card1 && card2
          return [card1, card2]
        end
      end
    end
    nil
  end
end

MemoryGame.new.show