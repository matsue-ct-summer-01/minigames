# main.rb
require 'gosu'

# --- 1. 定数とテトリミノの定義 ---
# Zオーダー: 描画順序を定義します。小さい値が下になります。
module ZOrder
  BACKGROUND, BOARD, TETROMINO, UI = *0..3
end

TETROMINOES = {
  i: { shape: [[1, 1, 1, 1]], color: Gosu::Color.rgb(0, 255, 255) },
  o: { shape: [[1, 1], [1, 1]], color: Gosu::Color.rgb(255, 255, 0) },
  j: { shape: [[1, 0, 0], [1, 1, 1]], color: Gosu::Color.rgb(0, 0, 255) },
  l: { shape: [[0, 0, 1], [1, 1, 1]], color: Gosu::Color.rgb(255, 165, 0) },
  s: { shape: [[0, 1, 1], [1, 1, 0]], color: Gosu::Color.rgb(0, 255, 0) },
  z: { shape: [[1, 1, 0], [0, 1, 1]], color: Gosu::Color.rgb(255, 0, 0) }
}.freeze

# --- 2. ゲームウィンドウクラス ---
class TetrisGame < Gosu::Window
  def initialize
    super 300, 600
    self.caption = "テトリス"

    @block_size = 30
    @board_width = 10
    @board_height = 20
    @board = Array.new(@board_height) { Array.new(@board_width, nil) }
    @score = 0
    @game_over = false

    @last_update = Gosu.milliseconds
    @fall_interval = 500
    @font = Gosu::Font.new(20)
    
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
    Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK, ZOrder::BACKGROUND)
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
        # 枠線を描画する
        Gosu.draw_rect(x * @block_size, y * @block_size, @block_size, 1, Gosu::Color::GRAY, ZOrder::BOARD) # 上
        Gosu.draw_rect(x * @block_size, y * @block_size + @block_size - 1, @block_size, 1, Gosu::Color::GRAY, ZOrder::BOARD) # 下
        Gosu.draw_rect(x * @block_size, y * @block_size, 1, @block_size, Gosu::Color::GRAY, ZOrder::BOARD) # 左
        Gosu.draw_rect(x * @block_size + @block_size - 1, y * @block_size, 1, @block_size, Gosu::Color::GRAY, ZOrder::BOARD) # 右
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
    rotated = @current_tetromino_shape.transpose.map(&:reverse)
    
    # 壁衝突時の修正
    original_x = @x
    
    # 衝突判定
    @current_tetromino_shape = rotated
    while collision?
      if @x < 0
        @x += 1
      elsif @x + @current_tetromino_shape[0].size > @board_width
        @x -= 1
      else
        # 衝突した場合、回転を元に戻す
        @current_tetromino_shape = @current_tetromino_shape.reverse.transpose
        @x = original_x
        return
      end
    end
  end

  def check_game_over
    if collision?(0, 0)
      @game_over = true
    end
  end
end

TetrisGame.new.show if __FILE__ == $0