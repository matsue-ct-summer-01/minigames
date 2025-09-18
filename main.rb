# frozen_string_literal: true
require 'gosu'
require_relative 'games/tetris/main'
require_relative 'games/shooting/main'
require_relative 'core/dialogue'
require_relative 'core/sound_manager'

class GameManager < Gosu::Window
  # ゲームの状態
  STATE_STORY = :story
  STATE_PLAYING = :playing
  STATE_END = :end

  # 定数
  GAME_WIDTH = 640
  GAME_HEIGHT = 480
  CHARACTER_SCALE = 1.0 / 3.0

  # フォントサイズ
  FONT_SIZE_DIALOGUE = 18

  # 画面上の位置
  PLAYER_IMAGE_X = GAME_WIDTH / 2
  PLAYER_IMAGE_Y = GAME_HEIGHT / 2 + 160
  INQUISITOR_IMAGE_X = GAME_WIDTH / 2
  INQUISITOR_IMAGE_Y = GAME_HEIGHT / 2 - 100

  attr_reader :current_game, :total_score

  def initialize
    super GAME_WIDTH, GAME_HEIGHT
    self.caption = '試練'

    @game_state = STATE_STORY
    @dialogue_font = Gosu::Font.new(FONT_SIZE_DIALOGUE)
    @title_font = Gosu::Font.new(FONT_SIZE_DIALOGUE)
    @sound_manager = SoundManager.new
    @background_school = Gosu::Image.new('./assets/images/b_school.jpg')
    @background_stone = Gosu::Image.new('./assets/images/b_stone.jpg')
    @player_image = Gosu::Image.new('./assets/images/player.png')
    @inquisitor_image = Gosu::Image.new('./assets/images/inquisitor_01.png')

    @game_scores = { tetris: 0, shooting: 0 }
    @total_score = 0
    @last_game_score = 0
    
    # BGMファイルを読み込み、再生します
    # @bgm = Gosu::Song.new('./assets/sounds/bgm_loop.wav')
    # @bgm.play(true)

    # 統一されたストーリーデータ（イベントの進行順）
    @story_data = [
      # オープニングストーリー
      { type: :sound, data: "shooting_shot" }, # 効果音をtext指定に変更
      { type: :dialogue, content: "暗い場所で意識を取り戻す。\n\n冷たい石の床、頭上の巨大なアーチ、響くのはかすかな足音。", background: @background_stone, speaker_image: @player_image, text_speed: 2, sound_content: "text_beep", await_input: true },
      { type: :dialogue, content: "ここが...試練の間、か。", background: @background_stone, speaker_image: @player_image, text_speed: 2, sound_content: "text_beep", await_input: true },
      # テトリスゲームの開始
      { type: :dialogue, content: "集中しろ。テトリスで機転を試す。\nブロックを完璧に並べてみろ。さあ、どうする？", background: @background_school, speaker_image: @inquisitor_image, text_speed: 1, sound_content: "text_beep", await_input: true },
      { type: :game, class: TetrisGame },
      # テトリスゲーム後の効果音とストーリー
      
      { type: :dialogue, content: "テトリスの試練を突破した。合計スコアは#{@total_score}点だ。", background: @background_stone, speaker_image: @player_image, text_speed: 2, sound_content: "text_beep", await_input: true },
      { type: :dialogue, content: "ビビってんじゃねえ！シューティングで度胸見せてこい！\nブロック避けるかブッ壊しちまえ！Z押したら弾撃てっから！", background: @background_school, speaker_image: @inquisitor_image, text_speed: 1, sound_content: "text_beep", await_input: true },
      { type: :game, class: ShootingGame },
      # エンディング
      { type: :dialogue, content: "シューティングの試練もクリアした。\nこれで終わりだ。", background: @background_stone, speaker_image: @player_image, text_speed: 2, sound_content: "text_beep", await_input: true }
    ]
    @current_event_index = 0

    run_next_event
  end

  def update
    return if @game_state == STATE_END
    @current_event.update
  end

  def draw
    Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK)
    if @game_state == STATE_STORY || @game_state == STATE_PLAYING
      @current_event.draw
    elsif @game_state == STATE_END
      @background_school.draw(0, 0, 0)
      draw_end_screen
    end
    draw_scores unless @game_state == STATE_PLAYING
  end

  def button_down(id)
    case @game_state
    when STATE_STORY
      if @current_event.button_down(id)
        run_next_event
      end
    when STATE_PLAYING
      @current_event.button_down(id)
    when STATE_END
      if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
        close
      end
    end
  end

  def on_game_over(score)
    @last_game_score = score
    @total_score += score
    run_next_event
  end

  private
  
  def run_next_event
    if @current_event_index >= @story_data.length
      @game_state = STATE_END
      self.width, self.height = GAME_WIDTH, GAME_HEIGHT
      # @bgm.stop
      return
    end

    event = @story_data[@current_event_index]
    
    case event[:type]
    when :dialogue
      self.width, self.height = GAME_WIDTH, GAME_HEIGHT
      @current_event = Dialogue.new(
        content: event[:content],
        background: event[:background],
        speaker_image: event[:speaker_image],
        dialogue_font: @dialogue_font,
        sound_manager: @sound_manager,
        text_speed: event[:text_speed],
        sound_content: event[:sound_content],
        await_input: event[:await_input],
        window: self
      )
      @game_state = STATE_STORY
      @current_event_index += 1
    when :game
      game_class = event[:class]
      size = game_class.window_size
      self.width, self.height = size[:width], size[:height]
      @current_event = game_class.new(self)
      @game_state = STATE_PLAYING
      @current_event_index += 1
    when :sound
      @sound_manager.play(event[:data])
      @current_event_index += 1
      run_next_event
    end
  end

  def draw_scores
    @dialogue_font.draw_text("合計スコア: #{@total_score}", 10, 10, 1, 1.0, 1.0, Gosu::Color::YELLOW)
    @dialogue_font.draw_text("前回スコア: #{@last_game_score}", 10, 30, 1, 1.0, 1.0, Gosu::Color::YELLOW) if @last_game_score > 0
  end

  def draw_end_screen
    Gosu.draw_rect(20, GAME_HEIGHT - 120, GAME_WIDTH - 40, 100, Gosu::Color.rgba(0, 0, 0, 180), 10)
    @dialogue_font.draw_text("すべての試練を突破した！", 40, GAME_HEIGHT - 110, 11, 1.0, 1.0, Gosu::Color::WHITE)
    @dialogue_font.draw_text("あなたの合計スコア: #{@total_score}", 40, GAME_HEIGHT - 90, 11, 1.0, 1.0, Gosu::Color::WHITE)
    @dialogue_font.draw_text("Enterで終了", 40, GAME_HEIGHT - 40, 11, 1.0, 1.0, Gosu::Color::YELLOW)
  end
end

if __FILE__ == $0
  GameManager.new.show
end