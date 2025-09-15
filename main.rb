# frozen_string_literal: true
require 'gosu'
require_relative 'games/tetris/main'
# 他のゲームも同様にrequireする

class GameManager < Gosu::Window
  STATE_MENU = :menu
  STATE_PLAYING = :playing
  STATE_INTERMISSION = :intermission # 審問官との対話状態

  attr_reader :current_game

  def initialize
    super 640, 480
    self.caption = 'The Grand Interrogation'

    @game_state = STATE_MENU
    @font = Gosu::Font.new(30)
    @menu_font = Gosu::Font.new(20)
    @dialogue_font = Gosu::Font.new(20)

    # プレイヤーキャラクター
    @player_image = Gosu::Image.new('./assets/images/player.png')
    @player_x = 320
    @player_y = 400
    @player_speed = 6 # プレイヤーの移動速度を速く

    # 審問官の定義
    @inquisitors = {
      tetris: {
        id: :tetris,
        x: 320,
        y: 100,
        image: Gosu::Image.new('./assets/images/inquisitor_01.png'),
        dialogue: "私はテトリスの審問官だ。この試練を乗り越えろ。",
        class: TetrisGame,
        played: false
      }
      # 他の審問官をここに追加
      # breakout: { ... }, shooting: { ... }, etc.
    }
    @current_inquisitor = @inquisitors[:tetris]
  end

  def update
    case @game_state
    when STATE_PLAYING
      @current_game.update
    when STATE_MENU
      move_player
    when STATE_INTERMISSION
      # 対話状態ではプレイヤーを動かさない
    end
  end

  def draw
    Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK)

    case @game_state
    when STATE_PLAYING
      @current_game.draw
    when STATE_MENU, STATE_INTERMISSION
      draw_field

      # 審問官とプレイヤーを半分のサイズで描画
      @current_inquisitor[:image].draw(@current_inquisitor[:x] - 12.5, @current_inquisitor[:y] - 12.5, 0, 0.5, 0.5)
      @player_image.draw(@player_x, @player_y, 0, 0.5, 0.5)
      
      draw_ui
      if @game_state == STATE_INTERMISSION
        draw_dialogue_box
      end
    end
  end

  def button_down(id)
    case @game_state
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
    end
  end
  
  private

  def move_player
    @player_x -= @player_speed if Gosu.button_down?(Gosu::KB_A)
    @player_x += @player_speed if Gosu.button_down?(Gosu::KB_D)
    @player_y -= @player_speed if Gosu.button_down?(Gosu::KB_W)
    @player_y += @player_speed if Gosu.button_down?(Gosu::KB_S)
  end

  def draw_field
    @menu_font.draw_text('試練の間にようこそ', 180, 50, 1, 1.0, 1.0, Gosu::Color::WHITE)
  end

  def draw_ui
    @menu_font.draw_text("操作方法: WASDで移動, ENTERで話しかける", 10, height - 30, 1, 1.0, 1.0, Gosu::Color::WHITE)
  end
  
  def draw_dialogue_box
    Gosu.draw_rect(50, 300, 540, 100, Gosu::Color.rgba(0, 0, 0, 200), 10)
    Gosu.draw_rect(52, 302, 536, 96, Gosu::Color.rgba(50, 50, 50, 200), 10)
    @dialogue_font.draw_text(@current_inquisitor[:dialogue], 70, 320, 11, 1.0, 1.0, Gosu::Color::WHITE)
    @dialogue_font.draw_text("Enterでゲーム開始...", 70, 360, 11, 1.0, 1.0, Gosu::Color::YELLOW)
  end

  def check_interaction(id)
    if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
      distance = Gosu.distance(@player_x, @player_y, @current_inquisitor[:x], @current_inquisitor[:y])
      if distance < 50
        @game_state = STATE_INTERMISSION
      end
    end
  end
  
  def start_game
    @game_state = STATE_PLAYING
    game_class = @current_inquisitor[:class]
    size = game_class.window_size
    self.width, self.height = size[:width], size[:height]
    @current_game = game_class.new(self)
  end
end

if __FILE__ == $0
  GameManager.new.show
end