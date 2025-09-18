# frozen_string_literal: true
require 'gosu'

class Dialogue
  # 定数
  DIALOGUE_BOX_ALPHA = 180
  DIALOGUE_BOX_PADDING = 20
  TEXT_LINE_HEIGHT = 20
  TEXT_START_X = 40
  TEXT_START_Y_OFFSET = 110
  NEXT_TEXT_PROMPT_Y_OFFSET = 40
  PROMPT_TEXT = "Enterで次へ"
  
  attr_reader :is_finished

  def initialize(content:, background:, speaker_image:, dialogue_font:, sound_manager:, text_speed:, sound_content:, await_input:, window:)
    @full_content = content
    @background = background
    @speaker_image = speaker_image
    @dialogue_font = dialogue_font
    @sound_manager = sound_manager
    @text_speed = text_speed
    @sound_content = sound_content
    @await_input = await_input # 新しいインスタンス変数
    @window = window
    
    @is_finished = false
    @current_char_index = 0
    @typewriter_timer = 0
    @displayed_text = ""
  end

  def finished?
    @is_finished
  end

  def await_input?
    @await_input
  end

  def update
    return if @is_finished
    update_text_animation
  end

  def draw
    @background.draw(0, 0, 0)
    @window.draw_rect(DIALOGUE_BOX_PADDING, @window.height - 120, @window.width - 40, 100, Gosu::Color.rgba(0, 0, 0, DIALOGUE_BOX_ALPHA), 10)
    lines = @displayed_text.split("\n")
    lines.each_with_index do |line, index|
      @dialogue_font.draw_text(line, TEXT_START_X, @window.height - TEXT_START_Y_OFFSET + (index * TEXT_LINE_HEIGHT), 11, 1.0, 1.0, Gosu::Color::WHITE)
    end
    @dialogue_font.draw_text(PROMPT_TEXT, TEXT_START_X, @window.height - NEXT_TEXT_PROMPT_Y_OFFSET, 11, 1.0, 1.0, Gosu::Color::YELLOW) if @is_finished && @await_input
  end

  def button_down(id)
    if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
      if @is_finished
        # 文字表示が完了し、入力待ちの場合はtrueを返す
        @await_input ? true : false
      else
        # 文字表示が未完了の場合はアニメーションをスキップ
        skip_animation
        return false
      end
    end
  end

  private

  def update_text_animation
    @typewriter_timer += 1
    if @typewriter_timer >= @text_speed
      if @current_char_index < @full_content.length
        char = @full_content[@current_char_index]
        @displayed_text += char
        @current_char_index += 1
        @typewriter_timer = 0
        @sound_manager.play(@sound_content)
      else
        @is_finished = true
      end
    end
  end

  def skip_animation
    @displayed_text = @full_content
    @is_finished = true
  end
end