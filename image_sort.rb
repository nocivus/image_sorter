#!/usr/bin/env ruby

require 'awesome_print'
require 'exifr/jpeg'
require 'fileutils'

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

def process_images(paths)
  total_processed = 0
  total_skipped = 0
  paths.each do |path|
    filename = File.basename(path)
    info = EXIFR::JPEG.new(path)

    # Do we have date time information?
    time = info.date_time
    next unless time

    # If we do, create the necessary folder, if non existing
    year  = time.year.to_s
    month = time.strftime("%-m")
    new_folder = File.join(PHOTO_FOLDER_NAME, year, month)
    FileUtils.mkdir_p(new_folder)
    if File.exist?(File.join(new_folder, filename))
      total_skipped += 1
    else
      FileUtils.mv(path, new_folder)
      total_processed += 1
    end
  end
  ap "Processed #{total_processed} out of #{paths.count} images found. " \
     "Skipped for already existing: #{total_skipped}"
end

if $PROGRAM_NAME == __FILE__
  paths = find_images(ARGV[0])
  process_images(paths)
end
