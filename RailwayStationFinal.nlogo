; Copyright 2018 Mathew Hounsell, Institute of Sustainable Futures, University of Technology Sydney
; CC BY-NC-SA 3.0
; This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
; To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Definitions
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Maximum Train/Platform Length 12
globals [
  last_new_human_tick
  last_new_engine_tick
  last_move_tick
  next_carriage_delay
  dwelling_max
  random_y
]

breed [ engines engine ]
breed [ carriages carriage ]
breed [ humans human ]
breed [ flora florum ]

engines-own [
  dwell
]
carriages-own [
  load
]
turtles-own [
  human-state
  target
  kind
]

; ~~~~~~~~~~~~~~~~~~~~
; Reporting
; ~~~~~~~~~~~~~~~~~~~

to-report ticks-of-next-new-engine
  report last_new_engine_tick + engine-interval
end

to-report is-time-to-make-new-engine
  report ticks >= ticks-of-next-new-engine
end

to-report is-time-to-make-new-human
  let t ( human-interval )
  report ticks >= last_new_human_tick + t
end

to-report is-time-to-move
  report ticks >= last_move_tick + 2
end

to-report get-load-on-carriages
  if count engines < 1 [
    report 0
  ]
  let c 0
  ask carriages [ set c ( c + load ) ]
  report c
end

to-report can-platform-be-at-coord [ x ]
  report x > -13 and x < 0
end

to-report can-engine-be-at-coord [ x ]
  report x > -8
end

to-report can-next-stopping-engine-be-at-coord [ x ]
  let active-engine false
  ; no engine
  if count engines > 1 [
    ask engines [
      ; past station
      if xcor > -8 [
        set active-engine true
      ]
    ]
  ]
  if not active-engine [ report can-engine-be-at-coord x ]
  report x > -8
end

to-report coord-to-location [ x y ]
  if y = 3 and x > 25  [report "railway" ]
  if y = 1 and x > 25  [report "railway" ]
  if y = 8 and x > 25  [report "railway" ]
  if y = 10 and x > 25  [report "railway" ]
  if y = 15 and x > 25  [report "railway" ]
  if y = 17 and x > 25  [report "railway" ]
  if y = 22 and x > 25  [report "railway" ]
  if y = 24 and x > 25  [report "railway" ]
  if ((y >= 0 and y <= 4) or (y >= 7 and y <= 11) or (y >= 14 and y <= 18) or  (y >= 21 and y <= 25)) [ report "platform" ]
  if y = -1 or y = 5 or y = 6 or y = 12 or y = 13 or y = 19 or y = 20 or y = 26[ report "railway" ]

 ;;y = 1 or y = 3 or y = 4 or y = 6 or y = 7 or y = 9 or y = 10 or y = 12 or y = 13
 ;; y = 2 or y = 5 or y = 8 or y = 11 or y = 14
  if y = -2 and not can-platform-be-at-coord x [ report "dirt" ]
  if ( y = -2 or y = -3 ) and can-platform-be-at-coord x [ report "platform" ]
  if y < 0 and can-platform-be-at-coord x [ report "path" ]
  report "grass"
end

to-report tree-color [ v ]
  if v < 1.0 [ report red - 2 ]
  if v < 2.0 [ report orange - 1 ]
  if v < 3.0 [ report yellow - 1 ]
  report green - 3
end

to-report dwell-countdown
  let dwelling "-"
  if (count engines-on patch 0 -1) = 1 [
    ask engines [
      set dwelling dwell
    ]
  ]
  report dwelling
end

to-report engine-countdown
  if count engines < 1 [
    let t ( ticks-of-next-new-engine - ticks )
    if t < 0 [ report 0 ]
    report t
  ]
  report "-"
end

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Setup
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to startup
  setup
end

to setup
  clear-all
  reset-ticks
  set last_new_human_tick 0
  set last_new_engine_tick 0
  set last_move_tick 0
  set dwelling_max 20

  set-default-shape engines "train passenger engine"
  set-default-shape carriages "train passenger car"
  set-default-shape humans "person"
  set-default-shape flora "tree"
  resize-world -30 30 -30 30

  setup-patches
