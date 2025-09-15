# frozen_string_literal: true
require 'gosu'
require_relative 'games/tetris/main'
require_relative 'games/shooting/main'

class GameManager < Gosu::Window
  STATE_STORY_INTRO = :story_intro
  STATE_STORY_FALL = :story_fall
  STATE_STORY_AETHER = :story_aether
  STATE_MENU = :menu
  STATE_PLAYING = :playing
  STATE_INTERMISSION = :intermission
  STATE_END = :end

  attr_reader :current_game, :total_score

  def initialize
    super 640, 480
    self.caption = 'エーテル界の試練'

    @game_state = STATE_STORY_INTRO
    @font = Gosu::Font.new(30)
    @menu_font = Gosu::Font.new(20)
    @dialogue_font = Gosu::Font.new(18) # フォントサイズを小さくして見切れを防ぐ

    # プレイヤーキャラクター
    @player_image = Gosu::Image.new('./assets/images/player.png')
    @player_x = 320
    @player_y = 400
    @player_speed = 6

    # スコア管理
    @game_scores = { tetris: 0, shooting: 0 }
    @total_score = 0
    @last_game_score = 0

    # 音効果
    begin
      @text_sound = Gosu::Sample.new('./assets/sounds/text_beep.mp3')  # テキスト音
    rescue
      @text_sound = nil # 音ファイルがない場合はnil
      puts "Warning: テキスト音ファイルが見つかりません (./assets/sounds/text_beep.ogg)"
    end

    # 審問官（絵文字を削除してシンプルに）
    @inquisitors = {
      tetris: {
        id: :tetris,
        x: 100,
        y: 100,
        image: Gosu::Image.new('./assets/images/inquisitor_01.png'),
        dialogue: "よお、頭ん中ぐちゃぐちゃか？テトリスで片付けスキル見せてみろよ！",
        class: TetrisGame,
        played: false
      },
      shooting: {
        id: :shooting,
        x: 540,
        y: 100,
        image: Gosu::Image.new('./assets/images/inquisitor_01.png'),
        dialogue: "ビビってんじゃねえ！シューティングで度胸見せてこい！",
        class: ShootingGame,
        played: false
      }
    }
    @current_inquisitor = nil

    # タイプライター効果用の変数
    @typewriter_text = ""
    @typewriter_full_text = ""
    @typewriter_index = 0
    @typewriter_timer = 0
    @typewriter_speed = 6 # 速度を遅く（数値を大きく）
    @typewriter_finished = false
    @typewriter_lines = []  # 複数行対応
    @current_line = 0
    @line_y_offset = 0

    # 最初のストーリーテキスト（絵文字削除）
    start_typewriter("またいつもの高専。マジで毎日同じループ。\n昔はゲーム作って世界変えるとか思ってたのに…\n今じゃコード書くのもダルいわ。")
  end

  def update
    case @game_state
    when STATE_PLAYING
      @current_game.update
    when STATE_MENU
      move_player
    when STATE_INTERMISSION
      # 対話状態ではプレイヤーを動かさない
    when STATE_STORY_INTRO, STATE_STORY_FALL, STATE_STORY_AETHER
      update_typewriter
    end
  end

  def draw
    Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK)

    case @game_state
    when STATE_STORY_INTRO
      draw_typewriter_text(50, 200)
      if @typewriter_finished
        @dialogue_font.draw_text("Enterで次へ…", 50, 380, 1, 1.0, 1.0, Gosu::Color::YELLOW)
      end
    when STATE_STORY_FALL
      draw_typewriter_text(50, 200)
      if @typewriter_finished
        @dialogue_font.draw_text("Enterで次へ…", 50, 380, 1, 1.0, 1.0, Gosu::Color::YELLOW)
      end
    when STATE_STORY_AETHER
      draw_typewriter_text(50, 180)  # 長いテキストなので開始位置を上に
      if @typewriter_finished
        @dialogue_font.draw_text("Enterで試練開始！", 50, 400, 1, 1.0, 1.0, Gosu::Color::YELLOW)
      end
    when STATE_PLAYING
      @current_game.draw
    when STATE_MENU, STATE_INTERMISSION
      draw_field
      character_scale = 1.0 / 3.0
      @inquisitors.values.each do |inquisitor|
        inquisitor[:image].draw(inquisitor[:x] - inquisitor[:image].width * character_scale / 2,
                                inquisitor[:y] - inquisitor[:image].height * character_scale / 2,
                                0, character_scale, character_scale)
      end
      player_image_width = @player_image.width * character_scale
      player_image_height = @player_image.height * character_scale
      @player_image.draw(@player_x - player_image_width / 2, @player_y - player_image_height / 2, 0, character_scale, character_scale)
      draw_ui
      draw_dialogue_box if @game_state == STATE_INTERMISSION
    when STATE_END
      draw_end_screen
    end
    draw_scores unless @game_state == STATE_PLAYING
  end

  def button_down(id)
    case @game_state
    when STATE_STORY_INTRO
      if (id == Gosu::KB_RETURN || id == Gosu::KB_ENTER) && @typewriter_finished
        @game_state = STATE_STORY_FALL
        start_typewriter("（マジで退屈すぎだろ、こいつ…）\n突然、頭に響く声。\n『だったら、俺が最高のエンタメ用意してやるよ！』\n…って、え、空からなんか光ってくるんだけど！？")
      end
    when STATE_STORY_FALL
      if (id == Gosu::KB_RETURN || id == Gosu::KB_ENTER) && @typewriter_finished
        @game_state = STATE_STORY_AETHER
        start_typewriter("目が覚めると、めっちゃキラキラした変な空間。\n目の前にドヤ顔のヤツが。\n「よう、俺は審問者ってんだ。お前の魂、ダサすぎ。\nこれから4つの試練で輝き取り戻せよ。\nクリアしたら現実戻してやる。\n失敗？…まあ、虚無で一生過ごすだけ。」")
      end
    when STATE_STORY_AETHER
      if (id == Gosu::KB_RETURN || id == Gosu::KB_ENTER) && @typewriter_finished
        @game_state = STATE_MENU
      end
    when STATE_PLAYING
      if id == Gosu::KB_ESCAPE
        @game_state = STATE_MENU
        @current_game = nil
        self.width, self.height = 640, 480
      else
        @current_game.button_down(id)
      end
    when STATE_MENU
      check_interaction(id)
    when STATE_INTERMISSION
      if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
        start_game
      end
    when STATE_END
      if id == Gosu::KB_ESCAPE
        close
      end
    end
  end

  def on_game_over(score)
    game_key = @current_inquisitor[:id]
    @game_scores[game_key] = score
    @last_game_score = score
    @total_score += score
    switch_to_next_inquisitor
  end

  private

  def start_typewriter(text)
    @typewriter_full_text = text
    @typewriter_text = ""
    @typewriter_index = 0
    @typewriter_timer = 0
    @typewriter_finished = false
    @typewriter_lines = text.split("\n")  # 行に分割
    @current_line = 0
    @line_y_offset = 0
  end

  def update_typewriter
    return if @typewriter_finished
    
    @typewriter_timer += 1
    if @typewriter_timer >= @typewriter_speed && @typewriter_index < @typewriter_full_text.length
      char = @typewriter_full_text[@typewriter_index]
      @typewriter_text += char
      @typewriter_index += 1
      @typewriter_timer = 0
      
      # 文字が表示されるたびに音を鳴らす（改行文字以外）
      if @text_sound && char != "\n" && char.strip.length > 0
        @text_sound.play(0.3)  # 音量30%で再生
      end
      
      @typewriter_finished = true if @typewriter_index >= @typewriter_full_text.length
    end
  end

  def draw_typewriter_text(x, y)
    lines = @typewriter_text.split("\n")
    lines.each_with_index do |line, index|
      @dialogue_font.draw_text(line, x, y + (index * 25), 1, 1.0, 1.0, Gosu::Color::WHITE)
    end
  end

  def move_player
    @player_x -= @player_speed if Gosu.button_down?(Gosu::KB_A)
    @player_x += @player_speed if Gosu.button_down?(Gosu::KB_D)
    @player_y -= @player_speed if Gosu.button_down?(Gosu::KB_W)
    @player_y += @player_speed if Gosu.button_down?(Gosu::KB_S)
  end

  def draw_field
    @menu_font.draw_text('試練の間へようこそ！', 180, 50, 1, 1.0, 1.0, Gosu::Color::WHITE)
  end

  def draw_ui
    @menu_font.draw_text("操作: WASDで移動, ENTERで話しかける", 10, height - 30, 1, 1.0, 1.0, Gosu::Color::WHITE)
  end

  def draw_dialogue_box
    Gosu.draw_rect(50, 300, 540, 100, Gosu::Color.rgba(0, 0, 0, 200), 10)
    Gosu.draw_rect(52, 302, 536, 96, Gosu::Color.rgba(50, 50, 50, 200), 10)
    
    # 長いテキストを複数行に分割して表示
    dialogue_lines = wrap_text(@current_inquisitor[:dialogue], 65) # 65文字で改行
    dialogue_lines.each_with_index do |line, index|
      @dialogue_font.draw_text(line, 70, 320 + (index * 20), 11, 1.0, 1.0, Gosu::Color::WHITE)
    end
    
    @dialogue_font.draw_text("Enterで試練スタート！", 70, 370, 11, 1.0, 1.0, Gosu::Color::YELLOW)
  end

  # テキストを指定した文字数で折り返す
  def wrap_text(text, width)
    words = text.split('')
    lines = []
    current_line = ""
    
    words.each do |char|
      if current_line.length + 1 <= width
        current_line += char
      else
        lines << current_line
        current_line = char
      end
    end
    lines << current_line if current_line.length > 0
    lines
  end

  def draw_scores
    @dialogue_font.draw_text("合計スコア: #{@total_score}", 10, 10, 1, 1.0, 1.0, Gosu::Color::YELLOW)
    @dialogue_font.draw_text("前回スコア: #{@last_game_score}", 10, 30, 1, 1.0, 1.0, Gosu::Color::YELLOW) if @last_game_score > 0
  end

  def draw_end_screen
    Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK)
    @font.draw_text("やるじゃん！全試練クリア！", 50, 100, 1, 1.0, 1.0, Gosu::Color::WHITE)
    @font.draw_text("約束通り、現実に戻してやるよ。", 50, 130, 1, 1.0, 1.0, Gosu::Color::WHITE)
    
    end_message = "でもさ、退屈な毎日はもう終わりだろ？\n自分の夢、追いかけてみ。絶対バズるから！"
    end_lines = end_message.split("\n")
    end_lines.each_with_index do |line, index|
      @font.draw_text(line, 50, 160 + (index * 35), 1, 1.0, 1.0, Gosu::Color::WHITE)
    end
    
    @font.draw_text("合計スコア: #{@total_score}", 150, 250, 1, 1.0, 1.0, Gosu::Color::WHITE)
    @font.draw_text("ESCで終了", 150, 350, 1, 1.0, 1.0, Gosu::Color::WHITE)
  end

  def check_interaction(id)
    if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
      closest_inquisitor = find_closest_inquisitor
      if closest_inquisitor
        @current_inquisitor = closest_inquisitor
        @game_state = STATE_INTERMISSION
      end
    end
  end

  def find_closest_inquisitor
    closest = nil
    min_distance = 50
    @inquisitors.values.each do |inquisitor|
      distance = Gosu.distance(@player_x, @player_y, inquisitor[:x], inquisitor[:y])
      closest = inquisitor if distance < min_distance
    end
    closest
  end

  def start_game
    @game_state = STATE_PLAYING
    game_class = @current_inquisitor[:class]
    size = game_class.window_size
    self.width, self.height = size[:width], size[:height]
    @current_game = game_class.new(self)
  end

  def switch_to_next_inquisitor
    @inquisitors[@current_inquisitor[:id]][:played] = true
    unplayed_inquisitors = @inquisitors.values.select { |i| !i[:played] }
    if unplayed_inquisitors.empty?
      @game_state = STATE_END
    else
      @game_state = STATE_MENU
      self.width, self.height = 640, 480
    end
    @current_inquisitor = nil
    @current_game = nil
  end
end

if __FILE__ == $0
  GameManager.new.show
end