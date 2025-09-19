# Gosuライブラリを読み込みます。
# これがないと、ゲームのウィンドウや描画、入力処理などができません。
require 'gosu'

# ====================
# カードクラスの定義
# ====================
# このクラスは、ゲーム内の「カード」というオブジェクトの設計図です。
# 1枚のカードが持つべき情報（絵柄、位置など）や、動作（めくる、描画するなど）を定義します。
class Card
  # attr_readerは、外部からインスタンス変数を読み取れるようにするRubyの機能です。
  # 例えば、card.valueと書くと、@valueの値を取得できます。
  attr_reader :value, :x, :y, :size, :is_flipped, :is_matched, :id, :image

  # initializeメソッドは、新しいCardオブジェクトが作られたときに呼ばれます。
  def initialize(value, image, x, y, size, id)
    # 引数で受け取った値を、このオブジェクトのインスタンス変数に格納します。
    @value = value
    @image = image
    @x, @y = x, y
    @size = size
    # カードの初期状態は「めくられていない」「ペアになっていない」です。
    @is_flipped = false
    @is_matched = false
    @id = id
  end

  # カードの状態を「めくる」に切り替えるメソッドです。
  def flip!
    @is_flipped = !@is_flipped # !は真偽値を反転させるRubyの演算子です。
  end

  # ペアが揃ったときに呼ばれるメソッドです。
  def match!
    @is_matched = true # カードを「ペア成立」状態にします。
  end

  # カードがペアになっているか確認するメソッドです。
  def matched?
    @is_matched
  end

  # めくられたカードを裏面に戻すメソッドです。
  def flip_back!
    @is_flipped = false
  end

  # カードを画面に描画するメソッドです。
  # このコードでは、カードの裏面を単色の四角形で描画します。
  def draw(font)
    # カードがめくられているかによって、カードの色を白（めくられた状態）か灰色（裏面）に設定します。
    color = @is_flipped ? Gosu::Color::WHITE : Gosu::Color::GRAY
    # 指定した色とサイズで、カードの土台となる四角形を描画します。
    Gosu.draw_rect(@x, @y, @size, @size, color)
    # 内側に、黒い縁取りの四角形を描画します。
    Gosu.draw_rect(@x + 2, @y + 2, @size - 4, @size - 4, Gosu::Color::BLACK)

    # カードがめくられている、またはペアが成立している場合にのみ、中の画像を描画します。
    if @is_flipped || @is_matched
      # 画像がカードの枠内に収まるように、画像のサイズを計算します。
      image_scale_x = (@size - 4) / @image.width.to_f
      image_scale_y = (@size - 4) / @image.height.to_f
      # Gosuのdrawメソッドを使って、計算したサイズで画像を描画します。
      # 座標はカードの枠の内側（+2, +2）に調整しています。
      @image.draw(@x + 2, @y + 2, 0, image_scale_x, image_scale_y)
    end
  end

  # マウスの座標がこのカードの範囲内にあるか（クリックされたか）を判定するメソッドです。
  def contains?(mouse_x, mouse_y)
    mouse_x.between?(@x, @x + @size) && mouse_y.between?(@y, @y + @size)
  end
end