end

to setup-patches
  ask patches [
    let loc ( coord-to-location pxcor pycor )
    let grass ( green - 0.25 + random-float 1.5 )
    set pcolor ( ifelse-value (loc = "railway") [black] [ifelse-value (loc = "platform") [grey] [ifelse-value (loc = "dirt") [brown] [ifelse-value (loc = "path") [green] [grass]]]] )
  ]

end

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Running
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
to go
  every 0.1 / simulation-speed [
    ; let us set the tick rate at 10 fps
    ; then we shall assume that every tick is equivilant to 1 sec
    ; the fps is 24 so that it is a multiple of 8
    go-single
    tick
  ]
end

to go-single
  ;; not available in the web -> no-display ;; to keep the carriages moving as one

  ifelse count engines > 0 or count carriages > 0 [
    move-engines
  ] [
    set random_y one-of [-1 5 6 12 13 19 20 26]
    make-new-engine random_y
  ]
  make-new-carriage random_y  ; use the fact that the last carriage may have moved into the second square to test
  ;; not available in the web -> display

  move-humans
  make-new-human

end



; ~~~~~~~~~~~~~~~~~~~~
; Control
; ~~~~~~~~~~~~~~~~~~~~
to delay-next-engine [ duration ]
  set last_new_engine_tick ( last_new_engine_tick + duration )
end

; ~~~~~~~~~~~~~~~~~~~~
; Movement
; ~~~~~~~~~~~~~~~~~~~~
to move-engines
  let dwelling 0
  ask engines [
    ifelse not can-move? 1 [
      die
    ][
      set dwelling dwell
      ifelse dwell > 0 [
        set dwell dwell - 1
      ][
        fd 1
        if xcor = 0 [
          set dwell dwelling_max + 1
        ]
      ]
    ]
  ]
  foreach sort-on [ xcor ] carriages [ the-carriage -> ask the-carriage [
    ifelse not can-move? 1 [
      die
    ][
      if dwelling = 0 [
        fd 1
      ]
    ]
  ] ]
  ifelse dwelling > 1 [
    ask engines [ set color magenta ]
    ask carriages [ set color magenta ]
    if is-time-to-make-new-human [
      let carriage-y-coordinate ([ycor] of one-of carriages)
      let target_ 1
      if carriage-y-coordinate = 5 [
        set carriage-y-coordinate carriage-y-coordinate - 1
      ]
      if carriage-y-coordinate = -1 [
        set carriage-y-coordinate carriage-y-coordinate + 1
      ]
      if carriage-y-coordinate = 6 [
        set carriage-y-coordinate carriage-y-coordinate + 1
        set target_ 8
      ]
      if carriage-y-coordinate = 12 [
        set carriage-y-coordinate carriage-y-coordinate - 1
        set target_ 8
      ]
      if carriage-y-coordinate = 13 [
        set carriage-y-coordinate carriage-y-coordinate + 1
        set target_ 15
      ]
      if carriage-y-coordinate = 19 [
        set carriage-y-coordinate carriage-y-coordinate - 1
        set target_ 15
      ]
      if carriage-y-coordinate = 20 [
        set carriage-y-coordinate carriage-y-coordinate + 1
        set target_ 22
      ]
      if carriage-y-coordinate = 26 [
        set carriage-y-coordinate carriage-y-coordinate - 1
        set target_ 22
      ]
      create-humans 1 [
        setxy -7 carriage-y-coordinate
        set heading 270
        set color red
        set human-state "moving"
        set target target_
        set kind "leaving"
        set shape one-of [ "person business" "person construction" "person doctor" "person service" "person lumberjack" "person student" ]
      ]
    ]
  ][
    ask engines [ set color white ]
    ask carriages [ set color white ]
  ]
end

