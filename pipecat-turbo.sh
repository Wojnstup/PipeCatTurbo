#! /bin/bash

## To use this you will need socat installed
socket_path="/tmp/mpvsocket"
list_file="$HOME/.pipecat_turbo_lists"

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

## Sets titles and urls to found playlists
search_playlist(){
	html=$( curl -s "$url${1//" "/"+"}""+content_type%3Aplaylist&page=1"  )

	titles=$( echo "$html" | grep '<p dir="auto">' | awk -F'<p dir="auto">' '{ print $2 }' | awk -F'</p>' '{ print $1 }' | grep -v "</b>" | grep -n "" )
	urls=$( echo "$html" | grep '<a style="width:100%" href=' | awk -F\" '{ print $4 }' )
}

## Sets titles and urls to playlist content - reused with channels
get_playlist_content(){
	echo $1
	html=$( curl -s "$video_url""$1" )

	titles=$( echo "$html" | grep '<p dir="auto">' | awk -F'<p dir="auto">' '{ print $2 }' | awk -F'</p>' '{ print $1 }' | grep -n "" )
	echo "$titles"
	urls=$( echo "$html" | grep '<a style="width:100%" href=' | awk -F\" '{ print $4 }' )
}

## Sets titles and urls found channels
search_channel(){
	html=$( curl -s "$url${1//" "/"+"}""+content_type%3Achannel&page=1" )

	titles=$( echo "$html" | grep '<p dir="auto">' | awk -F'<p dir="auto">' '{ print $2 }' | awk -F'</p>' '{ print $1 }' | grep -n "" ) 
	urls=$( echo "$html" | grep '<a href="/channel' | awk -F\" '{ print $2 }' | awk -F\/ '{ print $3 }' )
}

while :
do

	search_option=$( echo -e "Controlls\nVideo\nPlaylist\nChannel\nYour Lists\nAudio mode" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -p "Search option: " )
	
	if [[ $search_option == "Audio mode" ]]	
	then
		search_option=$( echo -e "Controlls\nVideo\nPlaylist\nChannel\nYour Lists\nAudio mode" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -p "Audio mode set: " )
		audio_mode="--no-video"
	fi

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

		if (( ${#choice}==0 ))
		then
			break
		fi
		
		echo quit | socat - /tmp/mpvsocket	
		notify-send "Playing '$choice'"
		echo "$choice" > /tmp/currently_playlist_pipecat
		choice=$( echo "$choice" | awk -F: '{ print $1 }' )

		## Get the url with index $choice and play it in mpv
		mpv $audio_mode  --input-ipc-server=$socket_path "$video_url$( echo "$urls" | sed -n $choice\p )"
		
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

		if [[ $choice == "" ]]
		then
			break
		fi
		
		echo quit | socat - /tmp/mpvsocket
		notify-send "Playing '$choice'"
		echo "$choice" > /tmp/currently_playlist_pipecat		

		choice=$( echo "$choice" | awk -F: '{ print $1 }' ) 
		## Get the url with index $choice and play it in mpv
		
		mpv $audio_mode --input-ipc-server=$socket_path "$video_url$( echo "$urls" | sed -n $choice\p )"
		
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
		echo $choice
		if [[ $choice == "" ]]
		then
			break
		fi
		
		echo quit | socat - /tmp/mpvsocket
		notify-send "Playing '$choice'"
		echo "$choice" > /tmp/currently_playlist_pipecat

		choice=$( echo "$choice" | awk -F: '{ print $1 }' )
		
		echo "$choice  <---------"
		## Get the url with index $choice and play it in mpv
		mpv $audio_mode --input-ipc-server=$socket_path "$video_url$( echo "$urls" | sed -n $choice\p )"
	elif [[ $search_option == "Controlls" ]]
	then
		currently_playing=$( cat /tmp/currently_playlist_pipecat )
		choice=$( echo -e "<<\n||\n>>\nX" | dmenu -sb '#98005d' -l 0 -fn "Terminus:bold:size:15" -h 27 -p "$currently_playing" ) 
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
			"X")
				echo "" > /tmp/currently_playlist_pipecat
				notify-send "Quitting..."
				echo quit | socat - /tmp/mpvsocket
				;;
		esac
	elif [[ $search_option == "Your Lists" ]]
	then
		## Make sure list file exists
		touch $list_file

		## Get contents of list file
		file=$( cat $list_file )

		## Extract list names and prompt user to choose a list
		list=$(cat "$HOME""/.pipecat_turbo_lists" | grep "####- START LIST" | awk -F\< '{ print $2 }' | awk -F\> '{ print $1 }' | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 )
		
		## Get the starting index and the file lenght of playlist file to get playlist starting and ending index in the next for loop. This should be done better than I did it but I'm so tired I just can't do it
		start_index=$( cat "$HOME""/.pipecat_turbo_lists" | grep -n "####- START LIST <$list>" | awk -F\: '{ print $1 }' )
		file_lenght=$( cat  "$HOME""/.pipecat_turbo_lists" | wc -l )
		
		for index in $( seq $file_lenght)
		do
			line=$( echo "$file" | sed -n $index\p )
			if (( $index > $start_index )) && [ "$line" = "####- END LIST -####" ]
			then
				break
			fi
		done
		
		## Extracting the urls between start_index and index - it should be named end_index or something but i juwst don't care anymore. This took 3 hours to implement. Never code while tired.
		content=$(echo "$file" | sed -n "$((start_index + 1)),$((index - 1))""p" )
		echo "$content" | awk '{ print $NF }' > /tmp/pipecat_list

		mpv $audio_mode --input-ipc-server=$socket_path --playlist=/tmp/pipecat_list
	fi
	break
done

