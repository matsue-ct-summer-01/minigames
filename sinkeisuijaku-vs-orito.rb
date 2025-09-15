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
    @timer = 0
    @message = "あなたのターン"
    @current_turn = :player # :player or :computer

    # AIのための情報
    @known_cards = {} # 覚えたカードの位置と値
    
    # ウィンドウサイズに合わせてカードサイズを調整
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
    @message_font.draw_text(@message, 10, 450, 0, 1.0, 1.0, Gosu::Color::YELLOW)
  end

  def update
    if @game_over
      return
    end

    if @flipped_cards.size == 2
      # 2枚目のカードをめくった後にメッセージを更新し、一定時間待機する
      if Gosu.milliseconds - @timer > 1500
        is_pair_found = check_pair
        @flipped_cards = []
        # ペアが見つからなかった場合のみターンを交代
        switch_turn unless is_pair_found || @game_over
      end
    elsif @current_turn == :computer
      computer_turn
    end
  end

  def check_pair
    card1, card2 = @flipped_cards
    
    if card1.value == card2.value
      card1.match!
      card2.match!
      @matched_pairs += 1
      @message = "#{@current_turn == :player ? 'あなた' : 'コンピュータ'}がペアを見つけました！"
      if @matched_pairs == 8
        @game_over = true
        @message = "ゲームクリア！"
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
    return if @game_over || @current_turn == :computer
    return unless id == Gosu::MS_LEFT

    @cards.each do |card|
      if card.contains?(mouse_x, mouse_y) && !card.is_flipped && @flipped_cards.size < 2
        card.flip!
        @flipped_cards << card
        @known_cards[card.id] = card.value
        
        # 2枚目のカードがめくられたら、即座にメッセージを更新する
        if @flipped_cards.size == 2
          @timer = Gosu.milliseconds
          card1, card2 = @flipped_cards
          @message = "めくったカード: #{card1.value} と #{card2.value}"
        end
        break
      end
    end
  end

  def computer_turn
    sleep(1.0) # AIが考える時間をシミュレート
    
    card_to_flip = []
    
    # 1. 記憶しているカードからペアを探す
    found_pair = find_known_pair
    if found_pair
      card_to_flip = found_pair
    else
      # 2. まだめくられていないカードからランダムに2枚選ぶ
      unflipped_cards = @cards.select { |c| !c.is_flipped && !c.is_matched }
      card_to_flip = unflipped_cards.sample(2)
    end
    
    # 2枚のカードをめくる
    card_to_flip.each do |card|
      card.flip!
      @flipped_cards << card
      @known_cards[card.id] = card.value
      @message = "コンピュータがめくっています..." # 1枚目をめくった時点のメッセージ
      sleep(0.5)
    end
    
    # 2枚目をめくった後にメッセージを更新
    card1, card2 = @flipped_cards
    @message = "コンピュータがめくったカード: #{card1.value} と #{card2.value}"

    @timer = Gosu.milliseconds
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