to move-a-human [ dwelling ]
  if human-state = "moving" [
    if kind = "boarding" [
      let newx (xcor - 1)
      if xcor >= -5 and xcor <= 30 [
        if xcor > 25 [
          if can-next-stopping-engine-be-at-coord newx and xcor > -5 and not any? turtles-on patch newx ycor [
            setxy newx ycor
            stop
          ]
        ]
        ; prefer going to target
        let newy ycor
        if ycor < target - 1[
          set newy ycor + 1
        ] if ycor > target + 1[
          set newy ycor - 1
        ]
        ;;goig up-target
        if can-next-stopping-engine-be-at-coord newx and xcor > -5 and not any? turtles-on patch newx newy [
          setxy newx newy
          stop
        ]
        ;;going left
        if can-next-stopping-engine-be-at-coord newx and xcor > -5 and not any? turtles-on patch newx ycor [
          setxy newx ycor
          stop
        ]
        ;;going down or up
        if can-next-stopping-engine-be-at-coord newx and xcor > -5 and not any? turtles-on patch xcor newy [
          setxy xcor newy
          stop
        ]
        if xcor <= -3 and (ycor = target + 1 or ycor = target - 1) [
          set human-state "waiting"
        ]
      ]
    ]
    if kind = "leaving" [
      let newx (xcor + 1)
      if xcor = 30 [
        die
      ]
      if xcor >= -8 and xcor < 30 [
        if xcor > 25 [
          if can-next-stopping-engine-be-at-coord newx and xcor > -5 and not any? turtles-on patch newx ycor [
            setxy newx ycor
            stop
          ]
        ]
        ; prefer going to target
        let newy ycor
        if ycor < target [
          set newy ycor + 1
        ] if ycor > target [
          set newy ycor - 1
        ]
        ;;goig up-target
        if can-next-stopping-engine-be-at-coord newx and xcor > -8 and not any? turtles-on patch newx newy [
          setxy newx newy
          stop
        ]
        ;;going right
        if can-next-stopping-engine-be-at-coord newx and xcor > -5 and not any? turtles-on patch newx ycor [
          setxy newx ycor
          stop
        ]
        ;;going down or up
        if can-next-stopping-engine-be-at-coord newx and xcor > -5 and not any? turtles-on patch xcor newy [
          setxy xcor newy
          stop
        ]
      ]
    ]
  ]

  if human-state = "waiting" [
    wait-for-carriage target
  ]
end

to wait-for-carriage [y]
  if any? carriages-on patch xcor (ycor + 1) [
    ask carriages with [ xcor = [xcor] of myself and ycor = [ycor + 1] of myself ] [
      set load load + 1
    ]
    die  ; or change state to represent that the human boarded the carriage
   ]
  if any? carriages-on patch xcor (ycor - 1) [
    ask carriages with [ xcor = [xcor] of myself and ycor = [ycor - 1] of myself ] [
      set load load + 1
    ]
    die  ; or change state to represent that the human boarded the carriage
   ]
end

to move-humans
  ifelse is-time-to-move [
    let dwelling 0
    ask engines with [ xcor = 0 ] [
      set dwelling dwell
    ]

    ; Move humans from specified x and y coordinates
    foreach (range -6 31 1) [x ->
      foreach (range -1 50 1) [ y ->
         ask humans with [ xcor = x and ycor = y and kind = "boarding" ] [
          move-a-human dwelling
        ]
      ]
    ]
    foreach (range 31 -8 -1) [x ->
      foreach (range -1 50 1) [ y ->
         ask humans with [ xcor = x and ycor = y and kind = "leaving"] [
          move-a-human dwelling
        ]
      ]
    ]
    set last_move_tick ticks
  ][
    ; Call move-a-human for waiting humans
    ask humans with [ human-state = "waiting" ] [
      move-a-human 0  ; The dwelling parameter can be ignored or adjusted as needed
    ]
  ]
end




