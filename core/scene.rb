# frozen_string_literal: true
require 'gosu'
require_relative 'dialogue'

class Scene
  attr_reader :is_finished

  def initialize(background:, dialogues_data:, window:)
    @background = background
    @window = window
    @dialogues = dialogues_data.map do |data|
      Dialogue.new(
        elements: data[:elements],
        speaker_image: data[:speaker_image],
        dialogue_font: data[:dialogue_font],
        sound_manager: data[:sound_manager],
        window: @window,
        text_speed: data[:text_speed] # ここでtext_speedを渡す
      )
    end
    @current_dialogue_index = 0
    @is_finished = false
  end


  def update
    current_dialogue.update if current_dialogue
  end

  def draw
    @background.draw(0, 0, 0)
    current_dialogue.draw if current_dialogue
  end

  def button_down(id)
    if current_dialogue && current_dialogue.button_down(id)
      @current_dialogue_index += 1
      if @current_dialogue_index >= @dialogues.length
        @is_finished = true
      end
    end
  end

  private

  def current_dialogue
    @dialogues[@current_dialogue_index]
  end
end