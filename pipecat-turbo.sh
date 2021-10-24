#! /bin/bash

## To use this you will need socat installed
socket_path="/tmp/mpvsocket"


## This is major! These URLS redirect to a privacy-respecting YouTube fronted, so you don't even ping google!
url="https://iteroni.com/search?q="
video_url="https://iteroni.com"

IFS=$'\n'

###### Functions ######

## Sets titles and urls to search results
search_video(){
	html=$( curl -s "$url${1//" "/"+"}""+content_type%3Avideo&page=1" )
	
	titles=$( echo "$html" | grep '<p dir="auto">' | awk -F'<p dir="auto">' '{ print $2 }' | awk -F'</p>' '{ print $1 }' | grep -n "") 
	urls=$( echo "$html" | grep '<a style="width:100%" href=' | awk -F\" '{ print $4 }' )
}

search_playlist(){
	html=$( curl -s "$url${1//" "/"+"}""+content_type%3Aplaylist&page=1"  )

	titles=$( echo "$html" | grep '<p dir="auto">' | awk -F'<p dir="auto">' '{ print $2 }' | awk -F'</p>' '{ print $1 }' | grep -v "</b>" | grep -n "" )
	urls=$( echo "$html" | grep '<a style="width:100%" href=' | awk -F\" '{ print $4 }' )
}

get_playlist_content(){
	echo $1
	html=$( curl -s "$video_url""$1" )

	titles=$( echo "$html" | grep '<p dir="auto">' | awk -F'<p dir="auto">' '{ print $2 }' | awk -F'</p>' '{ print $1 }' | grep -n "" )
	urls=$( echo "$html" | grep '<a style="width:100%" href=' | awk -F\" '{ print $4 }' )
}

search_channel(){
	html=$( curl -s "$url${1//" "/"+"}""+content_type%3Achannel&page=1" )

	titles=$( echo "$html" | grep '<p dir="auto">' | awk -F'<p dir="auto">' '{ print $2 }' | awk -F'</p>' '{ print $1 }' | grep -n "" ) 
	urls=$( echo "$html" | grep '<a href="/channel' | awk -F\" '{ print $2 }' | awk -F\/ '{ print $3 }' )
}

while :
do

	search_option=$( echo -e "Video\nPlaylist\nChannel\nControlls" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -p "Search option: " )
	

	if [[ $search_option == "Video" ]]
	then
		## Searching for a video
		video=$( echo "" | dmenu -sb '#98005d' -l 0 -fn "Terminus:bold:size:15" -h 27	-p "Search for video:"  )
	
		##### TODO Check if user entered anything, if not prompt them again

		if [[ $video == 'quit' ]]
		then
			break
		fi
	
		## Retrieve $urls and $titles
		search_video "$video"

		## Let user select a title, then get index of that title
		choice=$( echo "$titles" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 )
		notify-send "Playing '$choice'"
		echo "$choice" > /tmp/currently_playlist_pipecat
		choice=$( echo "$titles" | grep -n "$choice" | awk -F: '{ print $1 }' )

		## Get the url with index $choice and play it in mpv
		mpv --input-ipc-server=$socket_path "$video_url$( echo "$urls" | sed -n $choice\p )"
	elif [[ $search_option == "Playlist" ]]
	then
		## Searching for a playlist
		playlist=$( echo "" | dmenu -sb '#98005d' -l 0 -fn "Terminus:bold:size:15" -h 27   -p "Search for a playlist:"  )

		search_playlist "$playlist"

		choice=$( echo "$titles" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 )
		choice=$( echo "$titles" | grep -n "$choice" | awk -F: '{ print $1 }' )
		choice=$( echo "$urls" | sed -n $choice\p )
			
		get_playlist_content "$choice"

		choice=$( echo "$titles" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 )

		notify-send "Playing '$choice'"
		echo "$choice" > /tmp/currently_playlist_pipecat		

		choice=$( echo "$titles" | grep -n "$choice" | awk -F: '{ print $1 }' ) 
		## Get the url with index $choice and play it in mpv
		
		mpv --input-ipc-server=$socket_path "$video_url$( echo "$urls" | sed -n $choice\p )"
		
	elif [[ $search_option == "Channel" ]]
	then
		## Searching for a channel
		channel=$( echo "" | dmenu -sb '#98005d' -l 0 -fn "Terminus:bold:size:15" -h 27   -p "Search for a channel:"  )

		search_channel "$channel"	

		choice=$( echo "$titles" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 )
		choice=$( echo "$titles" | grep -n "$choice" | awk -F: '{ print $1 }' )
		choice=$( echo "$urls" | sed -n $choice\p )
		choice=$( echo "/playlist?list=""$choice" )
		
		echo "$urls"

		get_playlist_content "$choice" 
		choice=$( echo "$titles" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 )

		notify-send "Playing '$choice'"
		echo "$choice" > /tmp/currently_playlist_pipecat

		choice=$( echo "$titles" | grep -n "$choice" | awk -F: '{ print $1 }' )
		## Get the url with index $choice and play it in mpv
		mpv --input-ipc-server=$socket_path "$video_url$( echo "$urls" | sed -n $choice\p )"
	elif [[ $search_option == "Controlls" ]]
	then
		currently_playing=$( cat /tmp/currently_playlist_pipecat )
		choice=$( echo -e "<<\n||\n>>" | dmenu -sb '#98005d' -l 0 -fn "Terminus:bold:size:15" -h 27 -p "$currently_playing" ) 
		case $choice in
			"<<")
				echo playlist-prev | socat - /tmp/mpvsocket
				;;
			"||")
				echo cycle pause | socat - /tmp/mpvsocket
				;;
			">>")
				echo playlist-next | socat - /tmp/mpvsocket
				;;
		esac

	fi
	break
done

