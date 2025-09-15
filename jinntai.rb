require 'gosu'

WINDOW_W = 640
WINDOW_H = 480

class Humanoid
  def initialize(x, y)
    @x = x
    @y = y
    @width = 40
    @height = 80
    @speed = 5
  end

  def update(left, right)
    if left
      @x -= @speed
    elsif right
      @x += @speed
    end
    @x = [[@x, 0].max, WINDOW_W - @width].min
  end

  def draw
    cx = @x + @width / 2
    top = @y - @height

    # 体
    body_w = 24
    body_h = 36
    Gosu.draw_rect(cx - body_w/2, top + 20, body_w, body_h, Gosu::Color::WHITE, 0)

    # 頭
    Gosu.draw_rect(cx - 14, top, 28, 22, Gosu::Color.argb(0xff_ffe0bd), 0)

    # 足
    Gosu.draw_rect(cx - 12, top + 56, 8, 24, Gosu::Color::GRAY, 0)
    Gosu.draw_rect(cx + 4, top + 56, 8, 24, Gosu::Color::GRAY, 0)

    # 腕
    Gosu.draw_rect(cx - 20, top + 24, 6, 24, Gosu::Color::WHITE, 0)
    Gosu.draw_rect(cx + 14, top + 24, 6, 24, Gosu::Color::WHITE, 0)

    # 影
    Gosu.draw_rect(cx - 20, @y + 4, 40, 8, Gosu::Color.argb(0x66000000), 0)
  end
end

class GameWindow < Gosu::Window
  def initialize
    super(WINDOW_W, WINDOW_H)
    self.caption = "Gosu 人型（左右移動のみ）"
    @humanoid = Humanoid.new(WINDOW_W / 2 - 20, WINDOW_H - 60)
    @font = Gosu::Font.new(20)
  end

  def update
    left  = Gosu.button_down?(Gosu::KB_LEFT)
    right = Gosu.button_down?(Gosu::KB_RIGHT)
    @humanoid.update(left, right)
  end

  def draw
    # 背景と地面
    Gosu.draw_rect(0, 0, WINDOW_W, WINDOW_H, Gosu::Color::AQUA, 0)
    Gosu.draw_rect(0, WINDOW_H - 60, WINDOW_W, 60, Gosu::Color::GREEN, 0)

    @humanoid.draw
    @font.draw_text("← → で移動, ESCで終了", 10, 10, 1, 1, 1, Gosu::Color::BLACK)
  end

  def button_down(id)
    close if id == Gosu::KB_ESCAPE
  end
end

GameWindow.new.show