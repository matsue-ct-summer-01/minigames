# frozen_string_literal: true
require 'gosu'
require_relative 'games/tetris/main'
require_relative 'games/shooting/main'
require_relative 'core/dialogue'
require_relative 'core/sound_manager'
require_relative './soccer-pk-animation2'
require_relative './sinkeisuijaku_orito'

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
    @yomiage_speed =4
    # 統一されたストーリーデータ（イベントの進行順）
    @story_data = [
      # オープニングストーリー
      { type: :sound, data: "nonki" },#使用上ループできません。
      { type: :dialogue, content: "はあ、、、\n今日もまた学校がある。", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :dialogue, content: "外は九月のくせに暑いままだし、授業もいまいちやる気が出ないなあ", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :dialogue, content: "もういっそのこと今日は帰ろうかな\n家でゆっくりアニメでも見よ......", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :sound, data: "long_keen" },
      { type: :dialogue, content: "(おい、そこのお前....)", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :dialogue, content: "うわ!急に頭から謎の声が!!", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :sound, data: "keen" },
      { type: :dialogue, content: "(私は理想の高専生である)", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :sound, data: "long_keen" },
      { type: :dialogue, content: "(お前は怠惰すぎる、高専の恥だ)\n(そんなお前に4つの試練を用意した。これらを乗り越えることでお前は成長できるだろう)", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :dialogue, content: "まじか！", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :sound, data: "keen" },
     
      { type: :game, class: TetrisGame, name: :tetris },

      { type: :dialogue, content: "（まずは知の試練だ。なお、4つの試練は完全オリジナルだ。)", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :dialogue, content: ".....す、すごい!知力が上がるのを感じる!", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      
      
      { type: :sound, data: "keen" },
      { type: :dialogue, content: "（次は力の試練だ。)", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :game, class: ShootingGame, name: :shooting },
      { type: :dialogue, content: ".....す、すごい!知力が上がるのを感じる!", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      
      
      { type: :sound, data: "keen" },
      { type: :dialogue, content: "（次は知の試練だ。)", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :game, class: MemoryGame, name: :memory },
      { type: :dialogue, content: ".....す、すごい!さらに知力が上がるのを感じる!", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
       
      { type: :sound, data: "keen" },
      { type: :dialogue, content: "（最後に運の試練だ。)", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      
      
      { type: :game, class: PKGame, name: :pk },

      { type: :dialogue, content: ".....す、すごい!運気が上がるのを感じる!", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },


      { type: :sound, data: "keen" },
      { type: :dialogue, content: "（四つの試験をよく乗り越えた。)", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :sound, data: "long_keen" },
      { type: :dialogue, content: "（これでお前は赤点を回避し、課外活動に積極的になり、\n卒研で担当教員をこまらせることはなくなるだろう。)", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :dialogue, content: "よし!高専生活頑張るぞ!!!", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :dialogue, content: "-FIN-", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      { type: :sound, data: "happy_end" },#使用上ループできません。

      { type: :dialogue, content: "合計スコアは_SCORE_点でした。また遊んでね", background: @background_school, speaker_image: @player_image, text_speed: @yomiage_speed, sound_content: "text_beep", await_input: true },
      # エンディング
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
      return
    end

    event = @story_data[@current_event_index]
    
    case event[:type]
    when :dialogue
      self.width, self.height = GAME_WIDTH, GAME_HEIGHT
      
      # 修正: ダイアログの文字列を動的に更新
      content = event[:content].gsub('_SCORE_', @total_score.to_s)
      
      @current_event = Dialogue.new(
        content: content,
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

# Dialogue, SoundManager クラスは変更なし