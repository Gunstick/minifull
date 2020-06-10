#!/bin/bash
hatarisav=.autohatari.sav
hataricfg=.autohatari.cfg
if [ "$1" = "" ]
then
  echo "usage: $0 filename"
  exit 1
fi
if [ ! -f "$hatarisav" ]
then
  rm "$hatarisav"
  awk -v ahs="$hatarisav" -v pwd="$PWD" '
       /bAutoSave =/{$3="FALSE"}
       /szMemoryCaptureFileName =/{$3=ahs}
       /szAutoSaveFileName =/{$3=ahs}
       /szHardDiskDirectory =/ {$3=pwd}
       /EnableDriveA =/{$3="FALSE"}
       /EnableDriveB =/{$3="FALSE"}
       {print}' ~/.hatari/hatari.cfg > "$hataricfg"
  hatari --drive-a off --drive-b off -c "$hataricfg" &
  sleep 2.8  # this is the time TOS needs to start reading AUTO 
  xdotool key ISO_Level3_Shift+k 
  sleep 1
  kill -9 $!
  # now we have a nice save file
  # tell hatari to use it at each start
  sed -i 's/bAutoSave = FALSE/bAutoSave = TRUE/' "$hataricfg"
  cp "$hatarisav" "$hatarisav".bak   # save it for each use
  mkdir AUTO
fi

filebase="${1%.*}"
firstrun=1
export SDL_VIDEO_WINDOW_POS="0,0"
while true
do
  if [ "${filebase}.s" -nt "${filebase}.tos" ] || [ $firstrun -eq 1 ]
  then
    firstrun=0
    killall -9 hatari;
    result=$(make ${filebase} 2>&1)  
    if [ $? -ne 0 ]
    then
      echo "ASSEMBLER ERROR"
      echo
      echo "$result" |
      awk '/vasmm68k_mot/{next}
	   /Volker Barthelmann/{next}
	   /ColdFire cpu backend/{next}
	   /motorola syntax module/{next}
	   /output module/{next}
          {print "VASM: " $0}'
      sleep 1
    else
      echo "$result"|grep -i -e data -e code -e bss
      ls -l ${filebase}.tos
      rm AUTO/*   # clean AUTO
      cp ${filebase}.tos AUTO/${filebase}.prg   # copy exec
      xy=$(xdotool getmouselocation|sed 's/x://;s/y://;s/ screen.*$//')
#      hatari --drive-a off --drive-b off ${filebase}.tos 2>&1| 
      cp "$hatarisav".bak "$hatarisav"  # get the savestate back
      hatari -c "$hataricfg" |
        awk '/No GEMDOS dir/{next}
	     /GEMDOS HDD emulation/{next}
	     /Hatari v[0-9.]*, compiled on:/{next}
             {print "HATARI "$0}' &
      while [ "$(xdotool getmouselocation|sed 's/x://;s/y://;s/ screen.*$//')" = "$xy" ]
      do   # wait for mouse to be moved by hatari
	echo .
        sleep 0.2
      done
      sleep 0.2  # wait a little more
      xdotool mousemove $xy    # move mouse back
      WID=$(xdotool search --onlyvisible --name '^hatari')
      xdotool windowmove $WID 0 0    # move hatari window to top left corner
    fi
  fi
  inotifywait "${filebase}.s" >/dev/null 2>&1
done
