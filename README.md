# myMPD Maintain Stored Playlist Positions
Save current play position for stored playlists

For MPD 0.24 (stickers for stored playlists)

Configuration:  

Trigger 1:
Name: playlist_player
Trigger: Player (mpd_player)
Script: playlist
Script arguments: trigger=player

Trigger 2:
Name: playlist_queue
Trigger: Queue (mpd_queue)
Script: playlist
Script arguments: trigger=queue
