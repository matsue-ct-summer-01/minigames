# frozen_string_literal: true
require 'gosu'
require_relative './games/tetris/main'
require_relative './games/shooting/main'
require_relative './games/uno/main'

#require_relative './breakout/main' # 実際のパスに合わせてください

# ===============================================================
# ▼ ゲームマネージャークラス (GameManager)
# ゲームの選択と管理を行います。
# ===============================================================
class GameManager < Gosu::Window
  STATE_MENU = :menu
  STATE_PLAYING = :playing

  attr_reader :current_game

  def initialize
    super 640, 480
    self.caption = 'Game Manager'

    @game_state = STATE_MENU
    @font = Gosu::Font.new(30)
    @menu_font = Gosu::Font.new(20)

    # ゲームのクラス（設計図）をハッシュに格納しておく
    @game_classes = {
      tetris: TetrisGame,
      shooting: ShootingGame,
      uno: UnoGame,
      #breakout: BreakoutGame
    }

    @current_game_key = :tetris
    
    # 初期ゲームのインスタンス（実体）を生成
    # ここではインスタンスを作成するだけで、実際の実行はEnterキーまで待つ
    @current_game = @game_classes[@current_game_key].new(self)
  end

  def update
    # ゲームプレイ中のみ、現在プレイ中のゲームのupdateメソッドを呼ぶ
    @current_game.update if @game_state == STATE_PLAYING
  end

  def draw
    if @game_state == STATE_PLAYING
      # ゲームプレイ中なら、ゲーム画面を描画
      @current_game.draw
    elsif @game_state == STATE_MENU
      # メニュー画面を描画
      Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK)
      @font.draw_text('PRESS ENTER TO START', 150, 200, 1, 1.0, 1.0, Gosu::Color::WHITE)
      @menu_font.draw_text('Press T for Tetris, B for Breakout S for Shooting', 100, 250, 1, 1.0, 1.0, Gosu::Color::WHITE)
      @menu_font.draw_text("Selected: #{@current_game_key.to_s.capitalize}", 200, 300, 1, 1.0, 1.0, Gosu::Color::YELLOW)
    end
  end

  def button_down(id)
    if @game_state == STATE_PLAYING
      # ゲームプレイ中のキー操作
      if id == Gosu::KB_ESCAPE
        # ESCキーでメニューに戻る
        @game_state = STATE_MENU
        # ウィンドウサイズをメニューサイズに戻す
        self.width = 640
        self.height = 480
      else
        # それ以外のキーは現在のゲームに渡す
        @current_game.button_down(id)
      end
    else # メニュー画面でのキー操作
      case id
      when Gosu::KB_RETURN, Gosu::KB_ENTER
        # Enterキーでゲーム開始
        @game_state = STATE_PLAYING
        # 選択されたゲームのサイズにウィンドウをリサイズ
        size = @game_classes[@current_game_key].window_size
        self.width = size[:width]
        self.height = size[:height]
        # インスタンスを新しく作り直し、完全な初期状態にする
        @current_game = @game_classes[@current_game_key].new(self)

      when Gosu::KB_T
        # Tキーでテトリスを選択
        @current_game_key = :tetris
        puts 'Switched to Tetris.'

      when Gosu::KB_B
        # Bキーでブレイクアウトを選択
        @current_game_key = :breakout
        puts 'Switched to Breakout.'

      when Gosu::KB_S
        # Sキーでシューティングを選択
        @current_game_key = :shooting
        puts 'Switched to Shooting.'

      when Gosu::KB_U
      # Uキーでunoを選択
      @current_game_key = :uno
      puts 'Switched to UNO.'
      end
    end
  end
end

if __FILE__ == $0
  GameManager.new.show
end