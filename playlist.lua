-- {"order":1,"file":"","version":0,"arguments":["trigger"]}
local mpd_host = "minipc"
local mpd_port = 6600

function mpd_command(command)
  local cmd = "echo '" .. command .. "' | nc -N " .. mpd_host .. " " .. mpd_port
  return mympd.os_capture(cmd)
end

function value_for(line, key)
  local key_str = key .. ": "
  if line:sub(1, #key_str) == key_str then
    return line:sub(#key_str+1, -1)
  end
  return nil
end

function value_sticker_for(line, sticker)
  local sticker_str = "sticker: " .. sticker .. "="
  if line:sub(1, #sticker_str) == sticker_str then
    return line:sub(#sticker_str+1, -1)
  end
  return nil
end

function mpd_playlists()
  ret = {}
  local output = mpd_command("listplaylists")
  for line in output:gmatch("([^\n]*)\n?") do
    local playlist = value_for(line, "playlist")
    if playlist then
      table.insert(ret, playlist)
    end
  end
  return ret
end

function mpd_playlist_first_song(playlist)
  local cmd = "listplaylist \"" .. playlist .. "\" 0"
  local output = mpd_command(cmd)
  for line in output:gmatch("([^\n]*)\n?") do
    local file = value_for(line, "file")
    if file then
      return file
    end
  end
  return nil
end

function mpd_queue_first_song()
  local cmd = "playlistinfo 0"
  local output = mpd_command(cmd)
  for line in output:gmatch("([^\n]*)\n?") do
    local file = value_for(line, "file")
    if file then
      return file
    end
  end
  return nil
end

function mpd_playlist_len(playlist)
  local cmd = "playlistlength \"" .. playlist .. "\""
  local output = mpd_command(cmd)
  for line in output:gmatch("([^\n]*)\n?") do
    local songs = value_for(line, "songs")
    if songs then
      return tonumber(songs)
    end
  end
  return nil
end

function mpd_queue_len()
  local cmd = "status"
  local output = mpd_command(cmd)
  for line in output:gmatch("([^\n]*)\n?") do
    local songs = value_for(line, "playlistlength")
    if songs then
      return tonumber(songs)
    end
  end
  return nil
end

function mpd_current_playlist()
  local cmd = "status"
  local output = mpd_command(cmd)
  for line in output:gmatch("([^\n]*)\n?") do
    local playlist = value_for(line, "lastloadedplaylist")
    if playlist then
      return playlist
    end
  end
  return nil
end

function mpd_current_playlist_old()
  local queue_first_song = mpd_queue_first_song()
  local queue_len = mpd_queue_len()
  for i, playlist in ipairs(mpd_playlists()) do
    local playlist_first_song = mpd_playlist_first_song(playlist)
    if playlist_first_song == queue_first_song then
      local playlist_len = mpd_playlist_len(playlist)
      if playlist_len == queue_len then
        return playlist
      end
    end
  end
  return nil
end

function mpd_play_position(position)
  print("mpd_play_position " .. position)
  local cmd = "play " .. position
  local output = mpd_command(cmd)
  return nil
end

function mpd_get_playlist_sticker(playlist, sticker)
  print("mpd_get_playlist_sticker " .. playlist .. " " .. sticker)
  local cmd = "sticker get playlist \"" .. playlist .. "\" " .. sticker
  local output = mpd_command(cmd)
  for line in output:gmatch("([^\n]*)\n?") do
    local value = value_sticker_for(line, sticker)
    if value then
      return value
    end
  end
  return nil
end

function mpd_set_playlist_sticker(playlist, sticker, value)
  print("mpd_set_playlist_sticker " .. playlist .. " " .. sticker .. "=" .. value)
  local cmd = "sticker set playlist \"" .. playlist .. "\" " .. sticker .. " "  ..value
  local output = mpd_command(cmd)
  return nil
end

function mympd_set_variable(p_key, p_value)
  print("mympd_set_variable " .. p_key .. "=" .. p_value)
  mympd.api("MYMPD_API_SCRIPT_VAR_SET", { key = p_key, value = tostring(p_value) })
end

function mympd_delete_variable(p_key)
  print("mympd_delete_variable " .. p_key)
  mympd.api("MYMPD_API_SCRIPT_VAR_DELETE", { key = p_key })
end

-- main
if mympd_arguments.trigger == "queue" then
  print("queue")
  if mympd_env.var.playlist_current_playlist then
    mpd_set_playlist_sticker(mympd_env.var.playlist_current_playlist, "position", mympd_env.var.playlist_current_position)
  end
  mympd_delete_variable("playlist_current_playlist")
  mympd_delete_variable("playlist_current_position")
  return "end queue"
end

if mympd_arguments.trigger == "player" then
  print("player")

  mympd.init()

  local play_state = mympd_state.play_state
  local elapsed_time = mympd_state.elapsed_time
  local song_pos = mympd_state.song_pos
  local queue_length = mympd_state.queue_length

  if play_state == 2 and song_pos == 0 and elapsed_time < 5 then
    print("starting new playlist")
    local current_playlist = mpd_current_playlist()
    if current_playlist then
      print("found playlist " .. current_playlist)
      mympd_set_variable("playlist_current_playlist", current_playlist)
      mympd_set_variable("playlist_current_position", song_pos)
      local position = mpd_get_playlist_sticker(current_playlist, "position")
      if position then
        position = tonumber(position)
        print("found position sticker: " .. position .. ", queue_length: " .. queue_length)
        if position > 0 and position+1 < queue_length then
          mpd_play_position(position)
        end
      else
        print("position sticker not found")
      end
    else
      print("stored playlist not found")
    end
  end

  -- on stop save pos to playlist sticker
  if play_state == 3 and song_pos > 0 and mympd_env.var.playlist_current_playlist then
    mpd_set_playlist_sticker(mympd_env.var.playlist_current_playlist, "position", mympd_env.var.playlist_current_position)
  end

  -- on play save pos to var
  if play_state == 2 and song_pos > 0 and mympd_env.var.playlist_current_playlist then
    print("playing stored playlist " .. song_pos)
    mympd_set_variable("playlist_current_position", song_pos)
  end

  return "end player"
end

print("end unknown " .. mympd_arguments.trigger)
return "end unknown " .. mympd_arguments.trigger

print("end unknown " .. mympd_arguments.trigger)
return "end unknown " .. mympd_arguments.trigger
