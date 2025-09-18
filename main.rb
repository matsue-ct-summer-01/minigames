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
    @dialogue_font = Gosu::Font.new(18)
    @menu_font = Gosu::Font.new(20)

    # 背景画像
    @background_intro = Gosu::Image.new('./assets/images/b_stone.jpg')
    @background_fall = Gosu::Image.new('./assets/images/b_stone.jpg')
    @background_aether = Gosu::Image.new('./assets/images/b_stone.jpg')
    @background_end = Gosu::Image.new('./assets/images/b_school.jpg')
    @background_menu = Gosu::Image.new('./assets/images/b_school.jpg')

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
      @text_sound = Gosu::Sample.new('./assets/sounds/text_beep.mp3')
    rescue
      @text_sound = nil
      puts "Warning: テキスト音ファイルが見つかりません (./assets/sounds/text_beep.mp3)"
    end

    # 審問官（デバッグ用にdialogueを「テキスト」に）
    @inquisitors = {
      tetris: {
        id: :tetris,
        x: 100,
        y: 100,
        image: Gosu::Image.new('./assets/images/inquisitor_01.png'),
        dialogue: "テキスト",
        class: TetrisGame,
        played: false
      },
      shooting: {
        id: :shooting,
        x: 540,
        y: 100,
        image: Gosu::Image.new('./assets/images/inquisitor_01.png'),
        dialogue: "ビビってんじゃねえ！シューティングで度胸見せてこい！\nブロック避けるかブッ壊しちまえ！Z押したら弾撃てっから！"
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
    @typewriter_speed = 2
    @typewriter_finished = false
    @text_lines = []

    # 最初のストーリーテキスト（デバッグ用に「テキスト」に）
    start_story_text([
      "テキスト",
      "テキスト",
      "テキスト",
      "テキスト",
      "テキスト"
    ])
  end

  def update
    case @game_state
    when STATE_PLAYING
      @current_game.update
    when STATE_MENU
      move_player
    when STATE_INTERMISSION
      # 対話状態ではプレイヤーを動かさない
    when STATE_STORY_INTRO, STATE_STORY_FALL, STATE_STORY_AETHER, STATE_END
      update_story_text
    end
  end

  def draw
    Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK)

    case @game_state
    when STATE_STORY_INTRO
      @background_intro.draw(0, 0, 0)
      draw_story_ui
    when STATE_STORY_FALL
      @background_fall.draw(0, 0, 0)
      draw_story_ui
    when STATE_STORY_AETHER
      @background_aether.draw(0, 0, 0)
      draw_story_ui
    when STATE_PLAYING
      @current_game.draw
    when STATE_MENU
      @background_menu.draw(0, 0, 0)
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
    when STATE_INTERMISSION
      @background_menu.draw(0, 0, 0)
      draw_field
      character_scale = 1.0 / 3.0
      @current_inquisitor[:image].draw(@current_inquisitor[:x] - @current_inquisitor[:image].width * character_scale / 2,
                                       @current_inquisitor[:y] - @current_inquisitor[:image].height * character_scale / 2,
                                       0, character_scale, character_scale)
      @player_image.draw(@player_x - @player_image.width * character_scale / 2, @player_y - @player_image.height * character_scale / 2, 0, character_scale, character_scale)
      draw_dialogue_box
    when STATE_END
      @background_end.draw(0, 0, 0)
      draw_story_ui
    end
    draw_scores unless @game_state == STATE_PLAYING
  end

  def button_down(id)
    case @game_state
    when STATE_STORY_INTRO
      if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
        if @typewriter_finished
          @game_state = STATE_STORY_FALL
          start_story_text([
            "テキスト",
            "テキスト",
            "テキスト",
            "テキスト",
            "テキスト"
          ])
        else
          skip_typewriter
        end
      end
    when STATE_STORY_FALL
      if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
        if @typewriter_finished
          @game_state = STATE_STORY_AETHER
          start_story_text([
            "テキスト",
            "テキスト",
            "テキスト",
            "テキスト",
            "テキスト",
            "テキスト"
          ])
        else
          skip_typewriter
        end
      end
    when STATE_STORY_AETHER
      if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
        if @typewriter_finished
          @game_state = STATE_MENU
        else
          skip_typewriter
        end
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
      if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
        close
      else
        skip_typewriter
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

  def start_story_text(text_array)
    @text_lines = text_array
    @typewriter_text = ""
    @typewriter_index = 0
    @typewriter_timer = 0
    @typewriter_finished = false
    @current_line_index = 0
    @typewriter_full_text = @text_lines.join("\n")
    puts "Starting typewriter for state: #{@game_state}"
  end

  def update_story_text
    return if @typewriter_finished

    @typewriter_timer += 1
    if @typewriter_timer >= @typewriter_speed
      if @typewriter_index < @typewriter_full_text.length
        char = @typewriter_full_text[@typewriter_index]
        @typewriter_text += char
        @typewriter_index += 1
        @typewriter_timer = 0
        @text_sound.play(0.3) if @text_sound && char != "\n"
      else
        @typewriter_finished = true
      end
    end
  end

  def skip_typewriter
    @typewriter_text = @typewriter_full_text
    @typewriter_finished = true
    puts "Skipping typewriter"
  end

  def draw_story_ui
    Gosu.draw_rect(20, height - 120, width - 40, 100, Gosu::Color.rgba(0, 0, 0, 180), 10)
    lines = @typewriter_text.split("\n")
    lines.each_with_index do |line, index|
      @dialogue_font.draw_text(line, 40, height - 110 + (index * 20), 11, 1.0, 1.0, Gosu::Color::WHITE)
    end
    @dialogue_font.draw_text("Enterで次！", 40, height - 40, 11, 1.0, 1.0, Gosu::Color::YELLOW) if @typewriter_finished
  end

  def move_player
    @player_x -= @player_speed if Gosu.button_down?(Gosu::KB_A)
    @player_x += @player_speed if Gosu.button_down?(Gosu::KB_D)
    @player_y -= @player_speed if Gosu.button_down?(Gosu::KB_W)
    @player_y += @player_speed if Gosu.button_down?(Gosu::KB_S)
  end

  def draw_field
    @menu_font.draw_text('試練の間、来たぜ！', 180, 50, 1, 1.0, 1.0, Gosu::Color::WHITE)
  end

  def draw_ui
    @menu_font.draw_text("操作: WASDで動け、ENTERで絡め", 10, height - 30, 1, 1.0, 1.0, Gosu::Color::WHITE)
  end

  def draw_dialogue_box
    Gosu.draw_rect(50, 300, 540, 100, Gosu::Color.rgba(0, 0, 0, 200), 10)
    Gosu.draw_rect(52, 302, 536, 96, Gosu::Color.rgba(50, 50, 50, 200), 10)
    dialogue_lines = wrap_text(@current_inquisitor[:dialogue], 65)
    dialogue_lines.each_with_index do |line, index|
      @dialogue_font.draw_text(line, 70, 320 + (index * 20), 11, 1.0, 1.0, Gosu::Color::WHITE)
    end
    @dialogue_font.draw_text("Enterで試練開始！", 70, 370, 11, 1.0, 1.0, Gosu::Color::YELLOW)
  end

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
    @background_end.draw(0, 0, 0)
    Gosu.draw_rect(20, height - 120, width - 40, 100, Gosu::Color.rgba(0, 0, 0, 180), 10)
    lines = @typewriter_text.split("\n")
    lines.each_with_index do |line, index|
      @dialogue_font.draw_text(line, 40, height - 110 + (index * 20), 11, 1.0, 1.0, Gosu::Color::WHITE)
    end
    @dialogue_font.draw_text("Enterで終了", 40, height - 40, 11, 1.0, 1.0, Gosu::Color::YELLOW) if @typewriter_finished
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
      start_story_text([
        "テキスト",
        "テキスト",
        "テキスト",
        "テキスト"
      ])
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