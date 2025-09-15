#仮置き
require 'gosu'

require_relative 'scenes/menu_scene'
require_relative 'scenes/shooter_scene'

WINDOW_WIDTH  = 600
WINDOW_HEIGHT = 300

class MainWindow < Gosu::Window
  def initialize
    super(WINDOW_WIDTH, WINDOW_HEIGHT)
    self.caption = "Game Collection"

    # 最初はメニューシーンから
    @scene = MenuScene.new(self)
  end

  def update
    @scene.update
  end

  def draw
    @scene.draw
  end

  def button_down(id)
    @scene.button_down(id)
  end

  # シーンを切り替える
  def switch_scene(new_scene)
    @scene = new_scene
  end
end

MainWindow.new.show
