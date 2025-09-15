require 'gosu'

class JankenGame < Gosu::Window
  HANDS = ["グー", "チョキ", "パー"]
  RULES = ["勝ってください", "負けてください", "あいこしてください"]

  def initialize
    super(640, 480)
    self.caption = "制限時間つき 即出しじゃんけん"
    @font = Gosu::Font.new(32)

    reset_round
    @score = 0
    @time_limit = 3 # 秒
    @round_start = Gosu.milliseconds
    @message = ""
  end

  def update
    if Gosu.milliseconds - @round_start > @time_limit * 1000 && @message.empty?
      @message = "⏰ 時間切れ！失敗…"
    end
  end

  def draw
    @font.draw_text("お題: #{@rule}", 20, 20, 1)
    @font.draw_text("コンピュータ: #{HANDS[@computer]}", 20, 70, 1)
    @font.draw_text("操作: ← グー, ↓ チョキ, → パー", 20, 120, 1)
    @font.draw_text("残り時間: #{remaining_time}", 20, 170, 1)
    @font.draw_text("スコア: #{@score}", 20, 220, 1)
    @font.draw_text(@message, 20, 300, 1, 1, 1, Gosu::Color::RED) unless @message.empty?
  end

  def button_down(id)
    return if !@message.empty?

    case id
    when Gosu::KB_LEFT  then judge(0) # グー
    when Gosu::KB_DOWN  then judge(1) # チョキ
    when Gosu::KB_RIGHT then judge(2) # パー
    when Gosu::KB_ESCAPE then close
    end
  end

  def judge(player)
    result =
      if player == @computer
        "あいこ"
      elsif (player - @computer) % 3 == 1
        "勝ち"
      else
        "負け"
      end

    if (@rule == "勝ってください" && result == "勝ち") ||
       (@rule == "負けてください" && result == "負け") ||
       (@rule == "あいこしてください" && result == "あいこ")
      @message = "✅ 正解！ (#{result})"
      @score += 1
    else
      @message = "❌ 失敗… (#{result})"
    end
  end

  def button_up(id)
    # スペースで次のラウンドへ
    if id == Gosu::KB_SPACE && !@message.empty?
      reset_round
    end
  end

  private

  def reset_round
    @computer = rand(0..2)
    @rule = RULES.sample
    @round_start = Gosu.milliseconds
    @message = ""
  end

  def remaining_time
    remain = @time_limit - (Gosu.milliseconds - @round_start) / 1000
    remain > 0 ? remain : 0
  end
end

JankenGame.new.show
