#! /bin/bash

## To use this you will need socat installed
socket_path="/tmp/mpvsocket"
list_file="$HOME/.pipecat_turbo_lists"

## This is major! These URLS redirect to a privacy-respecting YouTube fronted, so you don't even ping google! If iteroni is down, try yewtu.be, if yewtu.be is down, try iteroni
## This uses invidious, that is self hosted. You can even host it on your own and use this script that way. Just replace these urls
url="https://iteroni.com/search?q="
video_url="https://iteroni.com"
#url="https://yewtu.be/search?q="
#video_url="https://yewtu.be"
sed_url="https\:\/\/yewtu.be"
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
	urls=$( echo "$html" | grep '<a style="width:100%" href=' | awk -F\" '{ print $4 }' )

	echo "URLS""$urls"
}

## Sets titles and urls found channels
search_channel(){
	html=$( curl -s "$url${1//" "/"+"}""+content_type%3Achannel&page=1" )

	titles=$( echo "$html" | grep '<p dir="auto">' | awk -F'<p dir="auto">' '{ print $2 }' | awk -F'</p>' '{ print $1 }' | grep -n "" ) 
	urls=$( echo "$html" | grep '<a href="/channel' | awk -F\" '{ print $2 }' | awk -F\/ '{ print $3 }' )
}

add_to_list(){
	file=$( cat $list_file )
	start_index=$( cat "$HOME""/.pipecat_turbo_lists" | grep -n "####- START LIST <$1>" | awk -F\: '{ print $1 }' )
	file_lenght=$( cat  "$HOME""/.pipecat_turbo_lists" | wc -l )
	if [[ -z $start_index ]]
		then
		echo "doesn't exist"
		break
	fi

	for index in $( seq $file_lenght)
	do
		line=$( echo "$file" | sed -n $index\p )
		if (( $index > $start_index )) && [ "$line" = "####- END LIST -####" ]
		then
			break
		fi
	done
	
	echo "$( cat "$HOME""/.pipecat_turbo_lists" | sed "$index"'i'"$2" )" > $list_file
}



###### MAIN ######
while :
do
	## First menu that pops up
	search_option=$( echo -e "Controlls\nSearch\nAudio mode\nShuffle mode\nYour Lists\nList tools" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -p "Option: " )

	## This while loop makes sure you can set both audio mode and shuffle mode at the same time
	while [[ "$search_option" == "Audio mode" ]] || [[ "$search_option" == "Shuffle mode" ]]
	do
		## If you selected Audio Mode, relaunch the menu in audio mode
		if [[ $search_option == "Audio mode" ]]	
		then
			search_option=$( echo -e "Controlls\nSearch\nAudio mode\nShuffle mode\nYour Lists\nList tools" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -p "Audio mode set: " )
			audio_mode="--no-video"
		fi
		
		## If you selected Shuffle Mode, relaunch the menu in shuffle mode
		if [[ $search_option == "Shuffle mode" ]]
		then
			search_option=$( echo -e "Controlls\nSearch\nAudio mode\nShuffle mode\nYour Lists\nList tools" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -p "Shuffle mode set: " )
			shuffle_mode="--shuffle"
		fi
	done

	## If user selected List tools, ask them waht they want to do with their lists
	if [[ $search_option == "List tools" ]]
	then
		search_option=$( echo -e "Add to list\nCreate new list" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -p "List tools:" )
	fi

	## If you selected add to list, relaunch the menu in add to list mode
	if [[ $search_option == "Add to list" ]]
	then
		list=$(cat "$HOME""/.pipecat_turbo_lists" | grep "####- START LIST" | awk -F\< '{ print $2 }' | awk -F\> '{ print $1 }' | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 )
		search_option=$( echo -e "Video\nPlaylist\nChannel" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -p "Find what you want to add: " )
		add_to_list="True"
	fi

	## If user selected Search, prompt them to choose what they are searching for
	if [[ $search_option == "Search" ]]
	then
		search_option=$( echo -e "Video\nPlaylist\nChannel" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -p "Search on youtube: " )
	fi
	
	#### THE MAIN IF STATEMENT
	if [[ $search_option == "Video" ]]
	then
		## Searching for a video
		video=$( echo "" | dmenu -sb '#98005d' -l 0 -fn "Terminus:bold:size:15" -h 27	-p "Search for video:"  )
	
		## Don't search for empty string
		if [[ -z $video ]]
		then
			break
		fi
	
		## Retrieve $urls and $titles
		search_video "$video"

		## Let user select a title, then get index of that title
		choice=$( echo "$titles" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 )

		if [[ -z $choice ]]
		then
			break
		fi
		
		## EXTREMELY IMPORTANT! When option set to add to list, add to list and break out of the loop	
		if [[ -v add_to_list ]]
		then
			title="$choice"
			choice=$( echo "$choice" | awk -F: '{ print $1 }' )
			
			full_link=$( echo $video_url$( echo "$urls" | sed -n $choice\p ))
			add_to_list "$list" "$title"' '$full_link
			break
		fi	
		
		## Stop other instances of mpv running
		echo quit | socat - /tmp/mpvsocket	
		notify-send "Playing '$choice'"

		## Transform choice into choice index
		choice=$( echo "$choice" | awk -F: '{ print $1 }' )

		## Get the url with index $choice and play it in mpv
		mpv $audio_mode  --input-ipc-server=$socket_path "$video_url$( echo "$urls" | sed -n $choice\p )"
		
	elif [[ $search_option == "Playlist" ]]
	then
		## Searching for a playlist
		playlist=$( echo "" | dmenu -sb '#98005d' -l 0 -fn "Terminus:bold:size:15" -h 27   -p "Search for a playlist:"  )

		## Don't search for empy string
		if [[ -z $playlist ]]
		then
			break
		fi

		search_playlist "$playlist"
		
		## Prompt user to select a playlist, then get the playlists's URL
		choice=$( echo "$titles" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 )
		choice=$( echo "$titles" | grep -n "$choice" | awk -F: '{ print $1 }' )
		choice=$( echo "$urls" | sed -n $choice\p )
			
		## Get contents of playlist with url
		get_playlist_content "$choice"
		
		## Prompt user to select a video/song from playlist
		choice=$( echo "$titles" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 -i )

		## EXTREMELY IMPORTANT! When option set to add to list, add to list and break out of the loop
		if [[ -v add_to_list ]]
		then
			title="$choice"
		        choice=$( echo "$choice" | awk -F: '{ print $1 }' )
			full_link=$( echo $video_url$( echo "$urls" | sed -n $choice\p | awk -F"&list" '{ print $1 }' ))
			add_to_list "$list" "$title"' '$full_link
			break
		fi

		
		if [[ $choice == "" ]]
		then
			break
		fi
		
		## Stop other instances of mpv running
		echo quit | socat - /tmp/mpvsocket
		notify-send "Playing '$choice'"

		## Transform choice into choice index
		choice=$( echo "$choice" | awk -F: '{ print $1 }' ) 

		## Throw contents of playlist into a file, then play this playlist starting from index in mpv
		echo "$urls" | sed "s/^/$sed_url/" | awk -F"&list" '{ print $1 }' > /tmp/pipecat_list
		mpv $audio_mode $shuffle_mode  --input-ipc-server=$socket_path -playlist=/tmp/pipecat_list --playlist-start=$((choice - 1))
		
	elif [[ $search_option == "Channel" ]]
	then
		## Searching for a channel
		channel=$( echo "" | dmenu -sb '#98005d' -l 0 -fn "Terminus:bold:size:15" -h 27   -p "Search for a channel:"  )

		## Don't search for empty string
		if [[ -z $channel ]]
		then
			break
		fi

		search_channel "$channel"	
		
		## Prompt user to select a channel, then get url of this channel's uploads playlist
		choice=$( echo "$titles" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 -i)
		choice=$( echo "$titles" | grep -n "$choice" | awk -F: '{ print $1 }' )
		choice=$( echo "$urls" | sed -n $choice\p )
		choice=$( echo "/playlist?list=""$choice" )
		
		get_playlist_content "$choice" 

		## Make urls not stupid, 'cause for some god forsaken reason they don't want to work if you don't do this
		urls=$( echo "$urls" | awk -F"&list" '{ print $1 }' )

		## Prompt user to choose a video from a channel
		choice=$( echo "$titles" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 -i )

		## EXTREMELY IMPORTANT! When option set to add to list, add to list and break out of the loop
		if [[ -v add_to_list ]]
		then
			title="$choice"
			choice=$( echo "$choice" | awk -F: '{ print $1 }' )
			full_link=$( echo $video_url$( echo "$urls" | sed -n $choice\p ))
			add_to_list "$list" "$title"' '$full_link
			break
		fi

		if [[ $choice == "" ]]
		then
			break
		fi
		
		## Stop other mpv instances from running	
		echo quit | socat - /tmp/mpvsocket
		notify-send "Playing '$choice'"

		## Transform choice into choice index
		choice=$( echo "$choice" | awk -F: '{ print $1 }' )
		
		## Get the url with index $choice and play it in mpv
		mpv $audio_mode --input-ipc-server=$socket_path "$video_url$( echo "$urls" | sed -n $choice\p )"
	elif [[ $search_option == "Controlls" ]]
	then
		## Bad, bad, bad, bad
		currently_playing=$( echo '{ "command": ["get_property", "media-title"] }' | socat - /tmp/mpvsocket | awk -F\" '{ print $4 }' )

		## Prompt user to choose an action
		choice=$( echo -e "||\nUp\nDown\n<<\n>>\nX" | dmenu -sb '#98005d' -l 0 -fn "Terminus:bold:size:15" -h 27 -p "$currently_playing" ) 
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
			"Up")
				echo add volume 10 | socat - /tmp/mpvsocket
				;;
			"Down")
				echo add volume -10 | socat - /tmp/mpvsocket
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
		list=$(cat "$HOME""/.pipecat_turbo_lists" | grep "####- START LIST" | awk -F\< '{ print $2 }' | awk -F\> '{ print $1 }' | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 -i )
	
		## Get the starting index and the file lenght of playlist file to get playlist starting and ending index in the next for loop. This should be done better than I did it but I'm so tired I just can't do it
		echo $list
		start_index=$( cat "$HOME""/.pipecat_turbo_lists" | grep -n "####- START LIST <$list>" | awk -F\: '{ print $1 }' )
		file_lenght=$( cat  "$HOME""/.pipecat_turbo_lists" | wc -l )
		
		## If for some reason there's no starting index, break
		if [[ -z $start_index ]]
		then
			echo "doesn't exist"
			break
		fi
		
		## This for loop checks for the nearest END LIST block
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

		## Get all titles from playlist
		titles=$(echo "$content" | awk '{$NF=""; print $0}') 

		## Prompt user to choose the starting position
		play_index=$( echo "$titles" | grep -n "" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -l 10 -i | awk -F\: '{print $1}' )

		## If user didn't choose anything, break
		if [[ -z $play_index ]]
		then
			break
		fi

		## Placing playlist urls into a /tmp file
		echo "$content" | awk '{ print $NF }' > /tmp/pipecat_list

		## Play playlist from given position
		echo quit | socat - /tmp/mpvsocket
		mpv $audio_mode  $shuffle_mode --input-ipc-server=$socket_path --playlist=/tmp/pipecat_list --playlist-start=$(( play_index - 1 ))

			
	elif [[ $search_option == "Create new list" ]]
	then
		list_name=$( echo "" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -p "Enter your list name" )
		
		## If user didn't enter enaything, break
		if [[ -z $list_name ]]
		then
			break
		fi

		## Check if playlist already exists
		lists=$(cat "$HOME""/.pipecat_turbo_lists" | grep "####- START LIST <""$list_name""> -####" )
		if [[ -v lists ]]
		then
			echo "Ok" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -p "Playlist already exists"
			break
		fi

		## Check if playlist contains illegal characters
		if [[ $list_name == *"<"* ]] || [[ $list_name == *">"* ]] || [[ $list_name == *"\n"* ]]
		then
			echo "Ok" | dmenu -sb '#98005d' -fn "Terminus:bold:size:15" -h 27 -p "Playlist name can't use < or > or \\n"
			break
		fi

		echo -e "####- START LIST <""$list_name""> -####\n####- END LIST -####" >> $list_file 
	fi
	break
done

