require 'gosu'

###############################
#          PKgame             #
###############################

class PKGame #< Gosu::Window ###共有時に無効
  WIDTH  = 640
  HEIGHT = 480
  DIRECTIONS = ["左", "中央", "右"]

  def initialize(window) ###共有時に有効
    #super(WIDTH, HEIGHT) ###共有時に無効
    self.caption = "サッカー PK対決"
  
    @haikei_image = Gosu::Image.new("./assets/images/penaltyarea.png")
    #@haikei_image = Gosu::Image.new("PKgame_img/penaltyarea.png")

    @font = Gosu::Font.new(28)
    @round = 1
    @score = 0
    @message = "←:左 ↑:中央 →:右 でシュート！"

    @ball_image = Gosu::Image.new("./assets/images/soccerball.png")
    #@ball_image = Gosu::Image.new("PKgame_img/soccerball.png")

    #@keeper_right_image = Gosu::Image.new("PKgame_img/keeper.png")
    #@keeper_left_image = Gosu::Image.new("PKgame_img/keeper_left.png")

    @keeper_right_image = Gosu::Image.new("./assets/images/keeper.png")
    @keeper_left_image = Gosu::Image.new("./assets/images/keeper_left.png")

    # ボールの初期位置
    @ball_x = WIDTH / 2 + 6
    @ball_y = HEIGHT - 73
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

    @end_button = false

    @goal_count = 0

    @game_over= false

    #サウンド
    @bgm = Gosu::Song.new("./assets/sounds/PKgame_bgm.mp3") 
    #@bgm = Gosu::Song.new("PKgame_sound/PKgame_bgm.mp3")
    
    @kick_sound  = Gosu::Sample.new("./assets/sounds/ボールを蹴る.mp3") 
    #@kick_sound  = Gosu::Sample.new("PKgame_sound/ボールを蹴る.mp3")
    
    @goal_sound  = Gosu::Sample.new("./assets/sounds/ゴールしたとき（サッカー）.mp3") 
    #@goal_sound  = Gosu::Sample.new("PKgame_sound/ゴールしたとき（サッカー）.mp3")
    
    @catch_sound  = Gosu::Sample.new("./assets/sounds/キャッチする（ドッチボール）.mp3") 
    #@catch_sound  = Gosu::Sample.new("PKgame_sound/キャッチする（ドッチボール）.mp3")
    
    @whistle_sound_start  = Gosu::Sample.new("./assets/sounds/ホイッスル（ピーッ）.mp3") 
    #@whistle_sound_start  = Gosu::Sample.new("PKgame_sound/ホイッスル（ピーッ）.mp3")

    @whistle_sound_end  = Gosu::Sample.new("./assets/sounds/ホイッスル（ピピーッ）.mp3") 
    #@whistle_sound_end  = Gosu::Sample.new("PKgame_sound/ホイッスル（ピピーッ）.mp3")

    @game_clear_sound = Gosu::Sample.new("./assets/sounds/歓声.mp3") 
    #@game_clear_sound = Gosu::Sample.new("PKgame_sound/歓声.mp3")

    #開始の笛
    @whistle_sound_start.play

  end

  def self.window_size
  { width: 640, height: 480 }
  end

  def update
    # ボール移動アニメーション
    @bgm.play

    if @ball_moving
      @ball_x += (@ball_target_x - @ball_x) * 0.2  #ボールのx座標が目的地に向かう
      @ball_y += (@ball_target_y - @ball_y) * 0.2  #ボールのy座標が目的地に向かう
      # ゴール到達判定
      if ((@ball_x - @ball_target_x).abs < 1) && ((@ball_y - @ball_target_y).abs < 1)  #ボールと目的地の距離がすごく近いとき接触
        @ball_moving = false #if文終了
        judge_result #メソッド呼び出し
      end
    end

    #ゲームオーバー
    if @game_over
      @parent.on_game_over(@score) # 親のメソッドを呼び出す
    end

    # キーパー移動アニメーション
    if @keeper_moving
      @keeper_x += (@keeper_target_x - @keeper_x) * 0.2
      if (@keeper_x - @keeper_target_x).abs < 1
        @keeper_moving = false
      end
    end
  end


  def draw
    #背景
    @haikei_image.draw(0, 125, 0, 0.188 , 0.2)

    # ゴール枠
    Gosu.draw_rect(WIDTH/2 - 100, 50, 200, 10, Gosu::Color::WHITE, 0)
    Gosu.draw_rect(WIDTH/2 - 100, 50, 10, 100, Gosu::Color::WHITE, 0)
    Gosu.draw_rect(WIDTH/2 + 100, 50, 10, 100, Gosu::Color::WHITE, 0)

    if @goalkeeper_choice == 2
      @keeper_right_image.draw(WIDTH / 2 + 20, 120 - 20, 1, 0.18, 0.22)
    end

    if @goalkeeper_choice == 0
      @keeper_left_image.draw(WIDTH / 2 - 120, 120 - 20, 1, 0.18, 0.22)
    end
    
    #キーパー
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
    @ball_image.draw(@ball_x - 45, @ball_y - 55, 1 , 0.3, 0.3)
    #@ball_image.draw(10,10,1)
    #Gosu.draw_rect(@ball_x - 10, @ball_y - 10, 20, 20, Gosu::Color::YELLOW, 0)

    # UI
    if @round == 1
      @font.draw_text("３ゴール以上でクリア", WIDTH/2 - 150, HEIGHT/2 , 1,  1.5, 1.5, Gosu::Color::BLACK)
    end

    if @round <= 5
      @font.draw_text("ラウンド: #{@round} / 5", 20, 20, 1)
    end
    @font.draw_text("スコア: #{@score}", 20, 60, 1)
    @font.draw_text("ゴール: #{@goal_count}回", 20, 100, 1)
    @font.draw_text(@message, 20, 330, 1, 1, 1, Gosu::Color::BLACK)
    @font.draw_text(@result, 20, 300, 1, 1, 1, Gosu::Color::RED) unless @result.empty?
    @font.draw_text(@result_score, WIDTH/2 - 150, HEIGHT/2 - 50 , 1, 1.5, 1.5, Gosu::Color::RED) unless @result.empty?
    
    #@font.draw_text("Enterキーを押して開始", WIDTH/2 - 100, HEIGHT/2 , 1) #unless @start_button=1
    
  end

  def button_down(id)
    return if @ball_moving #|| @start_button = 0 #|| @round > 5
    
    if @round > 5 
      case id
      when Gosu::KB_RETURN then @end_button = 1
      end

      if @end_button
        close
      end

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
      @kick_sound.play
      case player_choice
      when 0 then @ball_target_x = WIDTH/2 - 80
      when 1 then @ball_target_x = WIDTH/2
      when 2 then @ball_target_x = WIDTH/2 + 80
      end
      @ball_target_y = 110
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
      @catch_sound.play
      @result = "🥅 キーパーが#{DIRECTIONS[@goalkeeper_choice]}へ！セーブされた！"
    else
      @goal_sound.play
      @result = "⚽ ゴール！！ #{DIRECTIONS[@player_choice]}に決めた！"
      @score += 3000
      @goal_count += 1
    end

    @round += 1
    if @round <= 5
      @message = "←:左 ↑:中央 →:右 でシュート！"
    else
      @message = "試合終了！ 矢印キーで結果"
      @whistle_sound_end.play
    end

    # ボール位置をリセット
    @ball_x = WIDTH/2 + 6
    @ball_y = HEIGHT - 73
    @goalkeeper_choice = nil
  end

  def result
    if @goal_count >= 3
      @result_score = "あなたのスコア #{@score} \n        クリア！"
      @game_clear_sound.play
    else
      @result_score = "あなたのスコア #{@score} \n  ゲームオーバー！"
      @game_over = true
    end
  end
end

#PKGame.new.show ###共有時に無効
