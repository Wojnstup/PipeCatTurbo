<p align="center">
  <img src="/screenshots/controlls.png">
</p>
<h1 align="center">▶️ Watch Youtube and listen to music with dmenu! 🎵</h1>

  <h2 color="#c4037a">Features:</h2>

  <ul>
    <li>Search for channels, playlists and videos</li>
    <li>Set video or audio only mode</li>
    <li>Shuffle through a playlst</li>
    <li>Create a local playlist</li>
    <li>Control your music with media controlls</li>
    <li>Don't ping Google, for privacy concerns</li>
  </ul>
  
  <h3 color="#c4037a">Hint! You propably want to set a keybinding for this script, otherwise you'll hate it!</h3>
  
  <h2 color="#c4037a">Select from several options in main menu</h2>
  <p align="center">
    <img src="/screenshots/main_menu.png">
  </p>
  
  <h2 color="#c4037a">Search and select your videos, playlists and channels!</h2>
  <p align="center">
    <img src="/screenshots/select.png">
  </p>
  
  <h2 color="#c4037a">Watch your favourite creators without pinging Google!</h2>
  <p align="center">
    <img src="/screenshots/video.png">
  </p>
  
  <h2 color="#c4037a">Categorize your music with local playlists!</h2>
  <p align="center">
    <img src="/screenshots/your_lists.png">
  </p>
  
  <h3 color="#c4037a">You can create local lists and append songs to them in dmenu, but also ~/.pipecat_turbo_lists has easy to edit syntax.</h3> 
  <p align="center">
    <img src="/screenshots/syntax.png">
  </p>
  
  <h3 color="#c4037a">How does it work?</h3>
  <ul>
    <li>The local playlists are stored in ~/.pipecat_turbo_lists file</li>
    <li>When launched, mpv creates a /tmp/mpvsocket file, so you can controll it or extract info from it with bash commands</li>
    <li>While playing playlists, the script creates a /tmp/pipecat_list file, so you can move forward or backwards in your queue</li>
    <li>All the info and videos are scraped from an <a href="https://github.com/iv-org/invidious">Invidious</a> instance somebody hosted, so you don't ping Google wihle being able to access all the Youtube content</li>
  </ul>
  
  <h3 color="#c4037a">Config and hacking?</h3>
  <p align="center">
    The script doesn't have a config file by default. If you want to create a config file, you do it in <span color="#c4037a">~/.config/pipecat_turbo.conf</span><br>
  The rest is explained in the comments in the script. 
</p>  

<h3 color="#c4037a">Example config - it's the one I use!</h3>
<p align="center">
  <img src="/screenshots/config.png">
</p>

  
  
  <h2 color="#c4037a">Dependencies:</h2>

  <ul>
    <li>mpv - for playing content</li>
    <li>libnotify - for notifications</li>
    <li>socat - for controlling mpv from dmenu</li>
    <li>dmenu - for having a menu (obviously)</li>
    <li>a link to working Invidious instance, if the ones provided go down <a href="https://docs.invidious.io/Invidious-Instances.md">use a different one</a></li>
   </ul>
   <h6>Disclaimer! I'm a begginer in bash and my coding skills leave much to be desired. This script works, but the code might be a little messy, for now.</h6>
