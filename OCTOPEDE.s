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

SPIDERROW		EQU		$FE			; row/col of spider's left half
SPIDERCOLUMN	EQU		$FF
SPIDERDELAY		EQU		$F9			; how quick to move the spider?

CH				EQU		$24			; cursor Horiz
CV				EQU		$25			; cursor Vert

WNDWDTH			EQU		$21			; Width of text window
WNDTOP			EQU		$22			; Top of text window


RNDSEED			EQU		$EA			; +eb +ec

PEDEDELAY		EQU		$CE			; how many frames to delay the pede's walking
PEDECOUNTER		EQU		$CD			; how many frames to delay the pede's walking

SHROOMCOUNT		EQU		$CC			; how many mushrooms to start with

PEDEBYTE		EQU		$1D			; 1 bit per segment

MISSILEDELAY	EQU		$1E			; dropping block column

PLAYERCOLUMN	EQU		$09			; Where is the player shooting from?
PLAYERROW		EQU		$0A			; Where is the player shooting from?
PLAYERDELAY		EQU		$40			; how quick to move the player

PROGRESS 		EQU		$FD			; How many lives?

REVERSEPEDES	EQU		$1F			; which segments are going UP?

CSW     		EQU 	$36

BASL    		EQU 	$28
TABLEPOS    	EQU 	$3C        ; (BAS2)
SCRN    		EQU 	$3E        ; (A4)
VECT    		EQU 	$3EA

ITERATIONS		EQU		$F8

