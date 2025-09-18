# frozen_string_literal: true
require 'gosu'
require_relative 'scene'

class Story
  def initialize(scenes_data:, window:)
    @scenes = scenes_data.map do |data|
      Scene.new(
        background: data[:background],
        dialogues_data: data[:dialogues],
        window: window
      )
    end
    @current_scene_index = 0
  end

  def update
    current_scene.update if current_scene
  end

  def draw
    current_scene.draw if current_scene
  end

  def button_down(id)
    if current_scene && current_scene.button_down(id)
      @current_scene_index += 1
    end
  end

  def finished?
    @current_scene_index >= @scenes.length
  end

  private

  def current_scene
    @scenes[@current_scene_index]
  end
end
