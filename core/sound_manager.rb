# frozen_string_literal: true
require 'gosu'

class SoundManager
  def initialize
    @sounds = {}
    sound_files = Dir.glob('./assets/sounds/*.{wav,mp3}')
    sound_files.each do |file|
      sound_name = File.basename(file, '.*').to_sym
      
      @sounds[sound_name] = Gosu::Sample.new(file)
    end
  end

  def play(sound_name)
    #puts sound_name.to_sym
    sound = @sounds[sound_name.to_sym]
    sound&.play
  end
end