# frozen_string_literal: true
require 'gosu'

class SoundManager
  def initialize
    @sounds = {}
    load_sounds
  end

  def play(sound_name, volume = 0.3)
    sound = @sounds[sound_name.to_sym]
    if sound
      sound.play(volume)
    else
      puts "Warning: Sound not found: #{sound_name}"
    end
  end

  private

  def load_sounds
    # assets/sounds 以下のmp3ファイルを自動的にロード
    Dir.glob("assets/sounds/*.mp3").each do |file_path|
      sound_name = File.basename(file_path, ".*").to_sym
      begin
        @sounds[sound_name] = Gosu::Sample.new(file_path)
      rescue => e
        puts "Error loading sound file #{file_path}: #{e.message}"
      end
    end
  end
end