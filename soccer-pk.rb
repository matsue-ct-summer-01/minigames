require 'gosu'

class PKGame < Gosu::Window
  DIRECTIONS = ["左", "中央", "右"]

  def initialize
    super(640, 480)
    self.caption = "サッカー PK対決"
    @font = Gosu::Font.new(32)
    @score = 0
    @round = 1
    @message = "←:左 ↑:中央 →:右 でシュート！"
    @result = ""
  end

  def update
    # 終了条件：5回シュート後
    if @round > 5 && @message.start_with?("試合終了")
      # 何もしない
    end
  end

  def draw
    @font.draw_text("ラウンド: #{@round} / 5", 20, 20, 1)
    @font.draw_text("スコア: #{@score}", 20, 70, 1)
    @font.draw_text(@message, 20, 150, 1)
    @font.draw_text(@result, 20, 220, 1, 1, 1, Gosu::Color::YELLOW) unless @result.empty?
    if @round > 5
      @font.draw_text("試合終了！ あなたの得点: #{@score} 点", 20, 300, 1, 1, 1, Gosu::Color::GREEN)
      @font.draw_text("ESCキーで終了", 20, 360, 1)
    end
  end

  def button_down(id)
    return if @round > 5

    player_choice = nil
    case id
    when Gosu::KB_LEFT  then player_choice = 0
    when Gosu::KB_UP    then player_choice = 1
    when Gosu::KB_RIGHT then player_choice = 2
    when Gosu::KB_ESCAPE then close
    end

    if player_choice
      goalkeeper = rand(0..2)
      if player_choice == goalkeeper
        @result = "🥅 キーパーが#{DIRECTIONS[goalkeeper]}に飛んだ！セーブされた！"
      else
        @result = "⚽ ゴール！！ #{DIRECTIONS[player_choice]}に決めた！"
        @score += 1
      end
      @round += 1
      if @round <= 5
        @message = "←:左 ↑:中央 →:右 でシュート！"
      else
        @message = "試合終了"
      end
    end
  end
end

PKGame.new.show
