#!/usr/bin/env ruby
# Randomizes audio files in a given directory.

require 'open3'

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
    set_attributes
    create_output_directories
    process_files
  end

  private

  attr_reader :root_directory, :time_added_min, :time_added_max,
    :time_added_disabled, :randomized_directory, :output_directory, :map_file

  def set_attributes
    @root_directory = validate_root_directory
    @time_added_min = validate_time_added[:min]
    @time_added_max = validate_time_added[:max]
    @time_added_disable = validate_time_added[:disable]

    @randomized_directory = "#{root_directory}/randomized"
    @output_directory =
      "#{randomized_directory}/#{Time.now.strftime("%y%m%d_%H%M%S")}"

    @map_file = "#{output_directory}/map.txt"
  end

  def validate_root_directory
    directory = ARGV[0]

    unless File.directory?(directory)
      message = %(Could not open directory: "#{directory}")

      raise(ArgumentError, message)
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

  def create_output_directories
    Dir.mkdir(randomized_directory) unless File.directory?(randomized_directory)
    Dir.mkdir(output_directory) unless File.directory?(output_directory)
  end

  def process_files
    args = []

    audio_files.each do |f|
      next if File.directory?(f)

      result, _ = Open3.capture2e(%(ffprobe "#{f}" -show_format))

      args << {
        input_file: f,
        format: find_format(result),
        sample_rate: find_sample_rate(result),
      }
    end
  end

  def find_format(text)
    text.match(%r(format_name=([A-Za-z0-9]+)))

    $1
  end

  def find_sample_rate(text)
    text.match(%r((\d+) Hz))

    $1
  end

  def audio_files
    Dir.glob("#{root_directory}/*")
  end
end

AudioFileRandomizer.run_script
