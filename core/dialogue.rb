# frozen_string_literal: true
require 'gosu'

class Dialogue
  # 定数
  # TEXT_SPEED = 2 # この行は不要になります
  DIALOGUE_BOX_ALPHA = 180
  DIALOGUE_BOX_PADDING = 20
  TEXT_LINE_HEIGHT = 20
  TEXT_START_X = 40
  TEXT_START_Y_OFFSET = 110
  NEXT_TEXT_PROMPT_Y_OFFSET = 40
  PROMPT_TEXT = "Enterで次へ"

  attr_reader :is_finished

  def initialize(elements:, speaker_image:, dialogue_font:, sound_manager:, window:, text_speed: 2) # text_speed引数を追加
    @elements = elements
    @speaker_image = speaker_image
    @dialogue_font = dialogue_font
    @sound_manager = sound_manager
    @window = window
    @text_speed = text_speed # インスタンス変数として保存

    @is_finished = false
    @current_element_index = 0
    @current_char_index = 0
    @typewriter_timer = 0
    @displayed_text = ""

    # 現在処理している要素のタイプと内容を保持
    @current_element_type = nil
    @current_element_content = ""
  end
  
 def update # <--- このupdateメソッドが必要です
    return if @is_finished

    current_element = @elements[@current_element_index]
    return unless current_element

    case current_element[:type]
    when :text
      update_text_animation(current_element[:content])
    when :sound
      @sound_manager.play(current_element[:content])
      @current_element_index += 1
    end
    
    check_if_finished
  end

  def draw
    @window.draw_rect(DIALOGUE_BOX_PADDING, @window.height - 120, @window.width - 40, 100, Gosu::Color.rgba(0, 0, 0, DIALOGUE_BOX_ALPHA), 10)
    lines = @displayed_text.split("\n")
    lines.each_with_index do |line, index|
      @dialogue_font.draw_text(line, TEXT_START_X, @window.height - TEXT_START_Y_OFFSET + (index * TEXT_LINE_HEIGHT), 11, 1.0, 1.0, Gosu::Color::WHITE)
    end
    @dialogue_font.draw_text(PROMPT_TEXT, TEXT_START_X, @window.height - NEXT_TEXT_PROMPT_Y_OFFSET, 11, 1.0, 1.0, Gosu::Color::YELLOW) if @is_finished
  end

  def button_down(id)
    if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
      if @is_finished
        return true
      else
        skip_animation
      end
    end
    false
  end

  private

  def update_text_animation(full_text)
    @typewriter_timer += 1
    if @typewriter_timer >= @text_speed # ここで@text_speedを使うように変更
      if @current_char_index < full_text.length
        char = full_text[@current_char_index]
        @displayed_text += char
        @current_char_index += 1
        @typewriter_timer = 0
        @sound_manager.play("text_beep")
      else
        @current_element_type = nil
        @displayed_text += "\n"
      end
    end
  end

  def skip_animation
    @displayed_text = ""
    @elements[@current_element_index..-1].each do |elem|
      if elem[:type] == :text
        @displayed_text += elem[:content]
      end
    end
    @is_finished = true
  end

  def check_if_finished
    @is_finished = (@current_element_index >= @elements.length)
  end
end