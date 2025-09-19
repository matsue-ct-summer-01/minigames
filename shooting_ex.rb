# frozen_string_literal: true
require 'gosu'

# -----------------------------
# ▼ ShootingGame クラス
# -----------------------------
class ShootingGame
  WINDOW_WIDTH  = 640#ウィンドウサイズ
  WINDOW_HEIGHT = 480

  BLOCK_SIZE = 80#ブロックの大きさ
  COLUMNS = WINDOW_WIDTH / BLOCK_SIZE#ブロック列数
  SPAWN_INTERVAL = 60#ブロック生成間隔(1sあたり1個)
  FALL_SPEED = 2.5#おちてくる速さの初期値
  BULLET_SPEED = 8#プレイヤー弾の速さ
  PLAYER_SPEED = 5.5#プレイヤーの移動速度
  PLAYER_SPEED_SHIFT = 3.0#SHIFT押下時のプレイヤー移動速度

  def self.window_size
    { width: WINDOW_WIDTH, height: WINDOW_HEIGHT }
  end

  # ── Player ──
  class Player
    attr_reader :x, :y, :w, :h
    def initialize
      @w = 20#自機サイズ
      @h = 20
      @x = WINDOW_WIDTH / 2 - @w / 2#初期座標
      @y = WINDOW_HEIGHT - @h - 10
      @cooldown = 0#弾の連射防止用
      @image = Gosu::Image.new("assets/images/player.png", retro: true) 
    end

    def update
      #移動（矢印かWASDで移動、SHIFTを押している間は移動速度が遅くなる）
      if !Gosu.button_down?(Gosu::KB_LEFT_SHIFT)
          @x -= PLAYER_SPEED if Gosu.button_down?(Gosu::KB_LEFT) || Gosu.button_down?(Gosu::KB_A)
          @x += PLAYER_SPEED if Gosu.button_down?(Gosu::KB_RIGHT) || Gosu.button_down?(Gosu::KB_D)
          @y -= PLAYER_SPEED if Gosu.button_down?(Gosu::KB_UP) || Gosu.button_down?(Gosu::KB_W)
          @y += PLAYER_SPEED if Gosu.button_down?(Gosu::KB_DOWN) || Gosu.button_down?(Gosu::KB_S)
      elsif Gosu.button_down?(Gosu::KB_LEFT_SHIFT)
          @x -= PLAYER_SPEED_SHIFT if Gosu.button_down?(Gosu::KB_LEFT) || Gosu.button_down?(Gosu::KB_A)
          @x += PLAYER_SPEED_SHIFT if Gosu.button_down?(Gosu::KB_RIGHT) || Gosu.button_down?(Gosu::KB_D)
          @y -= PLAYER_SPEED_SHIFT if Gosu.button_down?(Gosu::KB_UP) || Gosu.button_down?(Gosu::KB_W)
          @y += PLAYER_SPEED_SHIFT if Gosu.button_down?(Gosu::KB_DOWN) || Gosu.button_down?(Gosu::KB_S)
      end

      #画面外にでないように座標を戻す
      @x = [[@x, 0].max, WINDOW_WIDTH - @w].min
      @y = [[@y, 0].max, WINDOW_HEIGHT - @h].min
      @cooldown -= 1 if @cooldown > 0#クールダウン(弾の間隔)をデクリメント(ただし0以下にはならないように)
    end

    def draw(window)
      #window.draw_rect(@x, @y, @w, @h, Gosu::Color.rgba(80, 160, 255, 255), 1)
      #window.draw_rect(@x + 8, @y + 8, @w - 16, @h - 16, Gosu::Color.rgba(30, 30, 30, 255), 2)
  
      # 20x20 に縮小して描画　@w@hの値に縮小される
      @image.draw_as_quad(
        @x,         @y,          Gosu::Color::WHITE,
        @x + @w,    @y,          Gosu::Color::WHITE,
        @x,         @y + @h,     Gosu::Color::WHITE,
        @x + @w,    @y + @h,     Gosu::Color::WHITE,
        1
      )

    end

    def shoot
      return nil if @cooldown > 0#クールダウンが0じゃないと撃てない
      @cooldown = 12#クールダウンを12に(待ち時間)
      bx = @x + @w / 2 - 4#弾の生成位置を計算、プレイヤーの座標から発射するように
      by = @y - 8
      Bullet.new(bx, by)
    end

    def rect
      [@x/2, @y/2, @w/2, @h/2]#あたり判定用　画像より小さくして難易度を下げちゃおう！
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
      @y -= BULLET_SPEED#弾を上に移動
      @alive = false if @y + @h < 0#画面外に出たらいないよ～って教える
    end

    def draw(window)#弾描画
      window.draw_rect(@x, @y, @w, @h, Gosu::Color.rgba(255, 220, 80, 255), 3)
    end

    def alive?; @alive; end
    def destroy; @alive = false; end
    def rect; [@x, @y, @w, @h]; end
  end


  # ── EnemyBullet ──
