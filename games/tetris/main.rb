# frozen_string_literal: true
require 'gosu'

# ===============================================================
# ▼ ゲーム1: テトリス (TetrisGame)
# Gosu::Windowを継承せず、ロジック部分のみを担当します。
# ===============================================================
class TetrisGame
  # --- 1. 定数とテトリミノの定義 ---
  module ZOrder
    BACKGROUND, TETROMINO,BOARD, UI = *0..3
  end

  TETROMINOES = {
    i: { shape: [[1, 1, 1, 1]], color: Gosu::Color.rgb(0, 255, 255) },
    o: { shape: [[1, 1], [1, 1]], color: Gosu::Color.rgb(255, 255, 0) },
    j: { shape: [[1, 0, 0], [1, 1, 1]], color: Gosu::Color.rgb(0, 0, 255) },
    l: { shape: [[0, 0, 1], [1, 1, 1]], color: Gosu::Color.rgb(255, 165, 0) },
    s: { shape: [[0, 1, 1], [1, 1, 0]], color: Gosu::Color.rgb(0, 255, 0) },
    z: { shape: [[1, 1, 0], [0, 1, 1]], color: Gosu::Color.rgb(255, 0, 0) }
  }.freeze

  # GameManagerがウィンドウサイズを取得するためのクラスメソッド
  def self.window_size
    { width: 300, height: 480 }
  end

  def initialize(window)
    @window = window
    
    @block_size = 30
    @board_width = 10
    @board_height = 16
    @board = Array.new(@board_height) { Array.new(@board_width, nil) }
    @score = 0
    @game_over = false

    @last_update = Gosu.milliseconds
    @fall_interval = 500
    @font = Gosu::Font.new(20)
    
    # BGMの読み込みと再生
    # .mp3は非推奨のため、もし可能であれば.oggファイルに変換して使ってください。
    @bgm = Gosu::Song.new('./assets/sounds/tetris.mp3')
    @bgm.play(true) # 引数にtrueを渡すとループ再生になります

    new_tetromino
  end

  def update
    return if @game_over
    
    if Gosu.milliseconds - @last_update > @fall_interval
      @y += 1
      @last_update = Gosu.milliseconds
      if collision?
        @y -= 1
        lock_tetromino
        clear_lines
        new_tetromino
        check_game_over
      end
    end
  end

  def draw
    Gosu.draw_rect(0, 0, @window.width, @window.height, Gosu::Color::BLACK, ZOrder::BACKGROUND)
    draw_board
    draw_current_tetromino

    if @game_over
      @font.draw_text("ゲームオーバー", 20, 250, ZOrder::UI, 2.0, 2.0, Gosu::Color::RED)
      @font.draw_text("スコア: #{@score}", 100, 300, ZOrder::UI)
    else
      @font.draw_text("スコア: #{@score}", 10, 10, ZOrder::UI)
    end
  end

  def button_down(id)
    return if @game_over
    case id
    when Gosu::KB_LEFT
      @x -= 1 unless collision?(-1, 0)
    when Gosu::KB_RIGHT
      @x += 1 unless collision?(1, 0)
    when Gosu::KB_DOWN
      @y += 1
      if collision?
        @y -= 1
        lock_tetromino
        clear_lines
        new_tetromino
        check_game_over
      end
    when Gosu::KB_UP
      rotate_tetromino
    end
  end

  private

  def new_tetromino
    type = TETROMINOES.keys.sample
    data = TETROMINOES[type]
    @current_tetromino_shape = data[:shape]
    @current_tetromino_color = data[:color]
    @x = 4
    @y = 0
  end

  def draw_board
    @board.each_with_index do |row, y|
      row.each_with_index do |color, x|
        if color
          Gosu.draw_rect(x * @block_size, y * @block_size, @block_size, @block_size, color, ZOrder::BOARD)
        end
        Gosu.draw_rect(x * @block_size, y * @block_size, @block_size, 1, Gosu::Color::GRAY, ZOrder::BOARD)
        Gosu.draw_rect(x * @block_size, y * @block_size + @block_size - 1, @block_size, 1, Gosu::Color::GRAY, ZOrder::BOARD)
        Gosu.draw_rect(x * @block_size, y * @block_size, 1, @block_size, Gosu::Color::GRAY, ZOrder::BOARD)
        Gosu.draw_rect(x * @block_size + @block_size - 1, y * @block_size, 1, @block_size, Gosu::Color::GRAY, ZOrder::BOARD)
      end
    end
  end

  def draw_current_tetromino
    return if @current_tetromino_shape.nil?
    @current_tetromino_shape.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        if cell == 1
          Gosu.draw_rect((@x + x) * @block_size, (@y + y) * @block_size, @block_size, @block_size, @current_tetromino_color, ZOrder::TETROMINO)
        end
      end
    end
  end
  
  def collision?(dx=0, dy=0)
    @current_tetromino_shape.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        if cell == 1
          board_x = @x + x + dx
          board_y = @y + y + dy
          
          if board_x < 0 || board_x >= @board_width || board_y >= @board_height || (board_y >= 0 && @board[board_y][board_x])
            return true
          end
        end
      end
    end
    false
  end

  def lock_tetromino
    @current_tetromino_shape.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        if cell == 1
          @board[@y + y][@x + x] = @current_tetromino_color
        end
      end
    end
  end

  def clear_lines
    lines_cleared = 0
    (@board_height - 1).downto(0) do |y|
      if @board[y].all?
        @board.delete_at(y)
        @board.unshift(Array.new(@board_width, nil))
        lines_cleared += 1
      end
    end
    update_score(lines_cleared)
  end

  def update_score(lines)
    case lines
    when 1
      @score += 100
    when 2
      @score += 300
    when 3
      @score += 500
    when 4
      @score += 800
    end
  end
  
  def rotate_tetromino
    # 1. 形状を保存
    original_shape = @current_tetromino_shape
    original_x = @x
    
    # 2. 形状を回転させる
    # 配列を転置し、各行を反転させることで90度回転を実現
    rotated = original_shape.transpose.map(&:reverse)
    @current_tetromino_shape = rotated
    
    # 3. 衝突チェックと位置調整
    # 回転後のブロックが壁や他のブロックと衝突しないように位置をずらす
    adjust_count = 0
    max_adjusts = 5
    while collision? && adjust_count < max_adjusts
      if @x < 0
        @x += 1 # 左側の壁に衝突したら右に1マスずらす
      elsif @x + @current_tetromino_shape[0].size > @board_width
        @x -= 1 # 右側の壁に衝突したら左に1マスずらす
      else
        break # 左右に動かしても解決しない場合はループを抜ける
      end
      adjust_count += 1
    end

    # 4. 最終チェック
    # 調整後も衝突している場合は、回転をキャンセルして元の状態に戻す
    if collision?
      @current_tetromino_shape = original_shape
      @x = original_x
    end
  end

  def check_game_over
    if collision?(0, 0)
      @game_over = true
    end
  end
end