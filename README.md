# Scratchcc

Scratch to microcontroller crosscompiler.

This code has about a million things missing and is not easy to run. If you're
not scared away by this, feel free to try it, but drop me an email since I'm
actively changing things.

## GPIO access

GPIO access is currently done via a naming convention on Scratch variables.

Name            | Description                   | Supported values
----------------|-------------------------------|---------------------
`#outX`         | Digital out on pin `X`        | `HIGH`, `LOW`, 0, 1
`#inX`          | Digital in on pin `X          | `HIGH`, `LOW``
`#pwmX`         | Digital PWM output on pin `X` | 0 - 100 (Duty cycle)
`#ainX`         | Analog in on pin `X`          | 0 - 1023

## Block implementation status

See [Block Selectors](http://wiki.scratch.mit.edu/wiki/Scratch_File_Format_(2.0)/Block_Selectors)
for the official documentation.

Selector        | Block         | Supported?            | Notes
----------------|---------------|-----------------------|-------------------
-               | () - ()       | y                     |
*               | () * ()       | y                     |
/               | () / ()       | y                     |
&               | () and ()     | y                     |
%               | () Mod ()     | y                     |
+               | () + ()       | y                     |
<               | () < ()       | y                     |
=               | () = ()       | y                     |
>               | () > ()       | y                     |
|               | () or ()      | y                     |
abs             | Abs ()        | y                     |
answer          | Answer        | n                     |
append:toList:  | Add () to ()  | n                     |
backgroundIndex | Backdrop #    | n                     |
bounceOffEdge   | If on Edge, Bounce | n                |
broadcast:      | Broadcast ()  | n                     |
changeGraphicEffect:by: | Change () Effect by () | n    |
changePenHueBy: | Change Pen Color by () | n                     |
changePenShadeBy: | Change Pen Shade by () | n                     |
changePenSizeBy: | Change Pen Size by () | n                     |
changeSizeBy:   | Change Size by () | n                     |
changeTempoBy:  | Change Tempo by () |   y                     | Tempo is set per thread, but probably should be globel
changeVar:by:   | Change () by () | n                     |
changeVolumeBy: | Change Volume by () | n                     |
changeXposBy:   | Change X by () | n                     |
changeYposBy:   | Change Y by () | n                     |
clearPenTrails  | Clear | n                     |
CLR_COUNT       | Clear Counter | n                     |
color:sees:     | Color () is Touching ()? | n                     |
comeToFront     | Go to Front | n                     |
computeFunction:of: | () of () (Operators block) | n                     |
concatenate:with: | Join ()() | n                     |
contentsOfList: | () (List block) | n                     |
costumeIndex    | Costume # | n                     |
COUNT           | Counter | n                     |
createCloneOf   | Create Clone of () | n                     |
deleteClone     | Delete This Clone | n                     |
deleteLine:ofList: | Delete () of () | n                     |
distanceTo:     | Distance to () | n                     |
doAsk           | Ask () and Wait | n                     |
doBroadcastAndWait | Broadcast () and Wait | n                     |
doForever       | Forever |   y                     |
doForeverIf     | Forever If () | n                     |
doForLoop       | For Each () in () | n                     |
doIf            | If () Then                     | n                     |
doIfElse        | If () Then, Else | n                     |
doPlaySoundAndWait | Play Sound () Until Done | n                     |
doRepeat        | Repeat () | n                     |
doReturn        | Stop Script | n                     |
doUntil         | Repeat Until () | n                     |
doWaitUntil     | Wait Until () | n                     |
doWhile         | While () | n                     |
drum:duration:elapsed:from: | Play Drum () for () Beats | n                     |
filterReset     | Clear Graphic Effects | n                     |
forward:        | Move () Steps | n                     |
fxTest          | Color FX Test () | n                     |
getAttribute:of: | () of () (Sensing block) | n                     |
getLine:ofList: | Item () of () | n                     |
getUserId       | User ID | n                     |
getUserName     | Username | n                     |
glideSecs:toX:y:elapsed:from: | Glide () Secs to X: () Y: () | n                     |
goBackByLayers: | Go Back () Layers | n                     |
gotoSpriteOrMouse: | Go to () | n                     |
gotoX:y:        | Go to X: () Y: () | n                     |
heading         | Direction                     | n                     |
heading:        | Point in Direction () | n                     |
hide            | Hide | n                     |
hideAll         | Hide All Sprites | n                     |
hideList:       | Hide List () | n                     |
hideVariable:   | Hide Variable () | n                     |
INCR_COUNT      | Incr Counter | n                     |
insert:at:ofList: | Insert () at () of () | n                     |
instrument:     | Set Instrument to () | ignored | Ignored since the Arduino only makes square waves
isLoud          | Loud? | n                     |
keyPressed: | Key () Pressed? | n                     |
letter:of: | Letter () of () | n                     |
lineCountOfList: | Length of () (List block) | n                     |
list:contains: | () Contains () | n                     |
lookLike: | Switch Costume to () | n                     |
midiInstrument: | Set Instrument to () | n                     |
mousePressed | Mouse Down? | n                     |
mouseX | Mouse X | n                     |
mouseY          | MouseY                     | n                     |
nextCostume | Next Costume | n                     |
nextScene | Next Backdrop | n                     |
not | Not () | n                     |
noteOn:duration:elapsed:from: | Play Note () for () Beats |   y                     | Only one note can be played at a time; uses pin 6
obsolete        | Obsolete | n                     |
penColor:       | Set Pen Color to () | n                     |
penSize:        | Set Pen Size to () | n                     |
playDrum        | Play Drum () for () Beats | n                     |
playSound:      | Play Sound () | n                     |
pointTowards:   | Point Towards () | n                     |
putPenDown      | Pen Down                     | n                     |
putPenUp        | Pen Up | n                     |
randomFrom:to:  | Pick Random () to () | n                     |
readVariable    | () (Variables block) | n                     |
rest:elapsed:from: | Rest for () Beats |   y                     |
rounded | Round () | n                     |
say:            | Say () | y                     | Sends output to serial port followed by a new line
say:duration:elapsed:from: | Say () for () Secs | n                     |
sayNothing      | Say Nothing | n                     |
scale           | Size | n                     |
sceneName | Backdrop Name | n                     |
scrollAlign                     | Align Scene () | n                     |
scrollRight | Scroll Right () | n                     |
scrollUp | Scroll Up () | n                     |
senseVideoMotion                     | Video () on () | n                     |
sensor: | () Sensor Value | n                     |
sensorPressed: | Sensor ()? | n                     |
setGraphicEffect:to: | Set () Effect to () | n                     |
setLine:ofList:to: | Replace Item () of () With () | n                     |
setPenHueTo: | Set Pen Color to () | n                     |
setPenShadeTo: | Set Pen Shade to () | n                     |
setRotationStyle | Set Rotation Style () | n                     |
setSizeTo: | Set Size to ()% | n                     |
setTempoTo: | Set Tempo to () bpm |   y                     |
setVar:to: | Set () to () |   y                     | Only support GPIO outputs
setVideoState | Turn Video () | n                     |
setVideoTransparenc  y                     | Set Video Transparency to ()% | n                     |
setVolumeTo: | Set Volume to ()% | n                     |
show | Show | n                     |
showList: | Show List () | n                     |
showVariable: | Show Variable () | n                     |
soundLevel | Loudness | n                     |
sqrt | Sqrt () |   y                     |
stampCostume | Stamp | n                     |
startScene | Switch Backdrop to () | n                     |
startSceneAndWait | Switch Backdrop to () and Wait | n                     |
stopAll | Stop All | n                     |
stopAllSounds | Stop All Sounds | n                     |
stopScripts | Stop () | n                     |
stopSound: | Stop Sound () | n                     |
stringLength: | Length of () (Operators block) | n                     |
tempo | Tempo |   y                     |
think: | Think () | n                     |
think:duration:elapsed:from: | Think () for () Secs | n                     |
timeAndDate | Current () | n                     |
timer | Timer | n                     |
timerReset | Reset Timer | n                     |
timestamp | Days Since 2000 | n                     |
touching: | Touching ()? | n                     |
touchingColor: | Touching Color ()? | n                     |
turnAwayFromEdge | Point Away From Edge | n                     |
turnLeft: | Turn () Degrees | n                     |
turnRight: | Turn () Degrees | n                     |
undefined | Undefined | n                     |
volume | Volume | n                     |
wait:elapsed:from: | Wait () Secs |   y                     |
warpSpeed | All at Once | n                     |
whenClicked | When This Sprite Clicked | n                     |
whenCloned | When I Start as a Clone | n                     |
whenGreenFlag | When Green Flag Clicked |   y                     |
whenIReceive | When I Receive () | n                     |
whenKeyPressed | When () Key Pressed | n                     |
whenSceneStarts | When Backdrop Switches to () | n                     |
whenSensorGreaterThan                     | When () is Greater Than () | n                     |
xpos | X Position                     | n                     |
xpos: | Set X to () | n                     |
xScroll | X Scroll | n                     |
ypos | Y Position                     | n                     |
ypos: | Set Y to () | n                     |
yScroll | Y Scroll | n                     |