# ====================
# メインゲームクラスの定義
# ====================
# MemoryGameクラスは、ゲームのウィンドウや全体の進行を管理する中心的なクラスです。
class MemoryGame < Gosu::Window
  # initializeメソッドは、ゲームウィンドウが作られたときに一度だけ呼ばれます。
  def initialize
    # super(幅, 高さ)で、Gosu::Windowのコンストラクタを呼び出し、ウィンドウを作成します。
    super(640, 480)
    # ウィンドウのタイトルを設定します。
    self.caption = "神経衰弱"

    # ゲームの状態を管理するためのインスタンス変数です。
    @cards = [] # 16枚のカードオブジェクトを格納する配列
    @flipped_cards = [] # 現在めくられているカード（最大2枚）を格納する配列
    @matched_pairs = 0 # 成立したペアの数
    @game_over = false # ゲームが終了したかどうかのフラグ
    @message = "あなたのターン" # 画面下部に表示するメッセージ
    @current_turn = :player # 現在のターン（:player または :computer）
    @known_cards = {} # コンピュータが記憶したカードの絵柄と位置（id）を保存するハッシュ
    
    @player_score = 0 # プレイヤーの得点
    @player_combo_count = 0 # 連続でペアを当てた回数
    @timer = 0 # 2枚めくった後の待ち時間を制御するタイマー
    @ai_action = nil # コンピュータが次にめくるカードを記憶しておく変数
    
    @card_size = 90 # カードの一辺のサイズ
    @message_font = Gosu::Font.new(self, "Arial", 20) # メッセージを表示するためのフォント

    # 背景画像を読み込み、インスタンス変数に格納します。
    @background_image = Gosu::Image.new("C:\\ruby_lecture\\code\\minigames\\images\\haikei.jpg")

    # カード表面に使う画像のファイルパスを配列にまとめます。
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
    
    # mapメソッドを使って、各ファイルパスからGosu::Imageオブジェクトを作成し、@imagesに格納します。
    @images = image_paths.map { |path| Gosu::Image.new(path) }

    # === 効果音の追加 ===
    # Gosu::Sampleは短い効果音用です。
    @bgm = Gosu::Song.new("C:\\ruby_lecture\\code\\minigames\\sounds\\bgm.wav")
    @flip_sound = Gosu::Sample.new("C:\\ruby_lecture\\code\\minigames\\sounds\\flip.wav")
    @match_sound_1 = Gosu::Sample.new("C:\\ruby_lecture\\code\\minigames\\sounds\\match1.wav")
    @match_sound_2 = Gosu::Sample.new("C:\\ruby_lecture\\code\\minigames\\sounds\\match2.wav")
    @match_sound_3 = Gosu::Sample.new("C:\\ruby_lecture\\code\\minigames\\sounds\\match3.wav")
    
    # setup_boardメソッドを呼び出して、カードを配置します。
    setup_board
    @bgm.play(true) # trueでループ再生
  end

  # ゲームボードをセットアップするメソッドです。
  def setup_board
    # 1〜8の数字を2つずつ用意し、シャッフルします。これがカードの「値」になります。
    values = (0..7).to_a * 2
    values.shuffle!
    padding = 10 # カード間の間隔

    # カードを中央に配置するための開始座標を計算します。
    start_x = (self.width - (4 * (@card_size + padding))) / 2
    start_y = (self.height - (4 * (@card_size + padding))) / 2
    
    # 4x4のカードグリッドを作成します。
    (0..3).each do |row|
      (0..3).each do |col|
        card_id = row * 4 + col # 0から15までのユニークなIDを生成
        x = col * (@card_size + padding) + start_x
        y = row * (@card_size + padding) + start_y
        
        # シャッフルされた値から、対応する画像とカードの値を決定します。
        image_index = values.pop
        card_value = image_index + 1
        card_image = @images[image_index]
        
        # 新しいCardオブジェクトを作成し、@cards配列に追加します。
        @cards << Card.new(card_value, card_image, x, y, @card_size, card_id)
      end
    end
  end

  # カーソル（マウス）をウィンドウ内に表示するかどうかを決めます。
  def needs_cursor?
    true
  end

  # 画面に描画するすべての処理を記述します。毎フレーム呼ばれます。
  def draw
    # 背景画像を描画します。画面サイズに合わせてスケーリングします。
    scale_x = self.width.to_f / @background_image.width
    scale_y = self.height.to_f / @background_image.height
    @background_image.draw(0, 0, 0, scale_x, scale_y)
    
    # すべてのカードのdrawメソッドを呼び出して描画します。
    # このコードでは、引数としてフォント（@message_font）を渡しています。
    @cards.each { |card| card.draw(@message_font) }
    
    # スコアとメッセージを画面に描画します。
    @message_font.draw_text("現在のスコア: #{@player_score}点", 10, 10, 0, 1.0, 1.0, Gosu::Color::BLACK)
    
    # ゲーム終了時のメッセージ
    if @game_over
      win_message = "ゲーム終了！"
      @message_font.draw_text(win_message, 10, 430, 0, 1.0, 1.0, Gosu::Color::BLACK)
      @message_font.draw_text("最終スコア: #{@player_score}点", 10, 450, 0, 1.0, 1.0, Gosu::Color::BLACK)
    else
      @message_font.draw_text(@message, 10, 450, 0, 1.0, 1.0, Gosu::Color::BLACK)
    end
  end

  # ゲームの状態を更新するロジックを記述します。毎フレーム呼ばれます。
  def update
    if @game_over
      return # ゲーム終了後は何もしません。
    end

    # 2枚のカードがめくられているか確認します。
    if @flipped_cards.size == 2
      # 1.5秒待ってからペア判定を行います。
      if Gosu.milliseconds - @timer > 1500
        is_pair_found = check_pair
        @flipped_cards = []
        # ペアが見つかった場合はターンを切り替えない（もう一度めくれる）
        # ゲームが終了した場合もターンは切り替えない
        switch_turn unless is_pair_found || @game_over
      end
    # 現在のターンがコンピュータの場合、AIの処理を開始します。
    elsif @current_turn == :computer
      handle_computer_turn
    end
  end

  # コンピュータのターンを処理するメソッドです。
  def handle_computer_turn
    # 2枚めくり終えた後の処理
    if @flipped_cards.size == 2
      if Gosu.milliseconds - @timer > 1500
        is_pair_found = check_pair
        @flipped_cards = []
        # ペアが見つからなかった場合のみターンを切り替えます
        switch_turn unless is_pair_found
      end
      return
    end
    
    # 1枚目をめくる
    if @flipped_cards.empty?
      @ai_action = find_card_to_flip # めくるカードをAIに探させます
      flip_card(@ai_action[0]) # 1枚目をめくります
      #@message = "コンピュータがめくったカード: #{@flipped_cards[0].value}" # メッセージはプレイヤー用なのでコメントアウト
      @timer = Gosu::milliseconds
      return
    end

    # 2枚目をめくる
    if @flipped_cards.size == 1 && Gosu.milliseconds - @timer > 1000
      flip_card(@ai_action[1]) # 2枚目をめくります
      #@message = "コンピュータがめくったカード: #{@flipped_cards[0].value} と #{@flipped_cards[1].value}" # メッセージはプレイヤー用なのでコメントアウト
      @timer = Gosu::milliseconds
    end
  end

  # カードをめくる処理を共通化するメソッドです。
  def flip_card(card)
    card.flip! # カードを裏返します
    @flipped_cards << card # めくられたカードを配列に追加します
    @known_cards[card.id] = card.value # AIがカードの情報を記憶します
    # === カードをめくる音を再生 ===
    @flip_sound.play
  end
  
  # めくられた2枚のカードがペアかどうかを判定するメソッドです。
  def check_pair
    card1, card2 = @flipped_cards # めくられた2枚のカードを取得します
    
    if card1.value == card2.value # 絵柄が同じか確認します
      card1.match! # ペアとして確定させます
      card2.match!
      @matched_pairs += 1 # ペア数を増やします
      
      if @current_turn == :player # プレイヤーのターンだった場合
        @player_combo_count += 1 # コンボ数を増やします
        case @player_combo_count
        when 1
          @player_score += 1000
          @match_sound_1.play # 1連続目の音
        when 2
          @player_score += 2000
          @match_sound_2.play # 2連続目の音
        else
          @player_score += 3000
          @match_sound_3.play # 3連続以上の音
        end
        @message = "ペアを見つけました！ポイント獲得！"
      end
      
      if @matched_pairs == 8 # 全てのペアが揃ったらゲーム終了
        @game_over = true
      end
      return true
    else
      card1.flip_back! # ペアでなければ裏に戻します
      card2.flip_back!
      @player_combo_count = 0 # コンボをリセットします
      @message = "ちがいます..."
      return false
    end
  end

  # プレイヤーとコンピュータのターンを切り替えるメソッドです。
  def switch_turn
    @current_turn = (@current_turn == :player ? :computer : :player)
    @message = @current_turn == :player ? "あなたのターン" : "コンピュータのターン"
  end

  # マウスやキーボードのボタンが押されたときに呼ばれます。
  def button_down(id)
    if @game_over
      close if id == Gosu::KB_ESCAPE # ゲーム終了後にESCキーで終了
      return
    end
    
    # コンピュータのターン中、または2枚めくられているときはクリックを無効にします。
    return if @current_turn == :computer || @flipped_cards.size == 2
    # マウスの左クリック以外は無視します。
    return unless id == Gosu::MS_LEFT

    # 全てのカードを調べて、クリックされたカードを見つけます。
    @cards.each do |card|
      # クリックされたカードが、まだめくられていないか確認します。
      if card.contains?(mouse_x, mouse_y) && !card.is_flipped
        flip_card(card) # カードをめくります
        
        if @flipped_cards.size == 1 # 1枚目がめくられた時
            #@message = "あなたがめくったカード: #{card.value}" # メッセージは他の部分で制御しているためコメントアウト
        elsif @flipped_cards.size == 2 # 2枚目がめくられた時
            @timer = Gosu::milliseconds # タイマーを開始
            card1, card2 = @flipped_cards
            #@message = "あなたがめくったカード: #{card1.value} と #{card2.value}" # メッセージは他の部分で制御しているためコメントアウト
        end
        break # 1枚見つかったらループを抜けます
      end
    end
  end

  # コンピュータがめくるカードを探すAIのロジックです。
  def find_card_to_flip
    found_pair = find_known_pair # まずは記憶したカードにペアがないか探します
    if found_pair
      return found_pair # ペアがあればそれを返します
    else
      # なければ、まだめくられていないカードの中からランダムに2枚選びます
      unflipped_cards = @cards.select { |c| !c.is_flipped && !c.is_matched }
      return unflipped_cards.sample(2)
    end
  end

  # AIが記憶しているカードの中からペアを見つけるメソッドです。
  def find_known_pair
    # 記憶したカードのIDを2つずつ組み合わせ、同じ値を持つペアを探します。
    @known_cards.keys.combination(2).each do |id1, id2|
      if @known_cards[id1] == @known_cards[id2]
        # ペアが見つかったら、実際のカードオブジェクトを取得します。
        card1 = @cards.find { |c| c.id == id1 && !c.is_matched }
        card2 = @cards.find { |c| c.id == id2 && !c.is_matched }
        # 取得したカードが有効（既にペアになっていない）なら、そのペアを返します。
        if card1 && card2
          return [card1, card2]
        end
      end
    end
    nil # ペアが見つからなかった場合はnilを返します。
  end
end

# MemoryGameクラスの新しいインスタンスを作成し、ゲームを開始します。
MemoryGame.new.show