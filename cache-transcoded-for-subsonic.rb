#!/usr/bin/ruby2.1
require 'pathname'
require 'shellwords'
require 'open3'
require 'fileutils'
require 'logger'
require 'securerandom'

# CONSTS(You can change them)

# Cache files placed CACHE_DIR. This directory will be structued like Maildir.
# First, a file being transcoded will be created in CACHE_DIR/tmp.
# Second, if transcoding finished, rename it to CACHE_DIR/new(Note that they must be on the same filesystem for atomic rename operation).
# Note that CACHE_DIR/cur does not exist because it is not needed that recording transcoded files is delivered.
CACHE_DIR = "/var/subsonic/cache"
LOG_FILE = "#{CACHE_DIR}/transcode.log"
FFMPEG = "/var/subsonic/transcode/ffmpeg"


################################################################################
# CONSTS(DO NOT CHANGE)
STATUS_STARTED = "started"
STATUS_FINISHED = "finished"

# INIT
FileUtils.makedirs(CACHE_DIR)
logger = Logger.new(LOG_FILE)
logger.info 'start'

# Parse command line
cmdline = ARGV
i = cmdline[cmdline.index('-i') + 1]
b_a = cmdline[cmdline.index('-b:a') + 1]
f = cmdline[cmdline.index('-f') + 1]

cache_file_tmp = Pathname.new("#{CACHE_DIR}/tmp/#{b_a}#{Pathname.new(i).parent}/#{Pathname.new(i).basename(".*")}.#{f}.#{SecureRandom.uuid}")
cache_file_new = Pathname.new("#{CACHE_DIR}/new/#{b_a}#{Pathname.new(i).parent}/#{Pathname.new(i).basename(".*")}.#{f}")

# Clean tmp file if Recieve specific signals.
trap(:INT) do
  cache_file_tmp.delete
end
trap(:TERM) do
  cache_file_tmp.delete
end

# Main
if cache_file_new.exist?
  STDOUT.binmode
  STDOUT.write(cache_file_new.read)
else
  cmdline[cmdline.index('-i') + 1] = Shellwords.shellescape(i)
  call = "#{FFMPEG} #{cmdline.join(' ')}"
  logger.info "call: #{call}"
  FileUtils.makedirs(cache_file_tmp.parent)
  cache_file_tmp.open('w').close    # touch
  Open3.popen3(call) do |stdin, stdout, stderr, wait_thr|
    stdin.close
    STDOUT.binmode
    out = cache_file_tmp.open('w')
    while (r = stdout.read(4096))
      out.write(r)
      STDOUT.write(r)
    end
    FileUtils.makedirs(cache_file_new.parent)
    File.rename(cache_file_tmp, cache_file_new)
    logger.info "finished"
    e = stderr.read
    logger.warn "stderr: #{e}" unless e.empty?
  end
end
logger.info "cache_file_new: #{cache_file_new}"
logger.info "cache_file_new stat: #{cache_file_new.stat.inspect}"
