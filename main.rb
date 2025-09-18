# frozen_string_literal: true
require 'gosu'
require_relative 'games/tetris/main'
require_relative 'games/shooting/main'
require_relative 'core/story'
require_relative 'core/scene'
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
    @title_font = Gosu::Font.new(FONT_SIZE_DIALOGUE) # Dialogue font is used for simplicity

    # アセットのロード
    @sound_manager = SoundManager.new
    @background_school = Gosu::Image.new('./assets/images/b_school.jpg')
    @background_stone = Gosu::Image.new('./assets/images/b_stone.jpg')
    @player_image = Gosu::Image.new('./assets/images/player.png')
    @inquisitor_image = Gosu::Image.new('./assets/images/inquisitor_01.png')
    
    # スコア管理
    @game_scores = { tetris: 0, shooting: 0 }
    @total_score = 0
    @last_game_score = 0

    @games_sequence = [
      { id: :tetris, class: TetrisGame, title: "テトリスの試練", dialogue: "集中しろ。テトリスで機転を試す。\nブロックを完璧に並べてみろ。さあ、どうする？" },
      { id: :shooting, class: ShootingGame, title: "シューティングの試練", dialogue: "ビビってんじゃねえ！シューティングで度胸見せてこい！\nブロック避けるかブッ壊しちまえ！Z押したら弾撃てっから！" }
    ]
    @current_game_index = 0

    setup_story
  end

  def update
    case @game_state
    when STATE_STORY
      @story.update
      if @story.finished?
        start_game
      end
    when STATE_PLAYING
      @current_game.update
    end
  end

  def draw
    Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK)

    case @game_state
    when STATE_STORY
      @story.draw
    when STATE_PLAYING
      @current_game.draw
    when STATE_END
      @background_school.draw(0, 0, 0)
      draw_end_screen
    end
    draw_scores unless @game_state == STATE_PLAYING
  end

  def button_down(id)
    case @game_state
    when STATE_STORY
      @story.button_down(id)
    when STATE_PLAYING
      if id == Gosu::KB_ESCAPE
        @game_state = STATE_STORY
        @current_game = nil
        self.width, self.height = GAME_WIDTH, GAME_HEIGHT
      else
        @current_game.button_down(id)
      end
    when STATE_END
      if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
        close
      end
    end
  end

  def on_game_over(score)
    game_key = @games_sequence[@current_game_index][:id]
    @game_scores[game_key] = score
    @last_game_score = score
    @total_score += score
    switch_to_next_stage
  end

  private

 def setup_story
    dialogues_for_next_stage = []
    current_game_data = @games_sequence[@current_game_index]

    if @current_game_index == 0
      dialogues_for_next_stage << {
        elements: [
          { type: :text, content: "暗い場所で意識を取り戻す。\n\n冷たい石の床、頭上の巨大なアーチ、響くのはかすかな足音。" },
          { type: :sound, content: "text_beep" },
          { type: :text, content: "ここが...試練の間、か。" }
        ],
        speaker_image: @player_image,
        dialogue_font: @dialogue_font,
        sound_manager: @sound_manager,
        text_speed: 2 # プレイヤーの速度を設定
      }
    else
      dialogues_for_next_stage << {
        elements: [
          { type: :text, content: "試練を突破した。合計スコアは#{@total_score}点だ。" },
          { type: :sound, content: "text_beep" },
          { type: :text, content: "次の扉へと進む。" }
        ],
        speaker_image: @player_image,
        dialogue_font: @dialogue_font,
        sound_manager: @sound_manager,
        text_speed: 2 # プレイヤーの速度を設定
      }
    end

    # ミニゲーム開始前のダイアログ
    dialogues_for_next_stage << {
      elements: [
        { type: :text, content: current_game_data[:dialogue] }
      ],
      speaker_image: @inquisitor_image,
      dialogue_font: @dialogue_font,
      sound_manager: @sound_manager,
      text_speed: 1 # 審問官は早口にしたいので1に設定
    }

    story_scenes = [
      {
        background: @background_school,
        dialogues: dialogues_for_next_stage
      }
    ]
    @story = Story.new(scenes_data: story_scenes, window: self)
    @game_state = STATE_STORY
  end

  def start_game
    game_class = @games_sequence[@current_game_index][:class]
    size = game_class.window_size
    self.width, self.height = size[:width], size[:height]
    @current_game = game_class.new(self)
    @game_state = STATE_PLAYING
  end

  def switch_to_next_stage
    @current_game_index += 1
    if @current_game_index >= @games_sequence.length
      @game_state = STATE_END
      self.width, self.height = GAME_WIDTH, GAME_HEIGHT
    else
      self.width, self.height = GAME_WIDTH, GAME_HEIGHT
      setup_story
    end
    @current_game = nil
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