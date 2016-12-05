#!/usr/bin/ruby2.1
require 'optparse'
require 'pathname'
require 'shellwords'
require 'open3'
require 'fileutils'
require 'logger'
require 'json'

# CONSTS(You can change them)
CACHE_DIR = "/var/subsonic/cache"
TRANSCODE_STATUS_FILE = "#{CACHE_DIR}/transcode-status.json"
LOG_FILE = "#{CACHE_DIR}/transcode.log"
FFMPEG = "/var/subsonic/transcode/ffmpeg"

# CONSTS
STATUS_STARTED = "started"
STATUS_FINISHED = "finished"

# INIT
FileUtils.makedirs(CACHE_DIR)
logger = Logger.new(LOG_FILE)
logger.info 'start'
transcode_status_file = Pathname.new(TRANSCODE_STATUS_FILE)
transcode_status_file.write(JSON.dump({})) unless transcode_status_file.exist?
transcode_status = JSON.parse(Pathname.new(TRANSCODE_STATUS_FILE).read)

# Parse command line
cmdline = ARGV
i = cmdline[cmdline.index('-i') + 1]
b_a = cmdline[cmdline.index('-b:a') + 1]
f = cmdline[cmdline.index('-f') + 1]

cache_file = Pathname.new("#{CACHE_DIR}/#{b_a}#{Pathname.new(i).parent}/#{Pathname.new(i).basename(".*")}.#{f}")

if transcode_status[cache_file.to_s] != STATUS_FINISHED
  cmdline[cmdline.index('-i') + 1] = Shellwords.shellescape(i)
  call = "#{FFMPEG} #{cmdline.join(' ')}"
  logger.info "call: #{call}"
  FileUtils.makedirs(cache_file.parent)
  cache_file.open('w').close    # touch
  Open3.popen3(call) do |stdin, stdout, stderr, wait_thr|
    transcode_status[cache_file.to_s] = STATUS_STARTED
    transcode_status_file.write(JSON.dump(transcode_status))
    stdin.close
    STDOUT.binmode
    out = cache_file.open('w')
    while (r = stdout.read(4096))
      out.write(r)
      STDOUT.write(r)
    end
    transcode_status[cache_file.to_s] = STATUS_FINISHED
    transcode_status_file.write(JSON.dump(transcode_status))
    logger.info "finished"
    e = stderr.read
    logger.warn "stderr: #{e}" unless e.empty?
  end
else
  STDOUT.binmode
  STDOUT.write(cache_file.read)
end
logger.info "cache_file: #{cache_file}"
logger.info "cache_file stat: #{cache_file.stat.inspect}"
