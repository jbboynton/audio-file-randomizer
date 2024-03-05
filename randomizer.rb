#!/usr/bin/env ruby
# Randomizes audio files in a given directory.

class AudioFileRandomizer
  TIME_ADDED_MIN_DEFAULT = 5
  TIME_ADDED_MAX_DEFAULT = 10
  TIME_ADDED_DISABLE_DEFAULT = false

  class << self
    def run_script
      new.call
    end
  end

  def call
    set_attributes_from_args
  end

  private

  attr_reader :directory, :time_added_min, :time_added_max, :time_added_disabled

  def set_attributes_from_args
    @directory = validate_directory
    @time_added_min = validate_time_added[:min]
    @time_added_max = validate_time_added[:max]
    @time_added_disable = validate_time_added[:disable]
  end

  def validate_directory
    directory = ARGV[0]

    unless File.directory?(directory)
      message = %(Could not open directory: "#{directory}")

      raise ArgumentError, message
    end

    directory
  end

  def validate_time_added
    time_added_arr = ARGV[1].split(" ")
    time_added = {}
    defaults = {
      min: TIME_ADDED_MIN_DEFAULT,
      max: TIME_ADDED_MAX_DEFAULT,
      disable: TIME_ADDED_DISABLE_DEFAULT,
    }

    if time_added_arr.empty?
      time_added = defaults
    elsif time_added_arr == ["0"]
      time_added = { disable: true }
    else
      time_added = {
        min: time_added_arr[0].to_i,
        max: time_added_arr[1].to_i,
      }
    end

    defaults.merge(time_added)
  end
end

AudioFileRandomizer.run_script