class EnemyBullet
  attr_reader :x, :y, :w, :h
  SPEED = 2.5#敵弾の速さ

  def initialize(x, y, angle)#生成場所と角度をうけとる
    @x = x
    @y = y
    @angle = angle
    @w = 16
    @h = 16
    @alive = true
    # 画像読み込み（retro: trueでピクセル感を維持）
    @image = Gosu::Image.new("assets/images/shooting_star.png", retro: true)
  end

  def update
    @x += SPEED * Math.cos(@angle)#角度(ラジアン)x方向はcos、y方向はsin
    @y += SPEED * Math.sin(@angle)#方向とスピードで座標変更
    @alive = false if @x < 0 || @x > ShootingGame::WINDOW_WIDTH || @y < 0 || @y > ShootingGame::WINDOW_HEIGHT
  end

  def draw(window)
    # 画像を現在のサイズに合わせて描画
    @image.draw(@x, @y, 3, @w.to_f / @image.width, @h.to_f / @image.height)
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
      @size = BLOCK_SIZE#ブロックサイズ
      @x = col * BLOCK_SIZE
      @y = y
      @falling = falling#落下中フラグ
      @alive = true#画面外にいないか
      @color = random_color#色
      @fall_speed = FALL_SPEED * rand(0.5..2.0)#ブロックの落ちる速さ
      @shoot_cooldown = rand(40..70)#最初に弾を打つまで
    end

    def update(landed_heights, landed_blocks, enemy_bullets)
      # 落下処理
      if @falling
        target_bottom = ShootingGame::WINDOW_HEIGHT - landed_heights[@col]
        if @y + @size + @fall_speed >= target_bottom
          @y = target_bottom - @size
          @falling = false
          @row = landed_heights[@col] / BLOCK_SIZE
          landed_blocks[@col] << self
          landed_heights[@col] += BLOCK_SIZE
        else
          @y += @fall_speed
        end
      end

      # 全方位弾
      @shoot_cooldown -= 1
      if @shoot_cooldown <= 0#クールダウンが0なら敵弾を撃つ
        shots = 16
        shots.times do |i|#弾を16方向(shotで変更可)均等に生成
          angle = 2 * Math::PI * i / shots
          enemy_bullets << EnemyBullet.new(@x + @size / 2, @y + @size / 2, angle)
        end
        @shoot_cooldown = rand(500..700)#次の敵弾発射まで
      end
    end

    #def draw(window)
    #  window.draw_rect(@x + 1, @y + 1, @size - 2, @size - 2, @color, 1)
    #end

    def destroy; @alive = false; end
    def alive?; @alive; end
    def rect; [@x, @y, @size, @size]; end

    private
    def random_color#色ランダムに
      Gosu::Color.argb(0xff_000000 | (rand(0xFFFFFF)))
    end
  end

  # ── ShootingGame インスタンス
  def initialize(parent)
    
    @parent = parent#on_game_overコールバック用
    @player = Player.new
    @bullets = []
    @enemy_bullets = []
    @falling_blocks = []
    @landed_blocks = Array.new(COLUMNS) { [] }#各列の配列
    @landed_heights = Array.new(COLUMNS, 0)#列ごとの積み高さ
    @spawn_timer = 0
    @score = 0
    @game_over = false

    @bgm = Gosu::Song.new("assets/sounds/shooting.mp3")
    @bgm.play(true)
    @shot_sound = Gosu::Sample.new("assets/sounds/shooting_shot.mp3")
    @bomb_sound = Gosu::Sample.new("assets/sounds/shooting_bomb.mp3")
    
  end

  def update
  return if @game_over

  # ── プレイヤー更新 ──
  @player.update
  if Gosu.button_down?(Gosu::KB_Z)#Z押したら弾打てる
   b = @player.shoot
   @shot_sound.play
   @bullets << b if b
  end

  # ── プレイヤー弾更新 ──
  @bullets.each(&:update)
  @bullets.reject! { |b| !b.alive? }

  # ── ブロック生成 ──
  @spawn_timer += 1
  if @spawn_timer >= SPAWN_INTERVAL
    col = rand(0...COLUMNS)
    @falling_blocks << Block.new(col, -BLOCK_SIZE, true)
    @spawn_timer = 0
  end

  # ── ブロック更新 ──
  @falling_blocks.each { |blk| blk.update(@landed_heights, @landed_blocks, @enemy_bullets) }

  # ── プレイヤー弾とブロックの衝突判定 ──
  @bullets.each do |b|
    (@falling_blocks + @landed_blocks.flatten).each do |blk|
      next unless blk.alive?
      if collide_rect?(b.rect, blk.rect)
        blk.destroy
        b.destroy
        @bomb_sound.play
        @score += 100
      end
    end
  end

  # ── 配列から破壊済みブロックを削除 ──
  @falling_blocks.reject! { |blk| !blk.alive? }
  @landed_blocks.each { |col| col.reject! { |blk| !blk.alive? } }

  # ── 落下が終わったブロックだけ @falling_blocks から除外 ──
  @falling_blocks.reject! { |blk| !blk.falling }

  # ── 敵弾更新 ──
  @enemy_bullets.each(&:update)
  @enemy_bullets.reject! { |b| !b.alive? }

  # ── プレイヤー衝突判定 ──
  if check_player_collision_with_blocks || check_player_collision_with_enemy_bullets

    @bgm.stop   # ← ゲームオーバーになったらBGM停止
    @game_over = true
    
  end