**************************************************
* Apple Standard Memory Locations
**************************************************
CLRLORES   	EQU		$F832
LORES      	EQU		$C050
HIRES		EQU		$C057
TXTSET     	EQU		$C051
MIXCLR     	EQU		$C052
MIXSET     	EQU		$C053
TXTPAGE1   	EQU		$C054
TXTPAGE2   	EQU		$C055
KEY        	EQU		$C000
C80STOREOFF	EQU		$C000
C80STOREON 	EQU		$C001
STROBE     	EQU		$C010
SPEAKER    	EQU		$C030
VBL        	EQU		$C02E
RDVBLBAR   	EQU		$C019		; not VBL (VBL signal low
WAIT		EQU		$FCA8 
RAMWRTAUX  	EQU		$C005
RAMWRTMAIN 	EQU		$C004
SETAN3     	EQU		$C05E		; Set annunciator-3 output to 0
SET80VID   	EQU		$C00D		; enable 80-column display mode (WR-only)
HOME		EQU		$FC58		; clear the text screen
; VTAB       	EQU		$FC22		; Sets the cursor vertical position (from CV)
COUT       	EQU		$FDED		; Calls the output routine whose address is stored in CSW,
								; normally COUT1
COUT1		EQU		$FDF0
COUT2		EQU		$FBF0
 
PRBYTE		EQU		$FDDA 		; print hex byte in A

STROUT		EQU		$DB3A 		; Y=String ptr high, A=String ptr low

ALTTEXT		EQU		$C055
ALTTEXTOFF	EQU		$C054


PB0			EQU		$C061		; paddle 0 button. high bit set when pressed.
PDL0		EQU		$C064		; paddle 0 value, or should I use PREAD?
PREAD		EQU		$FB1E

ROMINIT      EQU    $FB2F
ROMSETKBD    EQU    $FE89
ROMSETVID    EQU    $FE93

ALTCHAR		EQU		$C00F		; enables alternative character set - mousetext

BLINK		EQU		$F3
SPEED		EQU		$F1


HGR			EQU	$F3E2 			;	Initializes to hi-res page1, clears screen. 
HGR2		EQU	$F3D8 			;	Initializes to hi-res page2, clears screen. 
HCLR 		EQU	$F3F2 			;	Clears current screen to black 






**************************************************
* START - sets up various fiddly zero page bits
**************************************************

				ORG $0800						; PROGRAM DATA STARTS AT $0800

RESETSCORE		LDA #$00
				STA PLAYERSCORE
				STA PLAYERSCORE+1
				STA PLAYERSCORE+2
				STA PLAYERSCORE+3

				LDA #$03
				STA PROGRESS

RESTART			DEC PROGRESS
				BMI RESETSCORE					; no more lives left? start back at 3.
				JSR	FILLSCREENFAST				; clear screen to black
				
				JSR HGR							; clear HGR

				BIT LORES     					; GRAPHIQUES
				BIT MIXCLR     					; PLEIN G.
				BIT HIRES     					; HAUTE RESOLUTION
				BIT TXTPAGE1     				; PAGE1
				BIT $C00C     					; 40 COL.

				JSR HOOK						; set HRCG output


				LDA #$00
				STA PEDECOUNTER	
				LDA #$29						; keeps COUT from linebreaking
				STA WNDWDTH						; 
				CLC
				ROR
				ADC #$01
				STA PLAYERCOLUMN				; middle-ish
				LDA #$17
				STA PLAYERROW					; bottom line

				LDA #$14
				STA SPIDERROW
				LDA #$27
				STA SPIDERCOLUMN



RELOAD			JSR RNDINIT						; *should* cycle the random seed.
				LDA #$00						; zeros out accumulator for score display.
				JSR UPDATESCORE
				JSR DISPLAYHISCORE

				LDA #$07
				STA PEDEDELAY
				STA MISSILEDELAY				; bit of a break between missile shots
				
				LDA #$FF						; 11111111
				STA PEDEBYTE					; all segments live

				LDY #$07
				LDX	#$00
RESETPEDE		LDA #$00
				STA REVERSEPEDES				; all pedes going down
				STA PEDECOORDS,X				; segment ROW
				INX	
				TYA							
				STA PEDECOORDS,X				; segment COLUMN
				INX
				DEY
				BPL	RESETPEDE					; Y=0

				JSR DRAWSHROOMS					; puts mushrooms in random locations between row 0 and 23
				LDA PROGRESS
				BEQ EVERYFRAME					; skip if no lives left.
				JSR DRAWLIVES				; updates "progress" player lives indicator



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

				LDA PLAYERROW
				BEQ RESTART						; player dead if row=0
				LDA PEDEBYTE					; pedes all dead if 0
				BEQ RELOAD

				LDA #$00
				STA CURRENTPEDE					; start each frame on first segment

				JSR UPDATEPLAYER
				JSR UPDATEMISSILE
				JSR UPDATEPEDE
				JSR	UPDATESPIDER
				JSR INTERFRAME
	
				LDA #$00						; oops. i'm stuck if this rolls over
				STA ITERATIONS					; then what? RTS?
				
				
				JMP EVERYFRAME
				
				; loopty loop
;/EVERYFRAME

**************************************************

INTERFRAME
				LDA #$30						; wait a bit
				JSR WAIT
ANRTS			RTS
;/INTERFRAME
**************************************************

UPDATESPIDER	LDA SPIDERDELAY					
				BEQ STARTSPIDER					
				DEC SPIDERDELAY					
				RTS								
	
STARTSPIDER		LDA #$0D
				STA	SPIDERDELAY

				LDA SPIDERROW					; mark for erase
				STA ROW
				LDA SPIDERCOLUMN
				STA COLUMN

MOVESPIDER		; get random number, 0-FF, clear high nibble, divide by 4. 
				JSR RND			; 0-FF
				AND #$03		; 0-3
				BEQ DONEMOVING	; 0 stay
				ROR				; 1 or 3 - carry set
				BCC JUMPSPIDER	; 2 - carry clear, left
				BEQ	JUMPUP		; zero, jump up

JUMPDOWN		INC SPIDERROW				; 1, jump down
				LDA SPIDERROW
				CMP #$18
				BNE	JUMPSPIDER
				LDA #$17
				STA SPIDERROW
				JMP JUMPSPIDER

JUMPUP			DEC SPIDERROW
				LDA SPIDERROW
				CMP #$0A
				BNE	JUMPSPIDER
				LDA #$0B
				STA SPIDERROW

JUMPSPIDER		; determine if the spider is jumping left or right at the moment.
				; if the 100s score is odd, jump left. Otherwise, right.
				LDA PLAYERSCORE+2
				ROR
				BCC JUMPRIGHT
				

JUMPLEFT		DEC SPIDERCOLUMN
				BPL DONEMOVING
				LDA #$28						; column zero, reset
				STA SPIDERCOLUMN
				JMP DONEMOVING

JUMPRIGHT		INC SPIDERCOLUMN
				LDA SPIDERCOLUMN
				CMP #$28
				BCC DONEMOVING					; > 28, reset.
				LDA #$00						; column zero, reset
				STA SPIDERCOLUMN

DONEMOVING		

ERASESPIDER		;LDA #$A0
				;STA CHAR
				LDA ROW
				STA CV
				VTAB
				LDA COLUMN
				STA CH

COLLIDESPIDER	JSR GETCHAR						; hit the player?
				CMP #$F0						
				BEQ KILLTHEPLAYER
				CMP #$F1
				BEQ KILLTHEPLAYER
	
				INC CH							; right side test.
				JSR GETCHAR
				CMP #$F0
				BEQ KILLTHEPLAYER
				CMP #$F1
				BEQ KILLTHEPLAYER

				DEC CH

;				LDA #$A0
;				JSR PLOTQUICK					; otherwise, clobber mushrooms and pedes.
;				JSR PLOTQUICK
				JSR ERASEQUICK					
				JSR ERASEQUICK

DRAWSPIDER		LDA SPIDERCOLUMN
				STA CH
				LDA SPIDERROW
				STA CV
				VTAB
								
				LDA #$C8						; spider, left side = C8
;				STA CHAR
				JSR PLOTQUICK
;				INC CHAR						; spider, right side = CA
;				INC CHAR
				LDA #$CA						; spider, left side = C8
				JSR PLOTQUICK

				RTS

				
KILLTHEPLAYER	JMP KILLPLAYER

**************************************************




UPDATEPLAYER	LDA PLAYERDELAY					; counts down to 0
				BEQ STARTPLAYER					; if 0, set to delay value, and draw the pede
				DEC PLAYERDELAY					; otherwise, decrement
				RTS								; exit if countdown isn't done yet.				
				
		
STARTPLAYER		LDA #$0B
				STA	PLAYERDELAY
				; erase current player position
				; calculate new player position
				; render new player position

				LDA PLAYERCOLUMN				; load current position
				STA CH ; PLOTCOLUMN
				STA COLUMN						; store for erasing later
				
				LDA PLAYERROW
				STA CV ; PLOTROW				; hang onto these in case there's a collision
				STA ROW							; store for erasing later
				
				BIT ANRTS						; set overflow = no movement yet

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
				BEQ COLLIDEPLAYER
				INC PLAYERCOLUMN
				CLV
				JMP MOVEPLAYER2	
				
MOVEPLAYERLEFT	LDA PLAYERCOLUMN				; already at zero
				BEQ	COLLIDEPLAYER
				DEC PLAYERCOLUMN				; otherwise, go left
				CLV

MOVEPLAYER2		LDX #$01						; PDL 1 
				JSR PREAD 						; returns in Y

				TYA								; Y to Accumulator?
				CMP #$64
				BCC	MOVEPLAYERUP
				CMP #$96
				BCS MOVEPLAYERDOWN
				JMP COLLIDEPLAYER				; no U/D, plot as-is

MOVEPLAYERUP	LDA PLAYERROW					; already at col 39?
				CMP #$13						
				BEQ COLLIDEPLAYER
				DEC PLAYERROW
				CLV
				JMP COLLIDEPLAYER				; moving, check collision
				
MOVEPLAYERDOWN	LDA PLAYERROW					; already at zero
				CMP #$17						
				BEQ	COLLIDEPLAYER
				INC PLAYERROW					; otherwise, go DOWN
				CLV

COLLIDEPLAYER	; check new position for collisions
				
				BVS PLOTPLAYER					; overflow still set, skip the move/collide math
				
;				LDA #$A0						; plotrow/col should still be intact
;				STA CHAR
				JSR ERASEQUICK					; erase current position

				LDA PLAYERCOLUMN
				STA CH ; PLOTCOLUMN
				LDA PLAYERROW
				STA CV ; PLOTROW
				JSR GETCHAR						; not zero, collision. revert to old position.
				AND #$F0						; Ax = space
				CMP #$A0
				BEQ PLOTPLAYER
												; not zero, collision. revert to old position.
												
				CMP #$C0						; hit a 'pede or spider. DIE.
				BEQ PLAYERDIED								
												
				LDA ROW							
				STA CV 							; PLOTROW
				STA PLAYERROW
				LDA COLUMN
				STA CH 							; PLOTCOLUMN	
				STA PLAYERCOLUMN							

				JSR CLICK
				
PLOTPLAYER		
				
				LDA #$F0						;F0
;				STA CHAR
				JSR PLOTQUICK					; plot the player
				RTS
DONEPLAYER		RTS
;/UPDATEPLAYER

PLAYERDIED		; moved into a 'pede or the spider. jump to killplayer?
				JMP KILLPLAYER



**************************************************

UPDATEMISSILE	
*	if button and not already firing, create missile
*	if already firing, update missile row, display byte
*	if missile new position is non-blank, collision
				LDA PLAYERMISSILE				; row of missile will be FF if not firing
				BMI NOMISSILE

				STA CV							; PLOTROW	; erase missile at current coords
;				LDX #$01
				LDA PLAYERMISSILE+1
				STA CH							; PLOTCOLUMN
;				LDA #$A0
;				STA CHAR
				JSR ERASEQUICK
				
NEWMISSILE		;LDX #$02						; update missile coords
				LDA PLAYERMISSILE+2			; if displaybyte is AE . , make it A7 ', don't update row.
				CMP #$FB
				BEQ MISSILESTAY

MISSILEUP		DEC PLAYERMISSILE				; dec missile row
				BMI	MISSILEDONE					; if FF, all done. 
				LDA #$FB
				JMP MISSILECHAR

MISSILESTAY		LDA #$FD						; 
				STA PLAYERMISSILE+2	
				
MISSILECHAR		;STA CHAR						; display updated missile at new coords
				LDA PLAYERMISSILE								
				STA	CV							; PLOTROW
				;DEX			
				LDA PLAYERMISSILE+1	
				STA CH							; PLOTCOLUMN

				JSR GETCHAR						; check missile collision
				AND #$F0						; Ax = space
				CMP #$A0
				BNE COLLIDEMISSILE

				LDA PLAYERMISSILE+2
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
				LDA #$FD						; .	#$F0
				STA	PLAYERMISSILE,X
				STA CHAR
				DEX	
				LDA PLAYERCOLUMN				; get player COLUMN	
				STA PLAYERMISSILE,X
				DEX
				LDA	PLAYERROW					; set row to player - 1

				STA PLAYERMISSILE,X
				
				JMP NEWMISSILE		; UPDATEMISSILE				; put it on screen.
MISSILEDONE		
				RTS

COLLIDEMISSILE	LDX #$00						; accumulator should tell us what we collided with
				STX MISSILEDELAY				; hit something, set delay to zero, to fire again.
												; PLOTROW and PLOTCOLUMN are intact
												
				AND #$F0						; clear low nibble to C0 or C1
				CMP #$C0 ; @					; IS IT A PEDE SEGMENT (Cx)?
				BNE COLLIDESHROOM				; NO? check for mushroom
				LDA #$D0 						; full shroom
				;STA	CHAR
				JSR PLOTQUICK	
				LDA #$25						; 25 points for a pede 
				JSR UPDATESCORE


HITPEDE			; hit a pede segment - or SPIDER
				; determine which segment was hit
				
				; for each segment
				; check if segment's COLUMN == missile's column
				; set PEDECOORD,X==FF to remove from board.
				LDY #$08

WHICHPEDE		DEY								; next pede segment 7-0
				BPL	WHICHPEDE2					; rolled over? KILLED SPIDER
				
				JMP KILLSPIDER					; spider dead.
				
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
							
COLLIDESHROOM	CMP #$B0			
				BEQ KILLSCORE					; you hit the score, skippy.
				CMP #$F0
				BEQ KILLSCORE					; hit the player lives icons
				
				CMP #$D0 ; ?					; 5F = turn mushrooms into partial mushroom
				BNE KILLSHROOM
				LDA #$E0 ; _
				JMP KILLSHROOM2

KILLSHROOM		CMP #$E0 ; _					; 05 = remove partial mushrooms
				LDA #$A0
KILLSHROOM2		;STA CHAR
				JSR PLOTQUICK

				LDA #$10						; 10 points for a mushroom
				JSR UPDATESCORE



KILLSCORE		LDA #$FF						; reset the missile's coords to off-screen
				STA PLAYERMISSILE
	
				JSR CLICK
	
				RTS

KILLSPIDER		; erase spider
				LDA SPIDERROW
				STA CV
				VTAB
				LDA SPIDERCOLUMN
				STA CH

;				LDA #$A0
;				STA CHAR

				JSR ERASEQUICK
				JSR ERASEQUICK
				
				; set spider countdown to 0
				LDA #$FF
				STA SPIDERDELAY
				; reset spider coords

				LDA #$28
				STA SPIDERCOLUMN
				
				LDA #$50				; 50 points for the spider
				JSR UPDATESCORE
				LDA #$50				; 50 more points for the spider?
				JSR UPDATESCORE


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
				
				
NEXTPEDE		LDA CURRENTPEDE					; which segment 0-7
				CLC
				ROL								; multiply by 2
				TAX								
				
				LDA PEDECOORDS,X				; segment's row 
				CMP #$FF						; if FF, ignore
				BEQ SKIPPEDE
				 
PLOTPEDE		STA CV ; PLOTROW						; current plot row	
				STA ROW
				INX
				LDA PEDECOORDS,X				; segment's column
				STA CH ; PLOTCOLUMN					; current plot column	
				STA COLUMN
				JSR GETCHAR						; erasing something other than a pede segment?
				AND #$F0						; Ax = space
				CMP #$A0
				BEQ CONTINUEPEDE				; 00 - skip the erase step

				AND #$F0						; clear low nibble Cn = PEDE
				CMP #$C0 						; @
				BNE	CONTINUEPEDE				; skip the erase step if not 4C

												; hit another pede segment, no worries.
			


CONTINUEPEDE	JSR WALKLOOP					
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



WALKLOOP										
												; calculates next position
												; erases previous position
												; plots new position

												
NEXTPOS			JSR EVENORODDROW				; calculate next position

				JSR GETCHAR						; if next position not 00, then down and reverse

				CMP #$AF						; less than AF = empty, plottable
				BCS NEXTROW						; decides which pede direction to plot
								
ERASEPEDE		LDA CHAR
				PHA								; push CHAR
				LDA CH							; PLOTCOLUMN	; push PLOTCOLUMN
				PHA
				LDA CV							; PLOTROW	; push PLOTROW
				PHA
				
				LDA ROW							; segment old position
				STA CV							; PLOTROW
				LDA COLUMN
				STA CH							; PLOTCOLUMN
;				LDA #$A0						; erase current segment previous position
;				STA CHAR						; load the char
				JSR ERASEQUICK					; erases current segment previous position

				PLA								; pull PLOTROW
				STA CV 							; PLOTROW
				PLA
				STA CH 							; PLOTCOLUMN		; pull PLOTCOLUMN
				PLA
;				STA CHAR						; pull CHAR

				JSR PLOTQUICK					; plots pede at new position

				RTS
;/WALKLOOP



				
EVENORODDROW	LDA CURRENTPEDE					; segment 0-8
				CLC
				ROL								; *2
				TAX								; to X

				LDA PEDECOORDS,X				; segment ROW
				STA CV 							; PLOTROW	; for checking char at next position
				ROR								; ROW = odd, then carry set
				BCS ODDROW
;/EVENORODDROW


EVENROW
				INX								; INX to get to CURRENTPEDE,COLUMN
				
				LDY PEDECOORDS,X				; inc segment column
				INY
				TYA
				STY CH 							; PLOTCOLUMN		; to PLOTCOLUMN
				STA PEDECOORDS,X				
												
				CMP #$28						; if PLOTCOLUMN == #$27, then inc PLOTROW
				BEQ NEXTROW
												; else, loop on current row.
												
				JSR GETCHAR						; get character at next position.
				CMP #$AF						; < AF = empty space.
				BCS NEXTROW

				LDA #$C0 						; @					

				LDY CURRENTPEDE
				BNE EVENPLOT
				LDA #$C4						; "head"
EVENPLOT		STA CHAR

				RTS								; return and draw pixel
;/EVENROW

ODDROW			INX								; INX to get to CURRENTPEDE,COLUMN

				LDY PEDECOORDS,X				; DEC segment column 
				DEY								
				BMI NEXTROW						; if PLOTCOLUMN rolled over, then inc PLOTROW
				TYA
				STA	PEDECOORDS,X
				STA CH ; PLOTCOLUMN					; to PLOTCOLUMN

				
				JSR GETCHAR						; get char at next position
				CMP #$AF						; less than AF, space. 
				BCS NEXTROW

				LDA #$C2 ; A					
				
				LDY CURRENTPEDE
				BNE ODDPLOT
				LDA #$C6						; "head"
ODDPLOT			STA CHAR

				RTS								; return and draw pixel
;/ODDROW

NEXTROW			INC ITERATIONS					; if I'm stuck on a loop too long, kill the pede and move on
				BEQ KILLPEDE
				; hit something, bounce, kill or die. or EOL.
				; char in A
				
				; hit the player?
				CMP #$F0						; hit the player. BEEP and RESTART
				BEQ KILLPLAYER 				
				CMP #$F1						; hit the player. BEEP and RESTART
				BEQ KILLPLAYER 				

				; did I hit a missile?	
				
				;AND #$F0
				;CMP #$F0						; F = missile
				;BEQ KILLPEDE

				; must be a mushroom or end of line

; going up or down now?

				LDA #$00						; ACC back to 0
				SEC								; set carry

				LDX CURRENTPEDE					; X = currentpede
UPORDOWN		ROL								; ROL carry into A
				DEX								; loop on X
				BPL UPORDOWN
				AND	REVERSEPEDES				; bit in position AND to check REVERSEPEDES
				BEQ DOWNPEDE

UPPEDE			LDA CURRENTPEDE	
				CLC			
				ROL
				TAX	
				LDY PEDECOORDS,X				; DEC PEDE ROW
				DEY
				TYA
				STA PEDECOORDS,X				; otherwise, keep climbing up
				CMP #$13						; what's the bounce point? #$14?	
				BEQ UPPEDE2
				JMP EVENORODDROW				
			; above #$14, head back down
UPPEDE2			LDA #$00
				SEC						
				LDY CURRENTPEDE					; Y = currentpede
BACKDOWNPEDE	ROL								; ROL carry into A
				DEY								; loop on Y
				BPL BACKDOWNPEDE
				EOR REVERSEPEDES				; OR with REVERSEPEDES
				STA REVERSEPEDES				; store new REVERSEPEDES
				JMP EVENORODDROW				; continue as down.
				
DOWNPEDE		LDA CURRENTPEDE	
				CLC			
				ROL
				TAX	
				LDY PEDECOORDS,X				; INC PEDE ROW
				INY
				TYA
				STA PEDECOORDS,X				; store in PEDE.ROW
				
				CMP #$18						; if PLOTROW == #$18, done
				BNE JMPEVENODD					; spaghetti.
				; == 18, bottom of screen
; 				bottom of the screen? now what?
; 				need to start back up the screen for a bit, then back down. Oof.
				
				LDA #$16						; go back up a row
				STA PEDECOORDS,X				
				
				LDA #$00						; ACC back to 0
				SEC								; set carry

				LDX CURRENTPEDE					; X = currentpede
BACKPEDE		ROL								; ROL carry into A
				DEX								; loop on X
				BPL BACKPEDE
				ORA REVERSEPEDES				; OR with REVERSEPEDES
				STA REVERSEPEDES				; store new REVERSEPEDES
				
				
								
JMPEVENODD		JMP EVENORODDROW				; X = (PEDE.ROW)			
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
						STA CV ; PLOTROW				
						
			
						JSR RND					; returns with 0-ff in A
						ROR						; 1/2
						TAX						; random steps between mushrooms in X
		
SHROOMROW				DEC CV ; PLOTROW				; next row up
						BNE SHROOMROW2			; not yet done, next row
						
						LDA	SHROOMCOUNT			; row 0 AND shroomcount 0? All done.
						BEQ SHROOMSDONE			; 
						
						LDA #$16				; still not done, reset at row 23
						STA CV ; PLOTROW
												
SHROOMROW2				LDA #$28				; start at column 40
						STA CH ; PLOTCOLUMN
		
SHROOMCOL				DEC CH ; PLOTCOLUMN		; next column
						BEQ SHROOMROW			; column == 0? next row
						DEX						; otherwise, DEX and check if it's mushroom time
						BNE SHROOMCOL			; x=0?
						LDA #$D0 ; ?				; shroom char
;						STA CHAR
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

DRAWLIVES						
						LDX #$00
						STX CV ; PLOTROW					; start at row 0, column 40
						LDX #$25
						STX CH ; PLOTCOLUMN
						LDA #$F0 							; player icon						
;						STA CHAR
						LDX PROGRESS						; for each PROGRESS, dec column
						
DRAWLIVES2				JSR PLOTQUICK 						; increments CH automatically. feh.
						DEX
						BNE DRAWLIVES2
															; repeat draw.
						RTS
;/DRAWLIVES



UPDATESCORE				; takes A and adds it to PLAYERSCORE+3
						SED									; decimal mode
						CLC	
						ADC PLAYERSCORE+3					; tens/ones					
						STA PLAYERSCORE+3					
						BCC SCOREDONE						; carry set? add to next digit.
						LDA #$00
						ADC PLAYERSCORE+2					; 1000/100					
						STA PLAYERSCORE+2
						BCC SCOREDONE						; carry set? add to next digit.
						LDA #$00
						ADC PLAYERSCORE+1					; 100.000/10.000					
						STA PLAYERSCORE+1
						BCC SCOREDONE						; carry set? add to next digit.
						LDA #$00
						ADC PLAYERSCORE 					; 10.000.000/1.000.000					
						STA PLAYERSCORE 
SCOREDONE				CLD
						
						; prints score at col #$1D, row 0
						LDA #$1D
						STA CH
						LDA #$00
						STA CV
						VTAB
						LDA PLAYERSCORE
						JSR PRBYTE
						LDA PLAYERSCORE+1
						JSR PRBYTE
						LDA PLAYERSCORE+2
						JSR PRBYTE
						LDA PLAYERSCORE+3
						JSR PRBYTE
						
SETHISCORE				; compare bytes of PLAYERSCORE with HISCORE
						CLC
						LDA HISCORE				; +0 equal, check score+1
						CMP PLAYERSCORE
						BCC	NEWHISCORE				; PLAYERSCORE higher than HISCORE
						BNE KEEPHISCORE

						LDA HISCORE+1			; +1 equal, check +2
						CMP PLAYERSCORE+1
						BCC	NEWHISCORE				; PLAYERSCORE higher than HISCORE
						BNE KEEPHISCORE

						LDA HISCORE+2			; +2 equal, check +3
						CMP PLAYERSCORE+2
						BCC	NEWHISCORE				; PLAYERSCORE higher than HISCORE
						BNE KEEPHISCORE

						LDA HISCORE+3
						CMP PLAYERSCORE+3
						BCC	NEWHISCORE				; PLAYERSCORE higher than HISCORE
						BNE KEEPHISCORE				; player lower, no new hiscore


						
						
NEWHISCORE				; copy the PLAYERSCORE to HISCORE and display						
						LDA PLAYERSCORE+3
						STA HISCORE+3
						LDA PLAYERSCORE+2
						STA HISCORE+2
						LDA PLAYERSCORE+1
						STA HISCORE+1
						LDA PLAYERSCORE
						STA HISCORE

DISPLAYHISCORE			; prints score at col #$1D, row 0
						LDA #$10
						STA CH
						LDA #$00
						STA CV
						VTAB
						LDA HISCORE
						JSR PRBYTE
						LDA HISCORE+1
						JSR PRBYTE
						LDA HISCORE+2
						JSR PRBYTE
						LDA HISCORE+3
						JSR PRBYTE


						
KEEPHISCORE				RTS

**************************************************
*	blanks the screen
**************************************************
FILLSCREENFAST						; 5,403 instructions

				LDA #$A0			; space
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
;				TXA								; save X
;				PHA
				
				VTAB								
;				LDA CHAR
				JMP COUT						; sends out through ENTRY

;				PLA
;				TAX								; restore X
;				RTS
				
;/PLOTQUICK			   



ERASEQUICK
			
				VTAB
				STY $01
				JMP ZEROBYTES
													
;/ERASEQUICK
**************************************************
*	GETS one CHAR at PLOTROW,PLOTCOLUMN - value returns in Accumulator - clobbers Y
**************************************************
GETCHAR
				LDY CV 					; PLOTROW
				LDA LoLineTableL,Y
				STA $0
				LDA LoLineTableH,Y
				STA $1       		  	; now word/pointer at $0+$1 points to line 
				LDY CH 					; PLOTCOLUMN
				LDA ($0),Y  			; byte at row,col is now in accumulator
				RTS
;/GETCHAR					   



VTAB			MAC
				LDY CV							; sets the Vertical Row memory loc. for COUT
				LDA LoLineTableH,Y
				STA BASL+1
				LDA LoLineTableL,Y
				STA BASL
            	<<<            					; End of Macro


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
				LDA	PLAYERSCORE+3	;	$4E				; #$55
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
					DS \
PEDECOORDS			HEX 00,07,00,06,00,05,00,04,00,03,00,02,00,01,00,00			; row/col byte pairs for each segment of the OCTOPEDE
PLAYERMISSILE		HEX FF,FF,E0												; row, column, displaybyte


PLAYERSCORE			DS 4							; DEC mode 0 - 99999999

HISCORE				DS 4							; DEC mode 0 - 99999999
		


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



********************************
*   AL31-CHARACTER GENERATOR   *
********************************


HOOK  		LDA   #ENTRY     ; PRODUCES LOW BYTE
      		STA   CSW
      		LDA   #>ENTRY    ; #> PRODUCES HIGH BYTE
      		STA   CSW+1

			RTS


ENTRY    	STY $01 			; stow Y for later
			CMP #$A0			; CHAR = space? skip the math and zero the bytes
			BEQ ZEROBYTES

EVEODDCOL	STA $00				;PHA	; STORE CHAR
								;PHA	; SAVE Y, since it gets clobbered

			LDY	#$00
			STY	TABLEPOS+1			; tablepos hi byte

			LDA $00
			CMP #$BA				; 0-9?
			BCC CLEARHI

			LDA	CH					; horiz column
			AND	#$01				; even or odd?
			ROR						; odd bit into carry

			LDA $00					; CHAR back			
			ADC	#$00				; add carry to CHAR, odd ones = CHAR + 1


CLEARHI		AND	#$7F       			; CLEAR HI BIT

CALC1		SEC
     		SBC	#$20							; CHAR < 96
     		ASL				;TABLEPOS      		; *2 = CHAR < 192
     		ASL				;TABLEPOS      		; *4 < 384
     		ROL	TABLEPOS+1	
     		ASL				;TABLEPOS      		; *8 < 768
     		ROL	TABLEPOS+1
     		STA	TABLEPOS      		
*
* TABLEPOS = (ASCII - $20) * 8 BYTES PER CHAR
*
 			CLC
 			LDA	#CHARTABLE     		; LOW BYTE
 			ADC	TABLEPOS
 			STA	TABLEPOS
 			LDA	#>CHARTABLE    		; HIGH BYTE
 			ADC	TABLEPOS+1
 			STA	TABLEPOS+1     		; TABLEPOS = TABLEPOS + CHARTABLE ADDR

CALC2 		CLC
      		LDA	BASL				; low byte of GR address
      		ADC	CH					; add horiz offset
      		STA	SCRN				; set HR low byte
      		LDA	BASL+1				; get GR hi BYTE
      		ADC	#$1C				; bump into HR space
      		STA	SCRN+1     			; SCRN = BASL + CH + $1C00

GETBYTE		LDY	#$00			
G1     		LDA	(TABLEPOS),Y		; first byte of character at TABLEPOS
       		STA	(SCRN),Y			; pop into HR screen 
INC    		INY						; next byte
       		CLC	
       		LDA	SCRN				; adjust for next HR address
       		ADC	#$FF
       		STA	SCRN
       		LDA	SCRN+1
       		ADC	#$03
       		STA	SCRN+1     			; SCRN=SCRN+$3FF
*
* $3FF TO MAKE UP FOR GROWING VALUE OF 'Y'
*
DONE?		CPY	#$08
     		BCC	G1

YES			LDA $00					;PLA
   			LDY $01					;TAY	; RESTORE Y
									;PLA	; RESTORE CHAR
OUT			JMP	COUT3



ZEROBYTES	CLC
      		LDA	BASL				; low byte of GR address
      		ADC	CH					; add horiz offset
      		STA	SCRN				; set HR low byte
      		LDA	BASL+1				; get GR hi BYTE
      		ADC	#$1C				; bump into HR space
      		STA	SCRN+1     			; SCRN = BASL + CH + $1C00

			LDY	#$00			
G2     		LDA	#$00				; Zero out the pixels
    	   	STA	(SCRN),Y			; pop into HR screen 
    		INY						; next byte
       		CLC	
       		LDA	SCRN				; adjust for next HR address
       		ADC	#$FF
       		STA	SCRN
       		LDA	SCRN+1
       		ADC	#$03
       		STA	SCRN+1     			; SCRN=SCRN+$3FF
			CPY	#$08
     		BCC	G2

			LDA #$A0				;PLA
   			LDY $01					;TAY	; RESTORE Y
			JMP	COUT3






COUT3								; mine. doesn't increment CV on CH rollover
			LDY CH
			STA (BASL),Y
			INC CH
			RTS


			
			DS \					; CHAR TABLE now aligned with page boundary, 
									; so each 8 bytes will stay on a single hi byte address
CHARTABLE	EQU *

         HEX   0000000000000000 ; SPACE				A0
         HEX   0000000000000000 ; BLANK				A1
         HEX   0000000000000000 ; !
         HEX   0000000000000000 ; !
         HEX   0000000000000000 ; !
         HEX   0000000000000000 ; !
         HEX   1414140000000000 ; "
         HEX   14143E143E141400 ; #
         HEX   083C0A1C281E0800 ; $
         HEX   0626100804323000 ; %
         HEX   040A0A042A122C00 ; &
         HEX   0810202020100800 ; )
         HEX   082A1C081C2A0800 ; *
         HEX   0008083E08080000 ; +
         HEX   0000000000000804 ; ,
         HEX   0000003E00000000 ; -
         HEX   1C22322A26221C00 ; 0					B0
         HEX   080C080808081C00 ; 1
         HEX   1C22201804023E00 ; 2
         HEX   3E20101820221C00 ; 3
         HEX   101814123E101000 ; 4
         HEX   3E021E2020221C00 ; 5
         HEX   1804021E22221C00 ; 6
         HEX   3E20100804040400 ; 7
         HEX   1C22221C22221C00 ; 8
         HEX   1C22223C20100C00 ; 9					B9

         HEX   1008040204081000 ; <						BA
         HEX   1008040204081000 ; <						BB
         HEX   1008040204081000 ; <						BC
         HEX   1008040204081000 ; <						BD
         HEX   D5D5FFFFFFFFD5D5 ; = progress bar		BF
         HEX   AAAAFFFFFFFFAAAA ; = progress bar		BE
 
         HEX   00007E7F7F7E2A2A ; C0 PEDE <-			C0
    ;			0000 0000     
    ;			0000 0000     
    ;			0111 1110     
    ;			0111 1111     
    ;			0111 1111     
    ;			0111 1110     
    ;			0010 1010     
    ;			0010 1010     

         HEX   00007E7F7F7E5454 ; C0 PEDE <-			C1
    ;			0000 0000     
    ;			0000 0000     
    ;			0111 1110     
    ;			0111 1111     
    ;			0111 1111     
    ;			0111 1110     
    ;			0101 0100     
    ;			0101 0100     

         HEX   00003F7F7F3F2A2A ; C2 PEDE ->			C2
    ;			0000 0000     
    ;			0000 0000     
    ;			0011 1111     
    ;			0111 1111     
    ;			0111 1111     
    ;			0011 1111     
    ;			0010 1010     
    ;			0010 1010     
         
         HEX   00003F7F7F3F1515 ; C2 PEDE ->			C3
    ;			0000 0000     
    ;			0000 0000     
    ;			0011 1111     
    ;			0111 1111     
    ;			0111 1111     
    ;			0011 1111     
    ;			0001 0101     
    ;			0001 0101     
         
         

         HEX   D0D0BFFFFFBF2828 ; C6 PEDE HEAD ->		C4
    ;			1101 0000     
    ;			1101 0000     
    ;			1011 1111     
    ;			1111 1111     
    ;			1111 1111     
    ;			1011 1111     
    ;			0010 1000     green
    ;			0010 1000     

         HEX   A0A0BFFFFFBF5454 ; C6 PEDE HEAD ->		C5
    ;			1010 0000     
    ;			1010 0000     
    ;			1011 1111     
    ;			1111 1111     
    ;			1111 1111     
    ;			1011 1111     
    ;			0101 0100     green
    ;			0101 0100     

         HEX   8585FEFFFFFE2828 ; C4 PEDE HEAD <-		C6
    ;			1000 0101     
    ;			1000 0101     
    ;			1111 1110     
    ;			1111 1111     
    ;			1111 1111     
    ;			1111 1110     
    ;			0010 1000     green
    ;			0010 1000     

          HEX   8A8AFEFFFFFE5454 ; C4 PEDE HEAD <-		C7
    ;			1000 1010     
    ;			1000 1010     
    ;			1111 1110     
    ;			1111 1111     
    ;			1111 1111     
    ;			1111 1110     
    ;			0101 0100     green
    ;			0101 0100     

              
         HEX   0101247070541111 ; J						C8 - SPIDER LEFT
	;			0000 0001
	;			0000 0100
	;			0010 0100
	;			0111 0000
	;			0111 0000
	;			0101 0100
	;			0001 0001
	;			0001 0001

         HEX   0208407070280202 ; K						C9 - SPIDER LEFT ODD
	;			0000 0010
	;			0000 1000
	;			0100 0000			green eyes
	;			0111 0000			white body
	;			0111 0000
	;			0010 1000
	;			0000 0010
	;			0000 0010

         HEX	4010020707154141 ; H					CA - SPIDER RIGHT
	;			0100 0000	
	;			0001 0000	
	;			0000 0010	
	;			0000 0111	
	;			0000 0111	
	;			0001 0101	
	;			0100 0001	
	;			0100 0001	
 
         HEX	20200907070A2222 ; I						CB - SPIDER RIGHT ODD
	;			0010 0000	
	;			0000 1000	
	;			0000 1001	
	;			0000 0111	
	;			0000 0111	
	;			0000 1010	
	;			0010 0010	
	;			0010 0010	




         HEX   0202020202023E00 ; L
         HEX   22362A2A22222200 ; M
         HEX   2222262A32222200 ; N
         HEX   1C22222222221C00 ; O
         
         HEX   BEAAAAAAFF181818 ; : mushroom high	EVEN D0
	;	         1011 1110			; ORANGE top
	;	         1010 1010
	;	         1010 1010
	;	         1010 1010
	;	         1111 1111			; white line
	;	         0001 1000			; white bottom
	;	         0001 1000
	;	         0001 1000

         HEX   BED5D5D5FF181818 ; ; mushroom high	ODD D1
	;	         1011 1110			; ORANGE top
	;	         1101 0101
	;	         1101 0101
	;	         1101 0101
	;	         1111 1111			; white line
	;	         0001 1000			; white bottom
	;	         0001 1000
	;	         0001 1000
         HEX   1E22221E0A122200 ; R
         HEX   1C22021C20221C00 ; S
         HEX   3E08080808080800 ; T
         HEX   2222222222221C00 ; U
         HEX   2222222222140800 ; V
         HEX   2222222A2A362200 ; W
         HEX   2222140814222200 ; X
         HEX   2222221408080800 ; Y
         HEX   3E20100804023E00 ; Z


        HEX   3E06060606063E00 ; [
        HEX   3E06060606063E00 ; [
        
        HEX   3E06060606063E00 ; [
         HEX   0002040810200000 ; \
         HEX   0002040810200000 ; \
         
         
         HEX   00000000FF181818 ; _ mushroom low	E0
	;	         0000 0000
	;	         0000 0000
	;	         0000 0000
	;	         0000 0000
	;	         1111 1111
	;	         0001 1000			; white bottom
	;	         0001 1000
	;	         0001 1000
         
         
         HEX   00000000FF181818 ; _ mushroom low	E1
	;	         0000 0000
	;	         0000 0000
	;	         0000 0000
	;	         0000 0000
	;	         1111 1111
	;	         0001 1000			; white bottom
	;	         0001 1000
	;	         0001 1000

         HEX   02021E2222221E00 ; b
         HEX   00003C0202023C00 ; c
         HEX   20203C2222223C00 ; d
         HEX   00001C223E023C00 ; e
         HEX   1824041E04040400 ; f
         HEX   00001C22223C201C ; g
         HEX   02021E2222222200 ; h
         HEX   08000C0808081C00 ; i
         HEX   100018101010120C ; j
         HEX   020222120E122200 ; k
         HEX   0C08080808081C00 ; l
         HEX   0000362A2A2A2200 ; m
         HEX   00001E2222222200 ; n
         HEX   00001C2222221C00 ; o

		HEX		949494B6B6BEFFFF ; ^ player		F0
						;         1001 0100
						;         1001 0100
						;         1001 0100
						;         1011 0110
						;         1011 0110
						;         1011 1110
						;         1111 1111
						;         1111 1111
         
         HEX	8A8A8A9B9B9FFFFF ; ^ player		F1
						;         1000 1010
						;         1000 1010
						;         1000 1010
						;         1001 1011
						;         1001 1011
						;         1001 1111
						;         1111 1111
						;         1111 1111

         HEX   00003A0602020200 ; r
         HEX   00003C021C201E00 ; s
         HEX   04041E0404241800 ; t
         HEX   0000222222322C00 ; u
         HEX   0000222222140800 ; v
         HEX   000022222A2A3600 ; w
         HEX   0000221408142200 ; x
         HEX   0000222214080806 ; y
         HEX   00003E1008043E00 ; z
         HEX   0000000018181800 ; . bullet low 		FB
         HEX   0000000018181800 ; . bullet low 		FC
         HEX   1818180000000000 ; '  bullet high 	FD
         HEX   1818180000000000 ; '  bullet high 	FE
         HEX   7F7F7F7F7F7F7F7F ; CURSOR