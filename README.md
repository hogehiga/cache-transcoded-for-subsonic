# cache-transcoded-for-subsonic
## What is it?
This is a script for caching transcoded files on server-side, works with Subsonic 5.3.

## What is Subsonic?
A media streming server. Official site is <http://www.subsonic.org>.

## Motivation
When I play music on Subsonic web interface, it calls transcoding method every time. I want to reduce it because of reducing CPU load.

## Pros and cons
### Pros
- Reduce CPU load.
- Transferring of trasncoded files from server to client becomes faster if CPU was bottolneck.
- Once file is transcoded, other client benefit from it.

### Cons
- Use much disk space.
    - Current implementation requires transcoded files per bitrate. For example, transcoded files have path like: `${CACHE_DIR}/128k/${PATH_TO_ORIGINAL_FILE}`.

## How it works
Arrow represents stream of data or calling procedure.
### Before
    Client <---- GET /stream ----> Subsonic server <---- call and read results ----> ffmpeg <---- read and transcode --- file
### After
#### 1st time
     Client <---- GET /stream ----> Subsonic server <---- call and read results ----> cache-transcoded-for-subsonic.rb <---- call and cache ----> ffmpeg <---- read and transcode ---- file
#### 2nd time
     Client <---- GET /stream ----> Subsonic server <---- call and read results ----> cache-transcoded-for-subsonic.rb <---- read ---- cache file

## Install
### Requriements
- Subsonic 5.3 server(referred to as server).
- Root authority of server.
- Subsonic server's admin authority.
- Ruby 2.1 on server.

### Instructions
1. Download `cache-transcoded-for-subsonic.rb`, locate it to `/var/subsonic/transcode`, give running authority to user who running subsonic server.
1. Change `CACHE_DIR`, `TRANSCODE_STATUS_FILE`, `LOG_FILE`, `FFMPEG` in `cache-transcoded-for-subsonic.rb`. If server is Debian jessie, you don't need to change, maybe.
1. Login to subsonic as admin, follow [Settings]-[Transcoding], and change ffmpeg to cache-transcoded-for-subsonic.rb in [Step 1].
1. Login to subsonic as general user, play music, check if log file contains such as `... INFO -- : call: /var/subsonic/transcode/ffmpeg -threads 2 -i ...`.