end


  def draw
    # 描画オブジェクトを親から取得
    window = @parent

    window.draw_rect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, Gosu::Color.rgba(10, 10, 20, 255), 0)
    (0..COLUMNS).each do |c|#背景ぬりつぶし黒
      x = c * BLOCK_SIZE
      Gosu.draw_line(x, 0, Gosu::Color.argb(0xFF202020),#背景グリッド線
                      x, WINDOW_HEIGHT, Gosu::Color.argb(0xFF202020), 0)
    end

    #色々描画　積み上がったブロック→落下ブロック→弾→プレイヤーの順
    @landed_blocks.each { |col| col.each { |blk| blk.draw(window) } }
    @falling_blocks.each { |blk| blk.draw(window) }
    @bullets.each { |b| b.draw(window) }
    @enemy_bullets.each { |b| b.draw(window) }
    @player.draw(window)

    font = Gosu::Font.new(20)
    #スコア表示
    font.draw_text("Score: #{@score}", 10, 8, 10, 1.0, 1.0, Gosu::Color::YELLOW)
    if @game_over#ゲームオーバー時の挙動
        @parent.on_game_over(@score) # 親のメソッドを呼び出す
      #font.draw_text("GAME OVER", WINDOW_WIDTH / 2 - 90, WINDOW_HEIGHT / 2 - 20, 20, 1.5, 1.5, Gosu::Color::RED)
      #font.draw_text("Press R to Restart", WINDOW_WIDTH / 2 - 110, WINDOW_HEIGHT / 2 + 20, 20, 1.0, 1.0, Gosu::Color::WHITE)
    end
  end

  def button_down(id)
   if id == Gosu::KB_R && @game_over
     initialize(@parent)
   end
  end

  # def button_down(id)
  # if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
  #   b = @player.shoot
  #   if b
  #     @shot_sound.play
  #     @bullets << b
  #   end
  # elsif id == Gosu::KB_R && @game_over
  #   initialize(@window)
  # end

  # def button_down(id)
  # case id
  # when Gosu::KB_RETURN, Gosu::KB_ENTER
  #   b = @player.shoot
  #   if b
  #     @shot_sound.play
  #     @bullets << b
  #   end
  # when Gosu::KB_R
  #   initialize(@window) if @game_over
  # end
  #end

  private

  #あたり判定のみんな
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

  def check_player_collision_with_enemy_bullets
    px, py, pw, ph = @player.rect
    @enemy_bullets.any? { |b| collide_rect?([px, py, pw, ph], b.rect) }
  end
end