; ~~~~~~~~~~~~~~~~~~~~
; Creation
; ~~~~~~~~~~~~~~~~~~~~
to make-new-human
  if is-time-to-make-new-human [
    set last_new_human_tick ticks
    let dir 0 ; ( floor ( random-float 1.9 ) ) * 180
    let x 30
    let y one-of [3 10 17 24]
    let target-options [-1 5]
    if y = 10 [
      set target-options [6 12]
    ]
    if y = 17 [
      set target-options [13 19]
    ]
    if y = 24 [
      set target-options [20 26]
    ]

    if dir = 180 [ set y max-pycor ]
    if (random-float 100 < human-frequency) and not any? turtles-on patch x y [
      create-humans 1 [
        setxy x y
        set heading 270
        set color cyan ; one-of [ yellow red blue orange cyan ]
        set shape one-of [ "person business" "person construction" "person doctor" "person service" "person lumberjack" "person student" ]
        set human-state "moving"
        set target one-of target-options
        set kind "boarding"
      ]
    ]
  ]
end

to make-new-carriage [var]
  if count carriages < carriage-length [
    if any? turtles-on patch (min-pxcor + 1) var [
      create-carriages 1 [
        setxy min-pxcor var
        set heading 90
        set color white
        set load 0
      ]
    ]
  ]
end

