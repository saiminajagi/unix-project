function display {
    DATA[0]="    #    ######   #     #    #    #     #   ####   ####### #####  "
    DATA[1]="   # #   #     #  #    #    # #   ##    #  #    #     #    #    # "
    DATA[2]="  #   #  #     #  #   #    #   #  # #   # #      #    #    #     #"
    DATA[3]=" #     # ######   ####    #     # #  #  # #      #    #    #     #"
    DATA[4]=" ####### #    #   #   #   ####### #   # # #      #    #    #     #"
    DATA[5]=" #     # #     #  #    #  #     # #    ##  #    #     #    #    # "
    DATA[6]=" #     # #      # #     # #     # #     #   ####   ####### #####  "
    echo


    # virtual coordinate system is X*Y ${#DATA} * 8
    ## This is to put the title in the centre

    REAL_OFFSET_X=$(($((`tput cols` - 56)) / 2))
    REAL_OFFSET_Y=$(($((`tput lines` - 6)) / 2))

    draw_char() {
      stty -echo
        V_COORD_X=$1
        V_COORD_Y=$2

        tput cup $((REAL_OFFSET_Y + V_COORD_Y)) $((REAL_OFFSET_X + V_COORD_X))

        printf %c ${DATA[V_COORD_Y]:V_COORD_X:1}
    }

    trap 'exit 1' INT TERM 

    tput civis
    clear
    while :; do
        for ((c=1; c <= 7; c++)); do
            tput setaf $c
            for ((x=0; x<${#DATA[0]}; x++)); do
                for ((y=0; y<=6; y++)); do
                    draw_char $x $y
                done
            done
        done
        sleep 1
        clear
        break
    done
}

display


stty -echo

# Init output
OLD_IFS="$IFS"
IFS= 

DELAY=0.15

tput civis
clear

SCREEN_WIDTH=$(tput cols)
SCREEN_HEIGHT=$(($(tput lines) - 1))
WIDTH=$((40 % (SCREEN_WIDTH - 2)))
HEIGHT=$((14 % (SCREEN_HEIGHT - 2)))

HALF_WIDTH=$((WIDTH/2))
HALF_HEIGHT=$((HEIGHT/2))

TOP=$(((SCREEN_HEIGHT - HEIGHT) / 2))
LEFT=$(((SCREEN_WIDTH - WIDTH) / 2))
BOTTOM=$((TOP + HEIGHT))
RIGHT=$((LEFT + WIDTH))

STATE='stop'

plateX=$((LEFT + HALF_WIDTH))
plateW=5
plateS=""

ballY=$((BOTTOM - 1))
ballX=$((LEFT + HALF_WIDTH + plateW / 2))
ballDY=-1
ballDX=-1
ballColors=(52 88 124 160 196)
currentColor=1
ballChar="0"
state="stop"
lifes=39767

bricks=()

function putBrik {
  index=1$1\0$2           #6854354645
  briks[$index]=1
  tput cup $1 $2
  echo '+'
}

function drawBricks {
 for (( row = $((TOP + 2)); row <= $((TOP + 7)); row++ ))
  do
    for (( column = $((LEFT + 3)); column <= $((RIGHT - 3)); column++ ))
    do
      if [ $(($column % 3)) == 0 ]
      then
        tput setaf 83
        putBrik $row $column
      fi
    done
  done 

  
}

function drawBorder {
  tput setaf 244
  tput cup $((TOP - 5)) $((LEFT + 5))
  echo "         _               _   _ "
  tput cup $((TOP - 4)) $((LEFT + 5))
  echo " ___ ___| |_ ___ ___ ___|_|_| |"
  tput cup $((TOP - 3)) $((LEFT + 5))
  echo "| .'|  _| '_| .'|   | . | | . |"
  tput cup $((TOP - 2)) $((LEFT + 5))
  echo "|__,|_| |_,_|__,|_|_|___|_|___|"

  line=""
  tput setaf 241
  for (( column = 0; column <= WIDTH; column++ ))
  do
    line+="~"
  done
  tput cup $((TOP - 1)) $LEFT
  echo $line
  tput cup $BOTTOM $LEFT
  echo $line

  for (( row = 0; row <= HEIGHT; row++ ))
  do
    tput cup $((TOP + row)) $((LEFT - 1))
    echo "|"
    tput cup $((TOP + row)) $((RIGHT + 1))
    echo "|"
  done

  tput cup $((BOTTOM + 2)) $LEFT
  echo "   Press 'h' or 'l' to start playing"
}

function clearBall {
  tput cup $ballY $ballX
  echo " "
}

function drawBall {
  tput setaf ${ballColors[$currentColor]}
  tput cup $ballY $ballX
  echo $ballChar

  #currentColor=$(($currentColor + 1))
  
}

function resetBall {
  clearBall
  ballY=$((BOTTOM - 1))
  ballX=$((plateX + plateW / 2))
  ballDY=-1
  ballDY=-1
  drawPlate
  drawBall
}

function move {
  (sleep $DELAY && kill -ALRM $$) &

  if [ $state != 'playing' ]
  then

    return
  fi

  clearBall
  ballY=$((ballY + ballDY))
  ballX=$((ballX + ballDX))

  if [ $ballX -gt $RIGHT ] || [ $ballX -lt $LEFT ]
  then
    ballDX=$((-ballDX))
    ballX=$((ballX + ballDX ))
  fi

  if [ $ballY -lt $TOP ]
  then
    ballDY=$((-ballDY))
    ballY=$((ballY + ballDY ))
  fi

  if [ $ballY -gt $((BOTTOM - 1)) ]
  then
    if [ $ballX -le $((plateX + plateW)) ] && [ $ballX -ge $plateX ]
    then
      #ballX=$((plateX + plateW / 2))
      ballDY=$((-ballDY))
      ballY=$((ballY + ballDY + ballDY))
      drawPlate
    else
      resetBall
      drawBorder
      state='stop'
      lifes=$((lifes - 1))
    fi
  fi

  index=1$ballY\0$ballX
  if [ ${briks[$index]} ] && [ ${briks[$index]} == 1 ]
  then
    tput cup $ballY $ballX
    drawBall
    clearBall
    ballDY=$((-ballDY))
    ballY=$((ballY))
    briks[$index]=0
  fi

  drawBall
  tput setaf 7
  tput cup $((BOTTOM + 2)) $LEFT
  if [ $lifes -gt 0 ]
  then
    echo "Lifes: " $lifes "                       "
  else
    echo "Game over                            "
    exitGame
  fi
}

function calcPlateS {
  plateS=" +"
  for (( i = 0; i < $((plateW - 2)); i++ ))
  do
    plateS+="-"
  done
  plateS+="+ "
}

function drawPlate {
  tput setaf 2
  tput cup $((BOTTOM - 1)) $((plateX - 1))
  echo $plateS
  if [ $plateX == $LEFT ]
  then
    tput setaf 241
    tput cup $((BOTTOM - 1)) $((plateX - 1))
    
  fi
}

function exitGame {
  echo "Goodbye!"
  trap exit ALRM
    tput cnorm
  IFS="$OLD_IFS"
  stty echo
  exit 0
}

function startGame {
  if [ $lifes -ge 0 ]
  then
    state='playing'
  else
    state='gameOver'
  fi
}

trap move ALRM
calcPlateS
drawBricks
drawBorder
drawBall
drawPlate
resetBall
move

while :
do
  read -s -n 1 key

  case "$key" in
    h)
      if [ $state == 'stop' ]
      then
        ballDX=-1
        startGame
      else
        if [ $plateX -gt $LEFT ]
        then
          plateX=$((plateX - 1))
          drawPlate
          drawBall
        fi
      fi
    ;;
    l)
      if [ $state == 'stop' ]
      then
        ballDX=1
        startGame
      else
        if [ $plateX -lt $((RIGHT - $plateW)) ]
        then
          plateX=$((plateX + 1))
          drawPlate
          drawBall
        fi
      fi
    ;;
    q)
      exitGame
    ;;
  esac
 
 
 
done
