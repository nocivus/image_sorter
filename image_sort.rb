#!/usr/bin/env ruby

require 'awesome_print'
require 'exifr/jpeg'
require 'fileutils'
require "date"

PHOTO_FOLDER_NAME = "photos".freeze

def find_images(folder)
  paths = []
  folder ||= "."
  Dir.glob("#{folder}/**/*.{jpg,jpeg}") do |path|
    begin
      next unless path.downcase =~ /.*\.jpg|jpeg$/
    rescue ArgumentError
      next
    end

    paths << path
  end
  paths
end

def try_parse(time, format)
  Date.strptime(time, format)
rescue
  false
end

def parse_time(time)
  return time if time.is_a?(Time) || time.is_a?(Date) || time.is_a?(DateTime)

  time = try_parse(time, "%Y:%m:%d %H:%M:%S")
  time = try_parse(time, "%d/%m/%Y %H:%M") unless time

  time
end

def move_file(time, path)
  filename = File.basename(path)
  parsed_time = parse_time(time)
  unless parsed_time 
    puts "Could not parse time: #{time}"
    return :failed
  end
  year  = parsed_time.year.to_s
  month = parsed_time.strftime("%m")
  new_folder = File.join(PHOTO_FOLDER_NAME, year, month)

  # Create folder if non existing
  FileUtils.mkdir_p(new_folder)

  # Skip if file exists
  return :skipped if File.exist?(File.join(new_folder, filename))

  # Otherwise move the file
  FileUtils.mv(path, new_folder)
  :processed
rescue StandardError => e
  ap time
  raise e
end

def process_images(paths)
  totals = { processed: 0, skipped: 0, failed: 0 }

  paths.each do |path|
    begin
      # Do we have date time information?
      info = EXIFR::JPEG.new(path)
      time = info.date_time
      next unless time
	
      # Move file (or attempt to)
      result = move_file(time, path)
      totals[result] += 1
    rescue EXIFR::MalformedJPEG
      puts "Malformed image: #{path}"
    end
  end

  ap "Processed #{totals[:processed]} out of #{paths.count} images found. " \
     "Skipped for already existing: #{totals[:skipped]}. " \
     "Failed: #{totals[:skipped]}."
end

if $PROGRAM_NAME == __FILE__
  paths = find_images(ARGV[0])
  process_images(paths)
end
