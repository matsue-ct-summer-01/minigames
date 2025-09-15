require 'gosu'

# -----------------------------
# ▼ ShootingGame クラス
# -----------------------------
class ShootingGame
  WINDOW_WIDTH  = 640
  WINDOW_HEIGHT = 480

  BLOCK_SIZE = 64
  COLUMNS = WINDOW_WIDTH / BLOCK_SIZE
  SPAWN_INTERVAL = 60
  FALL_SPEED = 2.5
  BULLET_SPEED = 8
  PLAYER_SPEED = 5.5

  # クラスメソッドでウィンドウサイズを返す
  def self.window_size
    { width: WINDOW_WIDTH, height: WINDOW_HEIGHT }
  end

  # ── Player ──
  class Player
    attr_reader :x, :y, :w, :h
    def initialize
      @w = 36
      @h = 36
      @x = WINDOW_WIDTH / 2 - @w / 2
      @y = WINDOW_HEIGHT - @h - 10
      @cooldown = 0
    end

    def update
      if Gosu.button_down?(Gosu::KB_LEFT) || Gosu.button_down?(Gosu::KB_A)
        @x -= PLAYER_SPEED
      end
      if Gosu.button_down?(Gosu::KB_RIGHT) || Gosu.button_down?(Gosu::KB_D)
        @x += PLAYER_SPEED
      end
      if Gosu.button_down?(Gosu::KB_UP) || Gosu.button_down?(Gosu::KB_W)
        @y -= PLAYER_SPEED
      end
      if Gosu.button_down?(Gosu::KB_DOWN) || Gosu.button_down?(Gosu::KB_S)
        @y += PLAYER_SPEED
      end

      @x = [[@x, 0].max, WINDOW_WIDTH - @w].min
      @y = [[@y, 0].max, WINDOW_HEIGHT - @h].min
      @cooldown -= 1 if @cooldown > 0
    end

    def draw(window)
      window.draw_rect(@x, @y, @w, @h, Gosu::Color.rgba(80, 160, 255, 255), 1)
      window.draw_rect(@x + 8, @y + 8, @w - 16, @h - 16, Gosu::Color.rgba(30, 30, 30, 255), 2)
    end

    def shoot
      return nil if @cooldown > 0
      @cooldown = 12
      bx = @x + @w / 2 - 4
      by = @y - 8
      Bullet.new(bx, by)
    end

    def rect
      [@x, @y, @w, @h]
    end
  end

  # ── Bullet ──
  class Bullet
    attr_reader :x, :y, :w, :h
    def initialize(x, y)
      @x = x
      @y = y
      @w = 8
      @h = 12
      @alive = true
    end

    def update
      @y -= BULLET_SPEED
      @alive = false if @y + @h < 0
    end

    def draw(window)
      window.draw_rect(@x, @y, @w, @h, Gosu::Color.rgba(255, 220, 80, 255), 3)
    end

    def alive?; @alive; end
    def destroy; @alive = false; end
    def rect; [@x, @y, @w, @h]; end
  end

  # ── Block ──
  class Block
    attr_accessor :col, :row, :x, :y, :size
    attr_reader :falling, :alive
    def initialize(col, y, falling = true)
      @col = col
      @size = BLOCK_SIZE
      @x = col * BLOCK_SIZE
      @y = y
      @falling = falling
      @alive = true
      @color = random_color
    end

    def update(landed_heights, landed_blocks)
      return unless @falling
      target_bottom = WINDOW_HEIGHT - landed_heights[@col]

      if @y + @size + FALL_SPEED >= target_bottom
        @y = target_bottom - @size
        @falling = false
        @row = landed_heights[@col] / BLOCK_SIZE
        landed_blocks[@col] << self
        landed_heights[@col] += BLOCK_SIZE
      else
        @y += FALL_SPEED
      end
    end

    def draw(window)
      window.draw_rect(@x + 1, @y + 1, @size - 2, @size - 2, @color, 1)
    end

    def destroy; @alive = false; end
    def alive?; @alive; end
    def rect; [@x, @y, @size, @size]; end

    private
    def random_color
      Gosu::Color.argb(0xff_000000 | (rand(0xFFFFFF)))
    end
  end

  # ── ShootingGame インスタンス（Window に依存しない管理用） ──
  def initialize(window)
    @window = window
    @player = Player.new
    @bullets = []
    @falling_blocks = []
    @landed_blocks = Array.new(COLUMNS) { [] }
    @landed_heights = Array.new(COLUMNS, 0)
    @spawn_timer = 0
    @score = 0
    @game_over = false
  end

  def update
    return if @game_over

    @player.update
    if Gosu.button_down?(Gosu::KB_SPACE)
      b = @player.shoot
      @bullets << b if b
    end

    @bullets.each(&:update)
    @bullets.reject! { |b| !b.alive? }

    @spawn_timer += 1
    if @spawn_timer >= SPAWN_INTERVAL
      col = rand(0...COLUMNS)
      @falling_blocks << Block.new(col, -BLOCK_SIZE, true)
      @spawn_timer = 0
    end

    @falling_blocks.each { |blk| blk.update(@landed_heights, @landed_blocks) }
    @falling_blocks.reject! { |blk| !blk.falling }

    @bullets.each do |b|
      (@falling_blocks + @landed_blocks.flatten).each do |blk|
        next unless blk.alive?
        if collide_rect?(b.rect, blk.rect)
          blk.destroy
          b.destroy
          @score += 100
        end
      end
    end

    @falling_blocks.reject! { |b| !b.alive? }
    COLUMNS.times { |c| @landed_blocks[c].reject! { |b| !b.alive? } }

    @game_over = true if check_player_collision_with_blocks
  end

  def draw
    window = @window
    window.draw_rect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, Gosu::Color.rgba(10, 10, 20, 255), 0)
    (0..COLUMNS).each do |c|
      x = c * BLOCK_SIZE
      Gosu.draw_line(x, 0, Gosu::Color.argb(0xFF202020),
                      x, WINDOW_HEIGHT, Gosu::Color.argb(0xFF202020), 0)
    end

    @landed_blocks.each { |col| col.each { |blk| blk.draw(window) } }
    @falling_blocks.each { |blk| blk.draw(window) }
    @bullets.each { |b| b.draw(window) }
    @player.draw(window)

    font = Gosu::Font.new(20)
    font.draw_text("Score: #{@score}", 10, 8, 10, 1.0, 1.0, Gosu::Color::YELLOW)
    if @game_over
      font.draw_text("GAME OVER", WINDOW_WIDTH / 2 - 90, WINDOW_HEIGHT / 2 - 20, 20, 1.5, 1.5, Gosu::Color::RED)
      font.draw_text("Press R to Restart", WINDOW_WIDTH / 2 - 110, WINDOW_HEIGHT / 2 + 20, 20, 1.0, 1.0, Gosu::Color::WHITE)
    end
  end

  def button_down(id)
    if id == Gosu::KB_R && @game_over
      initialize(@window)
    end
  end

  private

  def collide_rect?(a, b)
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    !(ax + aw <= bx || bx + bw <= ax || ay + ah <= by || by + bh <= ay)
  end

  def check_player_collision_with_blocks
    px, py, pw, ph = @player.rect
    (@falling_blocks + @landed_blocks.flatten).any? do |blk|
      blk.alive? && collide_rect?([px, py, pw, ph], blk.rect)
    end
  end
end