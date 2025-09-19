# frozen_string_literal: true
require 'gosu'

class Card
  attr_reader :value, :x, :y, :size, :is_flipped, :is_matched, :id, :image

  def initialize(value, image, x, y, size, id)
    @value = value
    @image = image
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
      # 画像がカードサイズに合うようにスケーリング
      image_scale_x = (@size - 4) / @image.width.to_f
      image_scale_y = (@size - 4) / @image.height.to_f
      @image.draw(@x + 2, @y + 2, 0, image_scale_x, image_scale_y)
    end
  end

  def contains?(mouse_x, mouse_y)
    mouse_x.between?(@x, @x + @size) && mouse_y.between?(@y, @y + @size)
  end
end


class MemoryGame


  def self.window_size
    { width: 450, height: 480 }
  end
  def initialize(window)
    @window = window
    #@window.caption = "神経衰弱"

   
    @cards = []
    @flipped_cards = []
    @matched_pairs = 0
    @game_over = false
    @message = "あなたのターン"
    @current_turn = :player
    @known_cards = {}
    
    @player_score = 0
    @player_combo_count = 0
    @timer = 0
    @ai_action = nil
    
    @card_size = 90
    @message_font = Gosu::Font.new(@window, "Arial", 20)
    
    # 背景画像を読み込む
    @background_image = Gosu::Image.new("C:\\ruby_lecture\\code\\minigames\\images\\haikei.jpg")

    # 画像ファイルのパスを指定
    image_paths = [
      "C:\\ruby_lecture\\code\\minigames\\images\\bone.png",
      "C:\\ruby_lecture\\code\\minigames\\images\\chusha.png",
      "C:\\ruby_lecture\\code\\minigames\\images\\normal.png",
      "C:\\ruby_lecture\\code\\minigames\\images\\hurisubi-.png",
      "C:\\ruby_lecture\\code\\minigames\\images\\kanshoku.png",
      "C:\\ruby_lecture\\code\\minigames\\images\\meal.png",
      "C:\\ruby_lecture\\code\\minigames\\images\\ote.png",
      "C:\\ruby_lecture\\code\\minigames\\images\\bigball.png"
    ]
    
    @images = image_paths.map { |path| Gosu::Image.new(path) }

    # === 効果音の追加 ===
    @bgm = Gosu::Song.new("C:\\ruby_lecture\\code\\minigames\\sounds\\bgm.wav")
    @flip_sound = Gosu::Sample.new("C:\\ruby_lecture\\code\\minigames\\sounds\\flip.wav")
    @match_sound_1 = Gosu::Sample.new("C:\\ruby_lecture\\code\\minigames\\sounds\\match1.wav")
    @match_sound_2 = Gosu::Sample.new("C:\\ruby_lecture\\code\\minigames\\sounds\\match2.wav")
    @match_sound_3 = Gosu::Sample.new("C:\\ruby_lecture\\code\\minigames\\sounds\\match3.wav")
    
    setup_board
    @bgm.play(true) # trueでループ再生
  end

  def setup_board
    # 各画像に0-7の値を割り当てる
    values = (0..7).to_a * 2
    values.shuffle!
    padding = 10
    
    start_x = (@window.width - (4 * (@card_size + padding))) / 2
    start_y = (@window.height - (4 * (@card_size + padding))) / 2
    
    (0..3).each do |row|
      (0..3).each do |col|
        card_id = row * 4 + col
        x = col * (@card_size + padding) + start_x
        y = row * (@card_size + padding) + start_y
        
        # 配列から画像のインデックスを取得
        image_index = values.pop
        
        # カードのvalueは1-8、画像はインデックスで紐づける
        card_value = image_index + 1
        card_image = @images[image_index]
        
        @cards << Card.new(card_value, card_image, x, y, @card_size, card_id)
      end
    end
  end

  def needs_cursor?
    true
  end

  def draw
    # 背景画像を描画
    scale_x = @window.width.to_f / @background_image.width
    scale_y = @window.height.to_f / @background_image.height
    @background_image.draw(0, 0, 0, scale_x, scale_y)
    
    # カードやスコアなどの描画はここから
    @cards.each { |card| card.draw(@message_font) }
    
    @message_font.draw_text("現在のスコア: #{@player_score}点", 10, 10, 0, 1.0, 1.0, Gosu::Color::YELLOW)
    
    if @game_over
      win_message = "ゲーム終了！"
      @message_font.draw_text(win_message, 10, 430, 0, 1.0, 1.0, Gosu::Color::YELLOW)
      @message_font.draw_text("最終スコア: #{@player_score}点", 10, 450, 0, 1.0, 1.0, Gosu::Color::YELLOW)
      sleep(3)
      @bgm.stop
      @window.on_game_over(@player_score) # 親のメソッドを呼び出す
    else
      @message_font.draw_text(@message, 10, 450, 0, 1.0, 1.0, Gosu::Color::YELLOW)
    end
  end

  def update
    if @game_over
      return
    end

    if @flipped_cards.size == 2
      # 2枚めくられたら1.5秒待機してペア判定
      if Gosu.milliseconds - @timer > 1500
        is_pair_found = check_pair
        @flipped_cards = []
        # ペアが見つかった場合はターンを切り替えない
        switch_turn unless is_pair_found || @game_over
      end
    elsif @current_turn == :computer
      handle_computer_turn
    end
  end

  def handle_computer_turn
    # 2枚めくり終えた後の処理
    if @flipped_cards.size == 2
      if Gosu.milliseconds - @timer > 1500
        is_pair_found = check_pair
        @flipped_cards = []
        # ペアが見つからなかった場合のみターンを切り替える
        switch_turn unless is_pair_found
      end
      return
    end
    
    # 1枚目をめくる
    if @flipped_cards.empty?
      @ai_action = find_card_to_flip
      flip_card(@ai_action[0])
      @timer = Gosu::milliseconds
      return
    end

    # 2枚目をめくる
    if @flipped_cards.size == 1 && Gosu.milliseconds - @timer > 1000
      flip_card(@ai_action[1])
      @timer = Gosu::milliseconds
    end
  end

  def flip_card(card)
    card.flip!
    @flipped_cards << card
    @known_cards[card.id] = card.value
    # === カードをめくる音を再生 ===
    @flip_sound.play
  end
  
  def check_pair
    card1, card2 = @flipped_cards
    
    if card1.value == card2.value
      card1.match!
      card2.match!
      @matched_pairs += 1
      
      if @current_turn == :player
        @player_combo_count += 1
        case @player_combo_count
        when 1
          @player_score += 1000
          # === 1連続目のペア成立音 ===
          @match_sound_1.play
        when 2
          @player_score += 2000
          # === 2連続目のペア成立音 ===
          @match_sound_2.play
        else
          @player_score += 3000
          # === 3連続以上のペア成立音 ===
          @match_sound_3.play
        end
        @message = "ペアを見つけました！ポイント獲得！"
      end
      
      if @matched_pairs == 8
        @game_over = true
      end
      return true
    else
      card1.flip_back!
      card2.flip_back!
      @player_combo_count = 0
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
      @window.close if id == Gosu::KB_ESCAPE
      return
    end
    
    return if @current_turn == :computer || @flipped_cards.size == 2
    return unless id == Gosu::MS_LEFT

    @cards.each do |card|
      # mouse_xとmouse_yを@windowから取得するように修正
      if card.contains?(@window.mouse_x, @window.mouse_y) && !card.is_flipped
        flip_card(card)
        
        if @flipped_cards.size == 1
        elsif @flipped_cards.size == 2
            @timer = Gosu::milliseconds
            card1, card2 = @flipped_cards
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
