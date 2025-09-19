# frozen_string_literal: true
require 'gosu'

###############################
#     PKgame      #
###############################

class PKGame
 WIDTH = 640
 HEIGHT = 480
 DIRECTIONS = ["左", "中央", "右"]

 def initialize(window)
  @parent = window
  @haikei_image = Gosu::Image.new("./PKgame_img/penaltyarea.png")

  @font = Gosu::Font.new(28)
  @round = 1
  @score = 0
  @message = "←:左 ↑:中央 →:右 でシュート！"

  @ball_image = Gosu::Image.new("./PKgame_img/soccerball.png")

  @keeper_right_image = Gosu::Image.new("./PKgame_img/keeper.png")
  @keeper_left_image = Gosu::Image.new("./PKgame_img/keeper_left.png")

  @ball_x = WIDTH / 2 + 6
  @ball_y = HEIGHT - 73
  @ball_target_x = @ball_x
  @ball_target_y = 100
  @ball_moving = false

  @keeper_x = WIDTH / 2
  @keeper_y = 120
  @keeper_target_x = @keeper_x
  @keeper_moving = false

  @result = ""
  @result_score = ""

  @end_button = false

  @goal_count = 0

  @game_over = false

  # 修正: 結果表示の待機状態を管理するための変数
  @game_end_state = false
  @game_end_counter = 0
  @game_end_max_frames = 180 # 3秒待機 (60FPSを想定)

  @bgm = Gosu::Song.new("./PKgame_sound/PKgame_bgm.mp3") 
  @kick_sound = Gosu::Sample.new("./PKgame_sound/ボールを蹴る.mp3") 
  @goal_sound = Gosu::Sample.new("./PKgame_sound/ゴールしたとき（サッカー）.mp3") 
  @catch_sound = Gosu::Sample.new("./PKgame_sound/キャッチする（ドッチボール）.mp3") 
  @whistle_sound_start = Gosu::Sample.new("./PKgame_sound/ホイッスル（ピーッ）.mp3") 
  @whistle_sound_end = Gosu::Sample.new("./PKgame_sound/ホイッスル（ピピーッ）.mp3") 
  @game_clear_sound = Gosu::Sample.new("./PKgame_sound/歓声.mp3") 

  @whistle_sound_start.play
 end

 def self.window_size
  { width: 640, height: 480 }
 end

 def update
  @bgm.play

  # 修正: ゲーム終了状態に入ったら、カウントを開始して待機
  if @game_end_state
   @bgm.stop
   @game_end_counter += 1
   if @game_end_counter >= @game_end_max_frames
    @parent.on_game_over(@score)
    @game_over = true
   end
   return
  end

  # ボール移動アニメーション
  if @ball_moving
   @ball_x += (@ball_target_x - @ball_x) * 0.2 
   @ball_y += (@ball_target_y - @ball_y) * 0.2 
   if ((@ball_x - @ball_target_x).abs < 1) && ((@ball_y - @ball_target_y).abs < 1) 
    @ball_moving = false
    judge_result
   end
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
  @haikei_image.draw(0, 125, 0, 0.188 , 0.2)

  Gosu.draw_rect(WIDTH/2 - 100, 50, 200, 10, Gosu::Color::WHITE, 0)
  Gosu.draw_rect(WIDTH/2 - 100, 50, 10, 100, Gosu::Color::WHITE, 0)
  Gosu.draw_rect(WIDTH/2 + 100, 50, 10, 100, Gosu::Color::WHITE, 0)

  if @goalkeeper_choice == 2
   @keeper_right_image.draw(WIDTH / 2 + 20, 120 - 20, 1, 0.18, 0.22)
  end

  if @goalkeeper_choice == 0
   @keeper_left_image.draw(WIDTH / 2 - 120, 120 - 20, 1, 0.18, 0.22)
  end
  
  Gosu.draw_rect(@keeper_x - 7, @keeper_y - 20, 14, 14, Gosu::Color.argb(0xff_ffe0bd), 0)
  Gosu.draw_rect(@keeper_x - 12, @keeper_y - 6 , 24, 30, Gosu::Color::GREEN, 0)
  Gosu.draw_rect(@keeper_x - 22, @keeper_y - 3, 10, 4, Gosu::Color::WHITE, 0)
  Gosu.draw_rect(@keeper_x + 12, @keeper_y - 3, 10, 4, Gosu::Color::WHITE, 0)
  Gosu.draw_rect(@keeper_x - 22 - 16, @keeper_y - 9, 16, 16, Gosu::Color::RED, 0)
  Gosu.draw_rect(@keeper_x + 12 + 10, @keeper_y - 9, 16, 16, Gosu::Color::RED, 0)
  Gosu.draw_rect(@keeper_x - 22, @keeper_y + 24, 15, 8, Gosu::Color::GRAY, 0)
  Gosu.draw_rect(@keeper_x + 7, @keeper_y + 24, 15, 8, Gosu::Color::GRAY, 0)

  @ball_image.draw(@ball_x - 45, @ball_y - 55, 1 , 0.3, 0.3)
  
  if @round == 1
   @font.draw_text("３ゴール以上でクリア", WIDTH/2 - 150, HEIGHT/2 , 1, 1.5, 1.5, Gosu::Color::BLACK)
  end

  if @round <= 5
   @font.draw_text("ラウンド: #{@round} / 5", 20, 20, 1)
  end
  @font.draw_text("スコア: #{@score}", 20, 60, 1)
  @font.draw_text("ゴール: #{@goal_count}回", 20, 100, 1)
  @font.draw_text(@message, 20, 330, 1, 1, 1, Gosu::Color::BLACK)
  @font.draw_text(@result, 20, 300, 1, 1, 1, Gosu::Color::RED) unless @result.empty?
  
  # 修正: result_scoreの描画をdrawメソッドに移動
  @font.draw_text(@result_score, WIDTH/2 - 150, HEIGHT/2 - 50 , 1, 1.5, 1.5, Gosu::Color::RED) unless @result_score.empty?
 end

 def button_down(id)
  return if @ball_moving || @game_end_state
  
  # 修正: ゲームが終了したら結果表示画面へ
  if @round > 5
   result
   return
  end
  
  player_choice = nil
  case id
  when Gosu::KB_LEFT then player_choice = 0
  when Gosu::KB_UP then player_choice = 1
  when Gosu::KB_RIGHT then player_choice = 2
  when Gosu::KB_ESCAPE then @parent.close
  end

  if player_choice
   @kick_sound.play
   case player_choice
   when 0 then @ball_target_x = WIDTH/2 - 80
   when 1 then @ball_target_x = WIDTH/2
   when 2 then @ball_target_x = WIDTH/2 + 80
   end
   @ball_target_y = 110
   @ball_moving = true

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
   @message = "試合終了！ Enterで結果"
   @whistle_sound_end.play
  end

  @ball_x = WIDTH/2 + 6
  @ball_y = HEIGHT - 73
  @goalkeeper_choice = nil
 end

 def result
  if @goal_count >= 3
   @result_score = "あなたのスコア #{@score}\n  クリア！"
   @game_clear_sound.play
  else
   @result_score = "あなたのスコア #{@score}\n ゲームオーバー！"
   @game_over = true
  end
  
  # 修正: sleepを削除し、結果表示の待機状態に移行
  @game_end_state = true
 end
end