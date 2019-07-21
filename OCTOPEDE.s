	DSK OCTOPEDE
	

**************************************************
* Setup
*	pede coords to 0,0
*	player to center, bottom
* 	draw mushrooms - how many? how to randomize?


* Do each frame:
*	read joystick
*	update player position
*	if button and not already firing, create missile
*	if already firing, update missile row
*	if missile new position is non-blank, collision
*		
*	update pede positions.
*	if pede new position is non-blank, collision
*	interframe delay based on "score" 
	




**************************************************
* Variables
**************************************************

ROW				EQU		$FA			; row/col in text screen
COLUMN			EQU		$FB
CHAR			EQU		$FC			; char/pixel to plot

CURRENTPEDE		EQU		$0F			; 0-F which segment to operate on

PLOTROW			EQU		$FE			; row/col in text page
PLOTCOLUMN		EQU		$FF

CH				EQU		$24			; cursor Horiz
CV				EQU		$25			; cursor Vert

WNDWDTH			EQU		$21			; Width of text window


RNDSEED			EQU		$EA			; +eb +ec

PEDEDELAY		EQU		$CE			; how many frames to delay the pede's walking
PEDECOUNTER		EQU		$CD			; how many frames to delay the pede's walking

SHROOMCOUNT		EQU		$CC			; how many mushrooms to start with

PEDEBYTE		EQU		$1D			; 1 bit per segment

MISSILEDELAY	EQU		$1E			; dropping block column

PLAYERCOLUMN	EQU		$09			; Where is the player shooting from?
PLAYERROW		EQU		$0A			; Where is the player shooting from?
PLAYERDELAY		EQU		$40			; how quick to move the player

PROGRESS 		EQU		$FD			; cleared pedes

