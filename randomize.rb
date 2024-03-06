#!/usr/bin/env ruby
# Randomizes audio files in a given directory.

require 'fileutils'
require 'open3'

class AudioFileRandomizer
  TIME_ADDED_MIN_DEFAULT = 5
  TIME_ADDED_MAX_DEFAULT = 10
  TIME_ADDED_DISABLE_DEFAULT = false
  FILE_PREFIX_DEFAULT = "file"

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
    :time_added_disabled, :randomized_directory, :output_directory,
    :file_prefix, :concat_file, :map_file

  def set_attributes
    @root_directory = validate_root_directory
    @time_added_min = validate_time_added[:min]
    @time_added_max = validate_time_added[:max]
    @time_added_disable = validate_time_added[:disable]
    @file_prefix = validate_file_prefix

    @randomized_directory = "#{root_directory}/Randomized"
    @output_directory =
      "#{randomized_directory}/#{Time.now.strftime("%Y%m%d_%H%M%S")}"

    @concat_file = "#{output_directory}/concat.txt"
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
    time_added_arr = ARGV[1].to_s.split(" ")
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

  def validate_file_prefix
    file_prefix = ARGV[2]

    if file_prefix.nil?
      prefix = FILE_PREFIX_DEFAULT
    else
      prefix = file_prefix
    end

    prefix
  end

  def time_added_disabled?
    @time_added_disable
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
        channels: find_channels(result),
        format: find_format(result),
        sample_rate: find_sample_rate(result),
        encoder: find_encoder(result),
      }
    end

    randomized_args = randomize(args)

    randomized_args.each_with_index do |args, i|
      create_random_audio_file(args, i)
    end
  end

  def find_channels(text)
    text.match(%r(Hz, ((\d+) channels|mono|stereo)))

    if $1 == "mono"
      channels = "mono"
    elsif $1 == "stereo"
      channels = "stereo"
    elsif $2.split(" ").last.to_i != 0
      channels = "stereo"
    end

    channels
  end

  def find_format(text)
    text.match(%r(format_name=([A-Za-z0-9]+)))

    $1
  end

  def find_sample_rate(text)
    text.match(%r((\d+) Hz))

    $1
  end

  def find_encoder(text)
    text.match(%r(Stream #0:0: Audio: (\w+).*,))

    $1
  end

  def audio_files
    Dir.glob("#{root_directory}/*")
  end

  def randomize(arr)
    randomized = []

    loop do
      element = arr.shuffle!.pop

      break if element.nil?

      randomized << element
    end

    randomized
  end

  def create_random_audio_file(args, idx)
    channels = args[:channels]
    format = args[:format]
    sample_rate = args[:sample_rate]
    encoder = args[:encoder]

    input_file = args[:input_file]
    output_file = "#{output_directory}/#{file_prefix}_#{idx + 1}.#{format}"

    if time_added_disabled?
      create_without_silence(input_file, output_file)
    else
      create_with_silence(
        input_file,
        output_file,
        channels,
        format,
        sample_rate,
        encoder,
      )
    end

    write_to_map(input_file, output_file)
  end

  def create_without_silence(input_file, output_file)
    FileUtils.cp(input_file, output_file)
  end

  def create_with_silence(
        input_file,
        output_file,
        channels,
        format,
        sample_rate,
        encoder
      )

    tmp_silence_file = "#{output_directory}/silence_tmp.#{format}"
    silence_file = "#{output_directory}/silence.#{format}"
    silence_time = rand(time_added_min..time_added_max).round(2)

    filter = "anullsrc=channel_layout=#{channels}:sample_rate=#{sample_rate}"
    cmd =
      %(ffmpeg -f lavfi -i #{filter} -t #{silence_time} '#{tmp_silence_file}')

    Open3.capture2e(cmd)

    # Re-encode with the correct encoder/sample format (i.e. bit depth)
    cmd =
      %(ffmpeg -y -i '#{tmp_silence_file}' -acodec #{encoder} '#{silence_file}')

    Open3.capture2e(cmd)

    write_to_concat(silence_file, input_file)

    concat(output_file)

    clean_up(tmp_silence_file, silence_file)
  end

  def write_to_concat(silence_file, input_file)
    File.open(concat_file, "a") do |f|
      f.write(%(file '#{silence_file}'\nfile '#{input_file}'))
    end
  end

  def concat(output_file)
    cmd = %(ffmpeg -f concat -safe 0 -i "#{concat_file}" -codec copy \
      "#{output_file}")

    Open3.capture2e(cmd)
  end

  def clean_up(tmp_silence_file, silence_file)
    File.delete(tmp_silence_file)
    File.delete(silence_file)
    File.delete(concat_file)
  end

  def write_to_map(input, output)
    input_basename = File.basename(input)
    output_basename = File.basename(output)

    File.open(map_file, "a") do |f|
      f.write("#{input_basename} → #{output_basename}\n")
    end
  end
end

AudioFileRandomizer.run_script
