	DSK LOADER

**************************************************
* boot stub at $2000 to BLOAD real program at $0800, JMP $0800
**************************************************
* Variables
**************************************************


**************************************************
* Apple Standard Memory Locations
**************************************************
CLRLORES  	EQU	$F832
LORES     	EQU	$C050
TXTSET    	EQU	$C051
MIXCLR    	EQU	$C052
MIXSET    	EQU	$C053
TXTPAGE1  	EQU	$C054
TXTPAGE2  	EQU	$C055
KEY       	EQU	$C000
C80STOREOF	EQU	$C000
C80STOREON	EQU	$C001
STROBE    	EQU	$C010
SPEAKER   	EQU	$C030
VBL       	EQU	$C02E
RDVBLBAR  	EQU	$C019       ;not VBL (VBL signal low
WAIT		EQU	$FCA8 
RAMWRTAUX 	EQU	$C005
RAMWRTMAIN	EQU	$C004
SETAN3    	EQU	$C05E       ;Set annunciator-3 output to 0
SET80VID  	EQU	$C00D       ;enable 80-column display mode (WR-only)
CLR80VID	EQU	$C00C
HOME 		EQU	$FC58		; clear the text screen
CH        	EQU	$24			; cursor Horiz
CV        	EQU	$25			; cursor Vert
VTAB      	EQU	$FC22       ; Sets the cursor vertical position (from CV)
COUT      	EQU	$FDED       ; Calls the output routine whose address is stored in CSW,
          	   	            ;  normally COUTI
STROUT		EQU	$DB3A 		;Y=String ptr high, A=String ptr low
		
ALTTEXT		EQU	$C055
ALTTEXTOFF	EQU	$C054
	
ROMINIT   	EQU $FB2F
ROMSETKBD 	EQU $FE89
ROMSETVID 	EQU $FE93
	
ALTCHAR		EQU	$C00F		; enables alternative character set - mousetext
	
BLINK		EQU	$F3
SPEED		EQU	$F1

BELL   		EQU	$FF3A     				; Monitor BELL routine
CROUT  		EQU	$FD8E     				; Monitor CROUT routine
PRBYTE 		EQU	$FDDA     				; Monitor PRBYTE routine
MLI    		EQU	$BF00     				; ProDOS system call
OPENCMD		EQU	$C8						; OPEN command index
READCMD		EQU	$CA						; READ command index
CLOSECMD	EQU	$CC						; CLOSE command index


**************************************************
* START - sets up various fiddly zero page bits
**************************************************

				ORG $2000						; PROGRAM DATA STARTS AT $2000

				JSR BLOAD						; BLOAD DATA
					
				JMP $0800						; jump to the new location
	
**************************************************
*	Load "OCTOPEDE" into memory at $0800
**************************************************


BLOAD   		JSR	OPEN    				;open "DATA"
       			JSR READ
       			JSR ERROR					
				JSR CLOSE
       			JSR ERROR					
       			RTS            				;Otherwise done
				
OPEN 			JSR	MLI       				;Perform call
       			DB	OPENCMD    				;CREATE command number
       			DW	OPENLIST   				;Pointer to parameter list
       			JSR	ERROR     				;If error, display it
       			LDA REFERENCE
       			STA READLIST+1
       			STA CLOSELIST+1
       			RTS				

READ			JSR MLI
				DB	READCMD
				DW	READLIST
				RTS

CLOSE			JSR MLI
				DB	CLOSECMD
				DW	CLOSELIST
				RTS
				
ERROR  			JSR	PRBYTE    				;Print error code
       			JSR	BELL      				;Ring the bell
       			JSR	CROUT     				;Print a carriage return
       			RTS				

OPENLIST		DB	$03						; parameter list for OPEN command
				DW	FILENAME
				DA	MLI-$400				; buffer snuggled up tight with PRODOS
REFERENCE		DB	$00						; reference to opened file
			
READLIST		DB	$04
				DB	$00						; REFERENCE written here after OPEN
				DB	$00,$08					; write to $0C00
				DB	$FF,$FF					; read as much as $FFFF - should error out with EOF before that.
TRANSFERRED		DB	$00,$00				

CLOSELIST		DB	$01
				DB	$00
				
FILENAME		DB	ENDNAME-NAME 			;Length of name
NAME    		ASC	'OCTOPEDE' 				;followed by the name
ENDNAME 		EQU	*