**************************************************
* Apple Standard Memory Locations
**************************************************
CLRLORES     EQU   $F832
LORES        EQU   $C050
TXTSET       EQU   $C051
MIXCLR       EQU   $C052
MIXSET       EQU   $C053
TXTPAGE1     EQU   $C054
TXTPAGE2     EQU   $C055
KEY          EQU   $C000
C80STOREOFF  EQU   $C000
C80STOREON   EQU   $C001
STROBE       EQU   $C010
SPEAKER      EQU   $C030
VBL          EQU   $C02E
RDVBLBAR     EQU   $C019		;not VBL (VBL signal low
WAIT		 EQU   $FCA8 
RAMWRTAUX    EQU   $C005
RAMWRTMAIN   EQU   $C004
SETAN3       EQU   $C05E		;Set annunciator-3 output to 0
SET80VID     EQU   $C00D		;enable 80-column display mode (WR-only)
HOME 		 EQU   $FC58		; clear the text screen
VTAB         EQU   $FC22		; Sets the cursor vertical position (from CV)
COUT         EQU   $FDED		; Calls the output routine whose address is stored in CSW,
								;  normally COUTI

STROUT		EQU   $DB3A 		;Y=String ptr high, A=String ptr low

ALTTEXT		EQU	$C055
ALTTEXTOFF	EQU	$C054


PB0			EQU		$C061		; paddle 0 button. high bit set when pressed.
PDL0		EQU		$C064		; paddle 0 value, or should I use PREAD?
PREAD		EQU		$FB1E

ROMINIT      EQU    $FB2F
ROMSETKBD    EQU    $FE89
ROMSETVID    EQU    $FE93

ALTCHAR		EQU		$C00F		; enables alternative character set - mousetext

BLINK		EQU		$F3
SPEED		EQU		$F1

**************************************************
* START - sets up various fiddly zero page bits
**************************************************

				ORG $2000						; PROGRAM DATA STARTS AT $2000

				JSR ROMSETVID           	 	; Init char output hook at $36/$37
				JSR ROMSETKBD           	 	; Init key input hook at $38/$39
				JSR ROMINIT               	 	; GR/HGR off, Text page 1
				
				LDA #$00
				STA BLINK						; blinking text? no thanks.
				STA LORES						; low res graphics mode
				STA MIXCLR
				STA ALTTEXTOFF					; display main text page

RESTART			LDA #$00
				STA PEDECOUNTER	
				STA PROGRESS

				LDA #$29						; keeps COUT from linebreaking
				STA WNDWDTH						; 
				CLC
				ROR
				STA PLAYERCOLUMN				; middle-ish
				LDA #$17
				STA PLAYERROW					; bottom line

				JSR	FILLSCREENFAST				; clear screen to black

RELOAD			JSR RNDINIT						; *should* cycle the random seed.

				INC PROGRESS

				LDA #$08
				STA PEDEDELAY
				STA MISSILEDELAY				; bit of a break between missile shots
				
				LDA #$FF						; 11111111
				STA PEDEBYTE					; all segments live

;PEDECOORDS		HEX 00,07,00,06,00,05,00,04,00,03,00,02,00,01,00,00			; row/col byte pairs for each segment of the OCTOPEDE

				LDY #$07
				LDX	#$00
RESETPEDE		LDA #$00
				STA PEDECOORDS,X				; segment ROW
				INX	
				TYA							
				STA PEDECOORDS,X				; segment COLUMN
				INX
				DEY
				BPL	RESETPEDE					; Y=0

				JSR DRAWSHROOMS					; puts mushrooms in random locations between row 0 and 23
				JSR DRAWPROGRESS				; updates "progress" player score indicator



**************************************************
*	MAIN LOOP
*	waits for keyboard input, moves cursor, etc
**************************************************

* Do each frame:
*	read joystick
*	update player position
*	if button and not already firing, create missile
*	if already firing, update missile row
*	if missile new position is non-blank, collision
*		

*	update pede positions.
*	if pede new position is non-blank, collision
*	interframe delay based on "score" ?



EVERYFRAME									

				LDA #$00
				STA CURRENTPEDE					; start each frame on first segment

				JSR UPDATEPLAYER
				JSR UPDATEMISSILE
				JSR UPDATEPEDE
				JSR INTERFRAME
				
				LDA PEDEBYTE					; pedes all dead if 0
				BEQ RELOAD
				
				LDA PLAYERROW
				BEQ RESTART						; player dead if row=0
				
				JMP EVERYFRAME
				
				; loopty loop
;/EVERYFRAME

**************************************************

INTERFRAME
				LDA #$20						; wait a bit
				JSR WAIT
				RTS
;/INTERFRAME
**************************************************


UPDATEPLAYER	LDA PLAYERDELAY					; counts down to 0
				BEQ STARTPLAYER					; if 0, set to delay value, and draw the pede
				DEC PLAYERDELAY					; otherwise, decrement
				RTS								; exit if countdown isn't done yet.				
				
		
STARTPLAYER		LDA #$10
				STA	PLAYERDELAY
				; erase current player position
				; calculate new player position
				; render new player position

				LDA PLAYERCOLUMN				; load current position
				STA PLOTCOLUMN
				STA COLUMN
				
				LDA PLAYERROW
				STA PLOTROW						; hang onto these in case there's a collision
				STA ROW
				
				LDA #$00		
				STA CHAR
				
				JSR PLOTQUICK					; erase current position

; read joystickX/pdl0, if less than 0x64(100) move left. if over 0x96(150) move right.

MOVEPLAYER		LDX #$00						; PDL 0 
				JSR PREAD 						; returns in Y

				TYA								; Y to Accumulator?
				CMP #$64
				BCC	MOVEPLAYERLEFT
				CMP #$96
				BCS MOVEPLAYERRIGHT
				JMP MOVEPLAYER2					; no L/R, check U/D

MOVEPLAYERRIGHT	LDA PLAYERCOLUMN				; already at col 39?
				CMP #$27						
				BEQ PLOTPLAYER
				INC PLAYERCOLUMN
				JMP MOVEPLAYER2	
				
MOVEPLAYERLEFT	LDA PLAYERCOLUMN				; already at zero
				BEQ	PLOTPLAYER
				DEC PLAYERCOLUMN				; otherwise, go left

MOVEPLAYER2		LDX #$01						; PDL 1 
				JSR PREAD 						; returns in Y

				TYA								; Y to Accumulator?
				CMP #$64
				BCC	MOVEPLAYERUP
				CMP #$96
				BCS MOVEPLAYERDOWN
				JMP COLLIDEPLAYER				; no U/D, plot as-is

MOVEPLAYERUP	LDA PLAYERROW				; already at col 39?
				CMP #$13						
				BEQ COLLIDEPLAYER
				DEC PLAYERROW
				JMP COLLIDEPLAYER			; moving, check collision
				
MOVEPLAYERDOWN	LDA PLAYERROW				; already at zero
				CMP #$17						
				BEQ	COLLIDEPLAYER
				INC PLAYERROW				; otherwise, go left

COLLIDEPLAYER	; check new position for collisions
				LDA PLAYERCOLUMN
				STA PLOTCOLUMN
				LDA PLAYERROW
				STA PLOTROW
				JSR GETCHAR						; not zero, collision. revert to old position.
				BEQ PLOTPLAYER
												; not zero, collision. revert to old position.
				LDA ROW							
				STA PLOTROW
				STA PLAYERROW
				LDA COLUMN
				STA PLOTCOLUMN	
				STA PLAYERCOLUMN							

				JSR CLICK
				
PLOTPLAYER		LDA #$11
				STA CHAR
				JSR PLOTQUICK					; plot the player
				RTS
DONEPLAYER		RTS
;/UPDATEPLAYER

**************************************************

UPDATEMISSILE	
*	if button and not already firing, create missile
*	if already firing, update missile row, display byte
*	if missile new position is non-blank, collision
				LDA PLAYERMISSILE				; row of missile will be FF if not firing
				BMI NOMISSILE

				STA PLOTROW						; erase missile at current coords
				LDX #$01
				LDA PLAYERMISSILE,X
				STA PLOTCOLUMN
				LDA #$00
				STA CHAR
				JSR PLOTQUICK
				
				LDX #$02						; update missile coords
				LDA PLAYERMISSILE,X				; if displaybyte is F0, make it 0F, don't update row.
				BMI MISSILESTAY

MISSILEUP		DEC PLAYERMISSILE				; dec missile row
				BMI	MISSILEDONE					; if FF, all done. 

MISSILESTAY		EOR #$FF						; else dec missile row, make byte F0
				STA PLAYERMISSILE,X	
				
				STA CHAR						; display updated missile at new coords
				LDA PLAYERMISSILE								
				STA	PLOTROW
				DEX			
				LDA PLAYERMISSILE,X	
				STA PLOTCOLUMN

				JSR GETCHAR						; check missile collision
				BNE COLLIDEMISSILE

				JSR PLOTQUICK

				RTS
				
; if there's no missile on the screen yet, put one there, as long as it has been at least N frames since last shot


NOMISSILE		LDA MISSILEDELAY
				BEQ NOMISSILE2
				DEC MISSILEDELAY				; count down to zero, bit of a break between shots
				JMP	MISSILEDONE
NOMISSILE2										; countdown done? check button
				LDA PB0							; no missile on screen. Check for button press to create one.
				BPL	MISSILEDONE
												; otherwise, create new missile at player column, row 23
ADDMISSILE		LDA #$30
				STA MISSILEDELAY				; reset delay for next shot.

				LDX #$2							; set missile display byte to #$F0
				LDA #$F0
				STA	PLAYERMISSILE,X
				DEX	
				LDA PLAYERCOLUMN				; get player COLUMN	
				STA PLAYERMISSILE,X
				DEX
				LDA	PLAYERROW					; set row to player
				STA PLAYERMISSILE,X
				
				JMP UPDATEMISSILE				; put it on screen.
MISSILEDONE		
				RTS

COLLIDEMISSILE									; accumulator should tell us what we collided with
												; PLOTROW and PLOTCOLUMN are intact
												
				CMP #$4C						; 4C = turn pede segments into mushrooms
				BNE COLLIDESHROOM
				LDA #$5F
				STA	CHAR
				JSR PLOTQUICK	
				

HITPEDE			; hit a pede segment
				; determine which segment was hit
				
				; for each segment
				; check if segment's COLUMN == missile's column
				; set PEDECOORD,X==FF to remove from board.
				LDY #$08

WHICHPEDE		DEY								; next pede segment 7-0
				BPL	WHICHPEDE2					; rolled over? RTS
				RTS
										
WHICHPEDE2		TYA
				CLC
				ROL
				TAX								; segment x 2 = segment ROW
				INX
				LDA PEDECOORDS,X				; get segment COLUMN
				
				LDX #$01
				CMP PLAYERMISSILE,X				; compare to missile column	
							
				BNE WHICHPEDE					; not the right segment, go again
												
												; correct segment COLUMN, CHECK ROW
				TYA
				CLC
				ROL
				TAX
				LDA PEDECOORDS,X				; get segment ROW
				
				CMP PLAYERMISSILE				; compare to missile ROW
				BNE WHICHPEDE					; wrong segment, go again
				
				; correct COLUMN AND ROW												
				TYA								
				CLC
				ROL
				TAX
				LDA #$FF						; set segment ROW again
				STA PEDECOORDS,X				; got the right segment, remove it
				
				JSR CLICK
				; clear the missile
						
				LDA #$FF
				STA PLAYERMISSILE				; missile row to top, clears missile

SETPEDEBYTE		
				LDA #$00						; zero out A
				SEC								; set carry
				
SETPEDEBYTE2	ROL								; carry into A
				DEY								; set for next segment
				BPL SETPEDEBYTE2				; if rolled over, done
				EOR	PEDEBYTE					; 11111111
												; 00001000 EOR
				STA PEDEBYTE					;=11110111	

				RTS
							
COLLIDESHROOM	CMP #$26
				BEQ KILLSCORE					; hit the score, skippy.
				
				CMP #$5F						; 5F = turn mushrooms into partial mushroom
				BNE KILLSHROOM
				LDA #$05
				JMP KILLSHROOM2

KILLSHROOM		CMP #$05						; 05 = remove partial mushrooms
				LDA #$00
KILLSHROOM2		STA CHAR
				JSR PLOTQUICK

KILLSCORE		LDA #$FF						; reset the missile's coords to off-screen
				STA PLAYERMISSILE
	
				JSR CLICK
	
				RTS


;/UPDATEMISSILE

**************************************************

UPDATEPEDE		; check if frames of delay have elapsed, slows down the pede
				LDA PEDECOUNTER					; counts down to 0
				BEQ STARTPEDE					; if 0, set to delay value, and draw the pede
				DEC PEDECOUNTER					; otherwise, decrement
				RTS								; exit if countdown isn't done yet.
				
STARTPEDE		LDA PEDEDELAY
				STA PEDECOUNTER
				
				; check PEDEBYTE to see if it's zeroed out yet.
				*****
				
				
NEXTPEDE		LDA CURRENTPEDE					; which segment 0-7
				CLC
				ROL								; multiply by 2
				TAX								
				
				LDA PEDECOORDS,X				; segment's row 
				CMP #$FF						; if FF, ignore
				BEQ SKIPPEDE
				 
PLOTPEDE		STA PLOTROW						; current plot row	

				INX
				LDA PEDECOORDS,X				; segment's column
				STA PLOTCOLUMN					; current plot column	

				JSR GETCHAR						; erasing something other than a pede segment?
				BEQ CONTINUEPEDE				; 00 - skip the erase step

				CMP #$4C
				BNE	CONTINUEPEDE				; skip the erase step if not 4C

												; hit another pede segment, no worries.
			

ERASEPEDE		LDA #$00						; erase current segment previous position
				STA CHAR						; load the char
				JSR PLOTQUICK					; erases current segment previous position

CONTINUEPEDE	JSR WALKLOOP					; erases previous position
												; calculates next position
												; plots new position
												

SKIPPEDE		INC CURRENTPEDE					; repeat with next segment

				LDA CURRENTPEDE
				CMP #$08						; done all 8 segments? RTS.
				BNE NEXTPEDE

				LDA #$00						; start over with segment 0
				STA CURRENTPEDE
				RTS
				
;/UPDATEPEDE

WALKLOOP										; erases previous position
												; calculates next position
												; plots new position

												
NEXTPOS			JSR EVENORODDROW				; calculate next position

				JSR GETCHAR						; if next position not 00, then down and reverse
				BNE NEXTROW

				LDA #$4C						; green/dk green
				STA CHAR
				JSR PLOTQUICK					; plots new position

				RTS
;/WALKLOOP



				
EVENORODDROW	LDA CURRENTPEDE					; segment 0-8
				CLC
				ROL
				TAX
				LDA PEDECOORDS,X				; segment ROW to PLOTROW
				STA PLOTROW							

				INX
				LDA PEDECOORDS,X
				STA PLOTCOLUMN					; segment COLUMN to PLOTCOLUMN

				LDA PLOTROW	
				ROR								; odd, then carry set
				BCS ODDROW
;/EVENORODDROW


EVENROW
				LDA CURRENTPEDE					; segment 0-8
				CLC
				ROL
				TAX
				INX								
				
				LDY PEDECOORDS,X				; inc segment column
				INY
				TYA
				STA PEDECOORDS,X
				STA PLOTCOLUMN					; to PLOTCOLUMN
												
				CMP #$28						; if PLOTCOLUMN == #$27, then inc PLOTROW
				BEQ NEXTROW
												; else, loop on current row.
												
				JSR GETCHAR
				BNE NEXTROW
												
				RTS								; return and draw pixel
;/EVENROW

ODDROW			LDA CURRENTPEDE					; segment 0-8
				CLC
				ROL
				TAX
				INX								

				LDY PEDECOORDS,X				; DEC segment column 
				DEY								
				BMI NEXTROW						; if PLOTCOLUMN rolled over, then inc PLOTROW
				TYA
				STA	PEDECOORDS,X
				STA PLOTCOLUMN					; to PLOTCOLUMN

				
				JSR GETCHAR
				BNE NEXTROW
				
				RTS
;/ODDROW

NEXTROW			; hit something, bounce, kill or die.
				; char in A
				
				; hit the player?
				CMP #$11						; hit the player. BEEP and RESTART
				BEQ KILLPLAYER 				

				; did I hit a missile?	
				
				CMP #$F0
				BEQ KILLPEDE
				CMP #$0F
				BEQ KILLPEDE

				; must be a mushroom.
				
				LDA CURRENTPEDE	
				CLC			
				ROL
				TAX	
				LDY PEDECOORDS,X				; INC PLOTROW
				INY
				TYA
				STA PEDECOORDS,X				
				
				CMP #$18						; if PLOTROW == #$18, done
				BNE EVENORODDROW

; 				bottom of the screen? now what?
; 				need to start back up the screen for a bit, then back down. Oof.
; 				or just kill the player and start over at 0.
				
				LDA #$00						; row back to 0
				STA PEDECOORDS,X
				
				JMP EVENORODDROW				
;/NEXTROW

				; kill this segment 
KILLPEDE		
				JSR COLLIDEMISSILE		;HITPEDE
				RTS

KILLPLAYER		; hit by a pede segment, or moved into one.
				JSR BEEP
				LDA #$00
				STA PLAYERROW
				RTS
				

**************************************************
*	subroutines
**************************************************
DRAWSHROOMS										; blank screen routine, counts down random number between placing mushrooms
						LDA #$18				
						STA	SHROOMCOUNT			; how many mushrooms to draw
		
						LDA #$16				; start at bottom ROW
						STA PLOTROW				
						
						LDA #$5F				; shroom char
						STA CHAR
			
						JSR RND					; returns with 0-ff in A
						ROR						; 1/2
						TAX						; random steps between mushrooms in X
		
SHROOMROW				DEC PLOTROW				; next row up
						BNE SHROOMROW2			; not yet done, next row
						
						LDA	SHROOMCOUNT			; row 0 AND shroomcount 0? All done.
						BEQ SHROOMSDONE			; 
						
						LDA #$16				; still not done, reset at row 23
						STA PLOTROW
												
SHROOMROW2				LDA #$28				; start at column 40
						STA PLOTCOLUMN
		
SHROOMCOL				DEC PLOTCOLUMN			; next column
						BEQ SHROOMROW			; column == 0? next row
						DEX						; otherwise, DEX and check if it's mushroom time
						BNE SHROOMCOL			; x=0?
						JSR PLOTQUICK			; draw mushroom Here
						DEC SHROOMCOUNT			
						BEQ SHROOMSDONE			; done drawing 24 shrooms?
												; no - do another 
												
NEXTSHROOM				;JSR RNDINIT
						JSR CLICK
						LDA #$80
						JSR WAIT

						JSR RND					; returns with 0-ff in A
						TAX						; random steps between mushrooms in X
						JMP SHROOMCOL

SHROOMSDONE				RTS
;/DRAWSHROOMS

**************************************************

DRAWPROGRESS						
						LDA #$00
						STA PLOTROW					; start at row 0, column 40
						LDA #$27
						STA PLOTCOLUMN
						LDA #$26					; draw a blue pixel
						STA CHAR
						LDX PROGRESS				; for each PROGRESS, dec column
						
DRAWPROGRESS2			JSR PLOTQUICK
						DEC PLOTCOLUMN
						DEX
						BNE DRAWPROGRESS2
												; repeat draw.

						RTS
;/DRAWPROGRESS

**************************************************
*	blanks the screen
**************************************************
FILLSCREENFAST						; 5,403 instructions

				LDA #$00
				LDY #$78
FILL1			DEY
				STA $400, Y
				STA $480, Y
				STA $500, Y
				STA $580, Y
				STA $600, Y
				STA $680, Y
				STA $700, Y
				STA $780, Y
				BNE FILL1
				RTS


**************************************************
*	prints one CHAR at PLOTROW,PLOTCOLUMN - clobbers A,Y
*	used for plotting background elements that don't need collision detection
**************************************************
PLOTQUICK		; using COUT so I can maybe update to a HRCG later.

				LDA PLOTROW
				STA CV
				LDA PLOTCOLUMN
				STA CH
				JSR VTAB					; sets the Vertical Row memory loc. for COUT
				
				LDA CHAR

				JSR COUT
				RTS
				

;OLD PLOTQUICK
				LDY PLOTROW
				TYA
				CMP #$18
				BCS OUTOFBOUNDS2			; stop plotting if dimensions are outside screen
				
				LDA LoLineTableL,Y
				STA $0
				LDA LoLineTableH,Y
				STA $1       		  		; now word/pointer at $0+$1 points to line 
				;JMP LOADQUICK

LOADQUICK		
				LDY PLOTCOLUMN
				TYA
				CMP #$28
				BCS OUTOFBOUNDS2			; stop plotting if dimensions are outside screen

				STY $06						; hang onto Y for a sec...

				LDA CHAR
				LDY $06
				STA ($0),Y  

OUTOFBOUNDS2	RTS
;/PLOTQUICK			   
			   

**************************************************
*	GETS one CHAR at PLOTROW,PLOTCOLUMN - value returns in Accumulator - clobbers Y
**************************************************
GETCHAR
				LDY PLOTROW
				CLC

				LDA LoLineTableL,Y
				STA $0
				LDA LoLineTableH,Y
				;JMP STORECHAR

STORECHAR		STA $1       		  	; now word/pointer at $0+$1 points to line 
				LDY PLOTCOLUMN
				LDA ($0),Y  			; byte at row,col is now in accumulator
				RTS
;/GETCHAR					   




**************************************************
*	CLICKS and BEEPS - clobbers X,Y,A
**************************************************
CLICK			LDX #$06
CLICKLOOP		LDA #$10				; SLIGHT DELAY
				JSR WAIT
				STA SPEAKER				
				DEX
				BNE CLICKLOOP
				RTS
;/CLICK

BEEP			LDX #$30
BEEPLOOP		LDA #$08				; short DELAY
				JSR WAIT
				STA SPEAKER				
				DEX
				BNE BEEPLOOP
				RTS
;/BEEP


BONK			LDX #$50
BONKLOOP		LDA #$20				; longer DELAY
				JSR WAIT
				STA SPEAKER				
				DEX
				BNE BONKLOOP
				RTS
;/BONK



**************************************************
* DATASOFT RND 6502
* BY JAMES GARON
* 10/02/86
* Thanks to John Brooks for this. I modified it slightly.
*
* returns a randomish number in Accumulator.
**************************************************
RNDINIT
				LDA	$C030			; #$AB
				STA	RNDSEED
				LDA	PROGRESS		;	$4E				; #$55
				STA	RNDSEED+1
				LDA	$C060			; #$7E
				STA	RNDSEED+2
				RTS	

* RESULT IN ACC
RND  			LDA	RNDSEED
     			ROL	RNDSEED
     			EOR	RNDSEED
     			ROR	RNDSEED
     			INC	RNDSEED+1
     			BNE	RND10
     			LDA	RNDSEED+2
     			INC	RNDSEED+2
RND10			ADC	RNDSEED+1
     			BVC	RND20
     			INC	RNDSEED+1
     			BNE	RND20
     			LDA	RNDSEED+2
     			INC	RNDSEED+2
RND20			STA	RNDSEED
     			RTS	

RND16			JSR RND			; limits RND output to 0-F
				AND #$0F		; strips high nibble
				RTS

**************************************************
* Data Tables
*
**************************************************
PEDECOORDS			HEX 00,07,00,06,00,05,00,04,00,03,00,02,00,01,00,00			; row/col byte pairs for each segment of the OCTOPEDE
PLAYERMISSILE		HEX FF,FF,F0	; row, column, displaybyte



**************************************************
* Lores/Text lines
* Thanks to Dagen Brock for this.
**************************************************
Lo01                 equ   $400
Lo02                 equ   $480
Lo03                 equ   $500
Lo04                 equ   $580
Lo05                 equ   $600
Lo06                 equ   $680
Lo07                 equ   $700
Lo08                 equ   $780
Lo09                 equ   $428
Lo10                 equ   $4a8
Lo11                 equ   $528
Lo12                 equ   $5a8
Lo13                 equ   $628
Lo14                 equ   $6a8
Lo15                 equ   $728
Lo16                 equ   $7a8
Lo17                 equ   $450
Lo18                 equ   $4d0
Lo19                 equ   $550
Lo20                 equ   $5d0
* the "plus four" lines
Lo21                 equ   $650
Lo22                 equ   $6d0
Lo23                 equ   $750
Lo24                 equ   $7d0

; alt text page lines
Alt01                 equ   $800
Alt02                 equ   $880
Alt03                 equ   $900
Alt04                 equ   $980
Alt05                 equ   $A00
Alt06                 equ   $A80
Alt07                 equ   $B00
Alt08                 equ   $B80
Alt09                 equ   $828
Alt10                 equ   $8a8
Alt11                 equ   $928
Alt12                 equ   $9a8
Alt13                 equ   $A28
Alt14                 equ   $Aa8
Alt15                 equ   $B28
Alt16                 equ   $Ba8
Alt17                 equ   $850
Alt18                 equ   $8d0
Alt19                 equ   $950
Alt20                 equ   $9d0
* the "plus four" lines
Alt21                 equ   $A50
Alt22                 equ   $Ad0
Alt23                 equ   $B50
Alt24                 equ   $Bd0




LoLineTable          da    	Lo01,Lo02,Lo03,Lo04
                     da    	Lo05,Lo06,Lo07,Lo08
                     da		Lo09,Lo10,Lo11,Lo12
                     da    	Lo13,Lo14,Lo15,Lo16
                     da		Lo17,Lo18,Lo19,Lo20
                     da		Lo21,Lo22,Lo23,Lo24

; alt text page
AltLineTable         da    	Alt01,Alt02,Alt03,Alt04
                     da    	Alt05,Alt06,Alt07,Alt08
                     da		Alt09,Alt10,Alt11,Alt12
                     da    	Alt13,Alt14,Alt15,Alt16
                     da		Alt17,Alt18,Alt19,Alt20
                     da		Alt21,Alt22,Alt23,Alt24


** Here we split the table for an optimization
** We can directly get our line numbers now
** Without using ASL
LoLineTableH         db    >Lo01,>Lo02,>Lo03
                     db    >Lo04,>Lo05,>Lo06
                     db    >Lo07,>Lo08,>Lo09
                     db    >Lo10,>Lo11,>Lo12
                     db    >Lo13,>Lo14,>Lo15
                     db    >Lo16,>Lo17,>Lo18
                     db    >Lo19,>Lo20,>Lo21
                     db    >Lo22,>Lo23,>Lo24
LoLineTableL         db    <Lo01,<Lo02,<Lo03
                     db    <Lo04,<Lo05,<Lo06
                     db    <Lo07,<Lo08,<Lo09
                     db    <Lo10,<Lo11,<Lo12
                     db    <Lo13,<Lo14,<Lo15
                     db    <Lo16,<Lo17,<Lo18
                     db    <Lo19,<Lo20,<Lo21
                     db    <Lo22,<Lo23,<Lo24

; alt text page
AltLineTableH        db    >Alt01,>Alt02,>Alt03
                     db    >Alt04,>Alt05,>Alt06
                     db    >Alt07,>Alt08,>Alt09
                     db    >Alt10,>Alt11,>Alt12
                     db    >Alt13,>Alt14,>Alt15
                     db    >Alt16,>Alt17,>Alt18
                     db    >Alt19,>Alt20,>Alt21
                     db    >Alt22,>Alt23,>Alt24
AltLineTableL        db    <Alt01,<Alt02,<Alt03
                     db    <Alt04,<Alt05,<Alt06
                     db    <Alt07,<Alt08,<Alt09
                     db    <Alt10,<Alt11,<Alt12
                     db    <Alt13,<Alt14,<Alt15
                     db    <Alt16,<Alt17,<Alt18
                     db    <Alt19,<Alt20,<Alt21
                     db    <Alt22,<Alt23,<Alt24