to make-new-engine [var]
  if count engines > 0 [ error "Asked to make a engine when one already exists." ]
  if is-time-to-make-new-engine [
    set last_new_engine_tick ticks
    create-engines 1 [
      setxy min-pxcor var
      set heading 90
      set color white ; one-of [ yellow red blue orange cyan ]
      set dwell 0
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
192
8
993
810
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-30
30
-30
30
0
0
1
ticks
24.0

BUTTON
7
8
90
43
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
104
8
187
43
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
103
46
187
80
Go Once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
1269
10
1743
292
Humans Outside
time (15 sec)
persons
0.0
10.0
0.0
10.0
true
false
"" "if ticks mod 15 != 0 [ stop ]"
PENS
"default" 1.0 0 -16777216 true "" "plot count humans"

MONITOR
1291
510
1384
555
NIL
count engines
20
1
11

MONITOR
1293
566
1386
611
NIL
count carriages
17
1
11

MONITOR
1613
511
1713
556
humans outside
count humans
17
1
11

MONITOR
1613
558
1713
603
humans inside
get-load-on-carriages
0
1
11

SLIDER
7
210
187
243
human-frequency
human-frequency
0
100
100.0
5
1
%
HORIZONTAL

SLIDER
8
130
188
163
engine-interval
engine-interval
0
600
0.0
60
1
seconds
HORIZONTAL

SLIDER
8
92
188
125
carriage-length
carriage-length
2
12
8.0
1
1
carriages
HORIZONTAL

SLIDER
7
173
188
206
human-interval
human-interval
1
30
12.0
1
1
seconds
HORIZONTAL

MONITOR
1436
513
1543
558
NIL
dwell-countdown
17
1
11

CHOOSER
7
323
186
368
simulation-speed
simulation-speed
0.125 0.25 0.5 1 2 4 8
3

BUTTON
6
257
95
291
delay train 60
delay-next-engine 60\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
1445
604
1554
649
NIL
engine-countdown
0
1
11

PLOT
1269
298
1743
483
Trains
time (15 sec)
trains
0.0
10.0
0.0
12.0
true
false
"" "if ticks mod 15 != 0 [ stop ]"
PENS
"engines" 1.0 0 -5298144 true "" "plot count engines"
"carriages" 1.0 0 -13345367 true "" "plot count carriages"

BUTTON
94
257
188
291
delay train 300
delay-next-engine 300
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

A model of persons waiting at a train station. The persons are arrive randomly and will be picked up periodically by a train consist.

## HOW IT WORKS

The simulation is designed to run at 1 updates per second. The tick control does control the speed of the simulation. See the SIMULATION-SPEED control.

### Trains
A train is made up of one engine and several carriages.

In most cities like Sydney, Australia the urban trains are made of Electric Multiple Units (EMU). The first and last carriage of a Sydney Waratah train has the driver cab and engine embedded in both the first and last carriages. The train can thus be driven in both directions from either end of the train. Although generally drivers should be in the forward cab. 

#### Engines
In this simulation an engine pulls the carriages. This simplifies the simulation as the engine is the master agent controlling the subordinate carriages. 

There can only be 0 or 1 engine. World wrap breaks the train logic.

Engines always stop past the end of the platform (at coordinate 0).

#### Carriages
Each carriage has a load and can accept one passenger at a time.

If there are carriages but no engine then the train is leaving the right side of the world.

### Humans
Humans arrive from the houses off the bottom of the world. Humans will travel up the path to the platform.

Humans will move up, up-left, up-right or right in order to be in front of a carriage. Humans will not move through another human, nor will they move backward. Humans will not enter the world if the path is full.

### Humans board carriages

When the engine is stopped, the carriages will dwell at the platform and one human per interval can board the train. The train will only well for 20 simulation updates (2 seconds of simulated time.) You can tell if a train is dwelling because it will turn magenta.

## HOW TO USE IT

### CONTROL

#### SETUP

Click 'Setup' to erase the current state and start again. 

#### GO

Click 'Go' to start or stop simulation from running continously. While the simulation is running the 'Go' button will be depressed. 

##### GO ONCE

To assist in your understanding you can step through individual ticks of the simulation. Stop the simulation is stopped and click the 'Go Once' button to progress the simulation just one update. _Note that humans only move as fast as HUMAN_INTERVAL and may not move for several updates._ 

#### SIMULATION-SPEED

Control the relative speed of the simulation. Choose speed from 8x, 4x, 2x, 1, 1/2, 1/4. 1/8.

#### DELAY TRAIN X

Click this button to increase the delay for the creation of the next engine by 60 or 300 seconds (in simulation time).

See ENGINE-INTERVAL and ENGINE-COUNTDOWN

### CONFIGURE

#### CARRIAGE-LENGTH 

The number of carriages that will follow the next engine. Range [2..12]. This variable will only impact the next train, not a current train. 

#### ENGINE-INTERVAL

The number of seconds (in simulation time) before the next engine is due to be created. 

See 'DELAY TRAIN X' and ENGINE-COUNTDOWN

#### HUMAN-INTERVAL and HUMAN-FREQUENCY

The interval is the number of seconds (in simulation time) before the next human might be created.

The frequency is the chance of a human being created this interval.

Some of the behaviour is easy to see with a 100% frequency and a lower interval. However to simulate random arrival a frequency less than 50% frequency is needed.

### INFORMATION

COUNT-ENGINES and COUNT-CARRIAGES gives you the count of engines and carriages at the last update. There is a plot on the right hand side labelled 'Trains' which records the number of engines (red) and the number of carriages (blue) over time.

### HUMANS-OUTSIDE and HUMANS-INSIDE
The number of humans on the current train are displayed a HUMANS-INSIDE. The number of humans on the path or platform are displayed as HUMANS-OUTSIDE.

On the right hand side of the display there is a plot of the number of humans outside over the simulated time. This plot tracks the number of humans queueing.

### ENGINE COUNTDOWN
The number of simulation updates until the next engine is created. If an engine exists this display is "-". 
If you 'DELAY TRAIN X' the countdown will increase.

### DWELL-COUNTDOWN
The number of simulation updates until the carriage door close and the engine departs,


## THINGS TO NOTICE

Trees make your city nicer.

## THINGS TO TRY

Make the HUMAN-INTERVAL 20 and the HUMAN-FREQUENCY 100, let four trains collect humans. Now delay the next train, what happen to the queue?


## EXPANDING THE MODEL
Increase the scale of the simulated time to be more realistic.


## COPYRIGHT AND LICENSE

Copyright 2018 Mathew Hounsell, Institute of Sustainable Futures, University of Technology Sydney

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person construction
false
0
Rectangle -7500403 true true 123 76 176 95
Polygon -1 true false 105 90 60 195 90 210 115 162 184 163 210 210 240 195 195 90
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Circle -7500403 true true 110 5 80
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -955883 true false 180 90 195 90 195 165 195 195 150 195 150 120 180 90
Polygon -955883 true false 120 90 105 90 105 165 105 195 150 195 150 120 120 90
Rectangle -16777216 true false 135 114 150 120
Rectangle -16777216 true false 135 144 150 150
Rectangle -16777216 true false 135 174 150 180
Polygon -955883 true false 105 42 111 16 128 2 149 0 178 6 190 18 192 28 220 29 216 34 201 39 167 35
Polygon -6459832 true false 54 253 54 238 219 73 227 78
Polygon -16777216 true false 15 285 15 255 30 225 45 225 75 255 75 270 45 285

person doctor
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true false 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

person lumberjack
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -2674135 true false 60 196 90 211 114 155 120 196 180 196 187 158 210 211 240 196 195 91 165 91 150 106 150 135 135 91 105 91
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -6459832 true false 174 90 181 90 180 195 165 195
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -6459832 true false 126 90 119 90 120 195 135 195
Rectangle -6459832 true false 45 180 255 195
Polygon -16777216 true false 255 165 255 195 240 225 255 240 285 240 300 225 285 195 285 165
Line -16777216 false 135 165 165 165
Line -16777216 false 135 135 165 135
Line -16777216 false 90 135 120 135
Line -16777216 false 105 120 120 120
Line -16777216 false 180 120 195 120
Line -16777216 false 180 135 210 135
Line -16777216 false 90 150 105 165
Line -16777216 false 225 165 210 180
Line -16777216 false 75 165 90 180
Line -16777216 false 210 150 195 165
Line -16777216 false 180 105 210 180
Line -16777216 false 120 105 90 180
Line -16777216 false 150 135 150 165
Polygon -2674135 true false 100 30 104 44 189 24 185 10 173 10 166 1 138 -1 111 3 109 28

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

train passenger car
false
0
Polygon -7500403 true true 15 206 15 150 15 135 30 120 270 120 285 135 285 150 285 206 270 210 30 210
Circle -16777216 true false 240 195 30
Circle -16777216 true false 210 195 30
Circle -16777216 true false 60 195 30
Circle -16777216 true false 30 195 30
Rectangle -16777216 true false 30 140 268 165
Line -7500403 true 60 135 60 165
Line -7500403 true 60 135 60 165
Line -7500403 true 90 135 90 165
Line -7500403 true 120 135 120 165
Line -7500403 true 150 135 150 165
Line -7500403 true 180 135 180 165
Line -7500403 true 210 135 210 165
Line -7500403 true 240 135 240 165
Rectangle -16777216 true false 5 195 19 207
Rectangle -16777216 true false 281 195 295 207
Rectangle -13345367 true false 15 165 285 173
Rectangle -2674135 true false 15 180 285 188

train passenger engine
false
0
Rectangle -7500403 true true 0 180 300 195
Polygon -7500403 true true 283 161 274 128 255 114 231 105 165 105 15 105 15 150 15 195 15 210 285 210
Circle -16777216 true false 17 195 30
Circle -16777216 true false 50 195 30
Circle -16777216 true false 220 195 30
Circle -16777216 true false 253 195 30
Rectangle -16777216 false false 0 195 300 180
Rectangle -1 true false 11 111 18 118
Rectangle -1 true false 270 129 277 136
Rectangle -16777216 true false 91 195 210 210
Rectangle -16777216 true false 1 180 10 195
Line -16777216 false 290 150 291 182
Rectangle -16777216 true false 165 90 195 90
Rectangle -16777216 true false 290 180 299 195
Polygon -13345367 true false 285 180 267 158 239 135 180 120 15 120 16 113 180 113 240 120 270 135 282 154
Polygon -2674135 true false 284 179 267 160 239 139 180 127 15 127 16 120 180 120 240 127 270 142 282 161
Rectangle -16777216 true false 210 115 254 135
Line -7500403 true 225 105 225 150
Line -7500403 true 240 105 240 150

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
