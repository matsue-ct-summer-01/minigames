require 'gosu'

class PKGame < Gosu::Window
  WIDTH  = 640
  HEIGHT = 480
  DIRECTIONS = ["左", "中央", "右"]

  def initialize
    super(WIDTH, HEIGHT)
    self.caption = "サッカー PK対決 (アニメーション付き)"

    @font = Gosu::Font.new(28)
    @round = 1
    @score = 0
    @message = "←:左 ↑:中央 →:右 でシュート！"

    # ボールの初期位置
    @ball_x = WIDTH / 2
    @ball_y = HEIGHT - 50
    @ball_target_x = @ball_x
    @ball_target_y = 100
    @ball_moving = false

    # キーパーの位置
    @keeper_x = WIDTH / 2
    @keeper_y = 120
    @keeper_target_x = @keeper_x
    @keeper_moving = false

    @result = ""
    @result_score = ""
    @enter=0
  end

  def update
    # ボール移動アニメーション
    if @ball_moving
      @ball_x += (@ball_target_x - @ball_x) * 0.2
      @ball_y += (@ball_target_y - @ball_y) * 0.2

      # ゴール到達判定
      if ((@ball_x - @ball_target_x).abs < 5) && ((@ball_y - @ball_target_y).abs < 5)
        @ball_moving = false
        judge_result
      end
    end

    # キーパー移動アニメーション
    if @keeper_moving
      @keeper_x += (@keeper_target_x - @keeper_x) * 0.2
      if (@keeper_x - @keeper_target_x).abs < 5
        @keeper_moving = false
      end
    end
  end

  def draw
    #背景
    #Gosu.draw_rect(0, 0, WIDTH, HEIGHT , Gosu::Color::GREEN, 0)

    # ゴール枠
    Gosu.draw_rect(WIDTH/2 - 100, 50, 200, 10, Gosu::Color::WHITE, 0)
    Gosu.draw_rect(WIDTH/2 - 100, 50, 10, 100, Gosu::Color::WHITE, 0)
    Gosu.draw_rect(WIDTH/2 + 100, 50, 10, 100, Gosu::Color::WHITE, 0)

    # キーパー
    #頭
    Gosu.draw_rect(@keeper_x - 7, @keeper_y - 20, 14, 14, Gosu::Color.argb(0xff_ffe0bd), 0)
    #体
    Gosu.draw_rect(@keeper_x - 12, @keeper_y - 6 , 24, 30, Gosu::Color::GREEN, 0)
    
    #腕
    Gosu.draw_rect(@keeper_x - 22, @keeper_y - 3, 10, 4, Gosu::Color::WHITE, 0)
    Gosu.draw_rect(@keeper_x + 12, @keeper_y - 3, 10, 4, Gosu::Color::WHITE, 0)

    #手
    Gosu.draw_rect(@keeper_x - 22 - 16, @keeper_y - 9, 16, 16, Gosu::Color::RED, 0)
    Gosu.draw_rect(@keeper_x + 12 + 10, @keeper_y - 9, 16, 16, Gosu::Color::RED, 0)
    
    #足
    Gosu.draw_rect(@keeper_x - 22, @keeper_y + 24, 15, 8, Gosu::Color::GRAY, 0)
    Gosu.draw_rect(@keeper_x + 7, @keeper_y + 24, 15, 8, Gosu::Color::GRAY, 0)

    # ボール
    Gosu.draw_rect(@ball_x - 10, @ball_y - 10, 20, 20, Gosu::Color::YELLOW, 0)

    # UI
    if @round <= 5
      @font.draw_text("ラウンド: #{@round} / 5", 20, 20, 1)
    end
    @font.draw_text("スコア: #{@score}", 20, 60, 1)
    @font.draw_text("スコア: #{@score}", 20, 100, 1)
    @font.draw_text(@message, 20, 400, 1)
    @font.draw_text(@result, 20, 300, 1, 1, 1, Gosu::Color::RED) unless @result.empty?
    @font.draw_text(@result_score, WIDTH/2 - 100, HEIGHT/2 , 1) unless @result.empty?
  end

  def button_down(id)
    return if @ball_moving #|| @round > 5
    
    if @round > 5 
      result
      return
    end

    player_choice = nil
    case id
    when Gosu::KB_LEFT  then player_choice = 0
    when Gosu::KB_UP    then player_choice = 1
    when Gosu::KB_RIGHT then player_choice = 2
    when Gosu::KB_ESCAPE then close
    end

    if player_choice
      # ボールのターゲット座標を決める
      case player_choice
      when 0 then @ball_target_x = WIDTH/2 - 80
      when 1 then @ball_target_x = WIDTH/2
      when 2 then @ball_target_x = WIDTH/2 + 80
      end
      @ball_target_y = 80
      @ball_moving = true

      # キーパーの飛ぶ方向
      @goalkeeper_choice = rand(0..2)
      case @goalkeeper_choice
      when 0 then @keeper_target_x = WIDTH/2 - 80
      when 1 then @keeper_target_x = WIDTH/2
      when 2 then @keeper_target_x = WIDTH/2 + 80
      end
      @keeper_moving = true

      @player_choice = player_choice
      @message = "シュート中..."
      @result = ""
    end
  end

  def judge_result
    if @player_choice == @goalkeeper_choice
      @result = "🥅 キーパーが#{DIRECTIONS[@goalkeeper_choice]}へ！セーブされた！"
    else
      @result = "⚽ ゴール！！ #{DIRECTIONS[@player_choice]}に決めた！"
      @score += 1
    end

    @round += 1
    if @round <= 5
      @message = "←:左 ↑:中央 →:右 でシュート！"
    else
      @message = "試合終了！ 矢印キーで結果"
    end

    # ボール位置をリセット
    @ball_x = WIDTH / 2
    @ball_y = HEIGHT - 50
  end

  def result
      if @score >= 3
      @result_score = "スコア #{@score} あなたの勝ち"
      else
      @result_score = "スコア #{@score} あなたの負け"
      end
  end
end

PKGame.new.show
