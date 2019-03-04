
#include p18f87k22.inc
;List of file registers used
;paddle one coords, xmin F0, xmax F1, ymin F2, ymax F3
;paddle two coords, xmin F5, xmax F6, ymin F7, ymax F8
;paddle one coords, xmin FA, xmax FB, ymin FC, ymax FD
;ball direction stored in, E0 for x and E1 for y.
;Player points stored in 0x91 and 0x92
;Keypad input store in 0x48, 0x58
;LCD variables are assigned in the 0x2X range from 0x21 to 0x25. (see lab book for details)
;Uart_counter at 0x27
;difference between ball and paddle ymax stored in D1 for left and D0 for right 
;Win values stored at 0x95 and 0x96

	code
	org 0x0

    extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
    extern	LCD_Setup, LCD_Write_Message, LCD_clear	    ; external LCD subroutines	
	
	org 0x100		    ; Main code starts here at address 0x100


acs0        udata_acs   ; named variables in access ram
x_min       res 1   ; reserve 1 byte for 
x_max	    res 1   ; reserve 1 byte for variable LCD_cnt_h
y_min       res 1   ; reserve 1 byte for ms counter
y_max	    res 1   ; reserve 1 byte for temporary use
ballvy	    res 1   ; reserve 1 byte for counting through nessagedelay_count res 1   ; reserve one byte for counter in the delay routine
ballvx	    res 1 ;
delay_count res 1   ; reserve one byte for counter in the delay routine	
myTable	    udata   0x700    ; reserve data anywhere in RAM (here at 0x700)
myTable2    udata   0x500
myArray	    res	    0x80    ; reserve 128 bytes for welcome message data
myArray2    res	    0x80	    
myTable3    udata   0x600    ; reserve data anywhere in RAM (here at 0x700)
myTable4    udata   0x400
myArray3    res	    0x80
rst	code	0    ; reset vector	    
	
myTable2 data	    "0-0\n"
	constant    myTable2_l=.4	; length of data
		    	
myTable data	    "Hold 1 to start\n"	; message, plus carriage return
	constant    myTable_l=.16	; length of data
	movlw	0x00
	movwf	0x96	; records if player 2 won
	movwf	0x95	; records if player 1 won
	
setup	
	movlw	0x00	
	cpfseq	0x95	   ; check for value signifying win
	call	P2WIN
	cpfseq	0x96	   ; check for value signifying win
	call	P1WIN
	movlw	0x00
	movwf	0x96	; records if player 2 won
	movwf	0x95	; records if player 1 won	
	
	bcf	EECON1, CFGS	; point to Flash program memory  
	bsf	EECON1, EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup LCD
standby
	lfsr	FSR0, myArray	; Load FSR0 with address in RAM	
	movlw	upper(myTable)	; address of data in PM	
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	movlw	myTable_l	; bytes to read
	movwf 	0x29		; our counter register
loop 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0
	movff	FSR0, 0x61
	decfsz	0x29		; count down to zero
	bra	loop		; keep going until finished
		
	movlw	myTable_l-1	; output message to LCD (leave out "\n")
	lfsr	FSR2, myArray
	call	LCD_Write_Message
	
	movlw	myTable_l	; output message to UART
	lfsr	FSR2, myArray
	call	UART_Transmit_Message	
	movlw	0x00
	movwf	0x54		; loop over keyboard, waiting for a 1 to start the game
	call	column1
	movlw	0xF3
	cpfsgt	0x54
	goto	$-8
	
	call	LCD_clear
			    ; now ball direction initialisations
	movlw	0x06	    ; ball starts moving inplayer
	
	movwf	0xE0
 
start1	code      ; only performed once, and everytime a point is scored

	movlw	0x00
	movwf	0x91
	movwf	0x92
	
start   clrf	TRISE		; Set PORTD as all outputs
	clrf	LATE		; Clear PORTD outputs
	clrf	TRISD
	clrf	LATD
	clrf	TRISB		; Set PORTB as all outputs
	clrf	LATB	
	bsf	PADCFG1,REPU,BANKED
	clrf	LATC
	clrf	LATJ 
	clrf	TRISC

			    ;now paddle1 intialisations		    
	movlw   0xFA
	movwf	0xF0	;x_min start value
	movlw	0xFE
	movwf	0xF1	;x_max start value
	movlw	0x55
	movwf	0xF2	;y_min start value
	movlw   0x99	
	movwf   0xF3	;y_max start value
	
			     ;now paddle2 intialisations
	movlw   0x05
	movwf	0xF5	;x_min start value
	movlw	0x09
	movwf	0xF6	;x_max start value
	movlw	0x55	
	movwf	0xF7	;y_min start value
	movlw   0x99	
	movwf   0xF8	;y_max start value
		
			    ;now ball initialisations
	movlw   0x7D
	movwf	0xFA	;x_min start value
	movlw	0x83
	movwf	0xFB	;x_max start value
	movlw	0x7D	
	movwf	0xFC	;y_min start value
	movlw   0x83	
	movwf   0xFD	;y_max start value
			    ; now ball speed intialisations
	movlw	0x05	    
	movwf	ballvx
	movlw	0x02
	movwf	ballvy	

	movlw	0x06	    ;ball start direction (5=left, 6=right)
	movwf	0xE1
			    ; paddle 1 size variable
	movf	0xF8, 0	    ; transport the coordinates of paddle 1 to a 
	movwf	0xD3	    ; different working register to not override
	movf	0xF7, 0
	subwf	0xD3	    
			    ; paddle 2 size variable	
	movf	0xF3, 0	    ; transport the coordinates of paddle 1 to a 
	movwf	0xD4	    ; different working register to not override
	movf	0xF2, 0
	subwf	0xD4
	
	
	call	LCD_clear
			    ; printing the score
	movlw	0x30	    ; offset for easy number printing (in asssemly ascii
	movff	0x92, 0x93  ; numbers start at 0x30) 
	addwf	0x93
	movlw	0x30	    ; offset for easy number printing
	movff	0x91, 0x94
	addwf	0x94
	
	movlw	0x00		;putting the scores onto the storing array
	lfsr	FSR2, myArray2
	movff	0x93, PLUSW2
	movlw	0x02
	lfsr	FSR2, myArray2
	movff	0x94, PLUSW2
	
	
results
	lfsr	FSR2, myArray2	; Load FSR0 with address in RAM	
	movlw	upper(myTable2)	; address of data in PM	
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(myTable2)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(myTable2)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	movlw	myTable2_l	; bytes to read
	movwf 	0x29		; counter register
resloop 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0
	
	decfsz	0x29		; count down to zero
	bra	resloop		; keep going until finished
		
	movlw	myTable2_l-1	; output message to LCD (leave out "\n")
	lfsr	FSR2, myArray2
	call	LCD_Write_Message
	
	movlw	myTable2_l	; output message to UART
	lfsr	FSR2, myArray2
	call	UART_Transmit_Message		
	

	
	
	
	
	
jump         ;main loop
	movlw	0x02	; delays within drawing
	movwf	0x55	; need to be initialized at the start of every loop
	movlw	0x02		  
	movwf	0x56
	movlw	0x02
	movwf	0x57     ; end of delays within drawing
		
	; we now draw each of the objects, paddle1, paddle2 and ball
paddle1                 
	movf	0xF0, 0 
	movwf	x_min	;stored in 0x02
	movf	0xF1, 0 
	movwf	x_max	;stored in 0x00
	movf	0xF2, 0 
	movwf	y_min	;stored in 0x01
	movf	0xF3, 0 
	movwf   y_max	;stored in 0x03
	call draw
	decfsz	0x56	;allows  for drawing multiple times if necessary
	bra paddle1

	
paddle2
	movf	0xF5, 0 
	movwf	x_min	;stored in 0x02		
	movf	0xF6, 0  
	movwf	x_max	;stored in 0x00
	movf	0xF7, 0 	
	movwf	y_min	;stored in 0x01
	movf	0xF8, 0 
	movwf   y_max	;stored in 0x03
	call draw
	decfsz	0x57
	bra paddle2

ball
	movf	0xFA, 0 
	movwf	x_min	;stored in 0x02
	movf	0xFB, 0 
	movwf	x_max	;stored in 0x00
	movf	0xFC, 0 	
	movwf	y_min	;stored in 0x01
	movf	0xFD, 0 	
	movwf   y_max	;stored in 0x03
	
	call draw	
	decfsz	0x55   ; delay
	bra ball
	call ballmovement
keypadcheck
	call  column1   ; to get keypad 1 result
	call  column2	; to get keypad 2 result
keypadoutput 

	movf  0x55, W	    ; adding the two outputs, column and row, to get one
	andwf  0x54	    ; variable for each button
	movff  0x54, 0x58
	


	movf  0x45, W	    ; adding the two outputs, column and row, to get one
	andwf  0x44	    ; variable for each button
	movff  0x44, 0x48
	
inputactivation
	call paddlemovement	
	bra pointchecks	    
	bra jump	    
	
	
ballmovement
	movf	ballvx, 0   ;
	movwf	0x21			; changeable ball velocity
	movf	ballvy, 0
	movwf	0x20			; changeable ball velocity
ballcheck
	movlw	0xFB
	cpfslt	0xFB
	decf	0xE0	;x max right side check/reflect
	
	movlw	0xFB	 
	cpfslt 0xFD
	decf	0xE1	;y max top side check/reflect
	
	movlw	0x05
	cpfsgt	0xFA
	incf	0xE0	;x min left side check/reflect
	
	movlw	0x05	 
	cpfsgt 0xFC
	incf	0xE1	;y min bottom side check/reflect
	
	
	
	
	
ballymove	
	movlw	0x05
	cpfsgt	0xE1
	bra ydec
yinc			; increments the ball's ymax and ymin
	incf    0xFC
	incf	0xFD
	decf	0x20	
	movlw	0x01
	cpfslt	0x20	; loops over this as many times as to make ballvy
	bra ballymove
	bra ballxmove	; checks x
ydec			; decrements the ball's ymax and ymin
	decf    0xFC
	decf	0xFD
	decf	0x20
	movlw	0x01
	cpfslt	0x20	; loops over this as many times as to make ballvy
	bra ballymove
	bra ballxmove	; checks x
	
ballxmove
	movlw	0x05
	cpfsgt	0xE0
	bra xdec	
xinc			; increments the ball's xmax and xmin
	
	incf	0XFA
	incf	0xFB
	decf	0x21
	movlw	0x01
	cpfslt	0x21	; loops over this as many times as to make ballvx
	bra ballxmove
	bra finmove	   ; end movement
xdec			; decrements the ball's xmax and xmin
	decf    0xFA
	decf	0xFB
	decf	0x21
	movlw	0x01
	cpfslt	0x21	; loops over this as many times as to make ballvx
	bra ballxmove
	bra finmove	; end movement
	
finmove	
	
	movf	0xFA, 0 	; reupdates with new coordinates for the objects
	movwf	x_min	;0x02
	movf	0xFB, 0 
	movwf	x_max	;0x00
	movf	0xFC, 0 	
	movwf	y_min	;0x01
	movf	0xFD, 0 	
	movwf   y_max	;0x03
	call draw
	return

	
	
draw
	movff	y_max, 0x0A       ; Draw funciton works by creating each side of
	movff	y_min, 0x0B	  ; each square seperately 
    	movff	x_max, 0x0C	  ; Values are moved to new registers to not 
	movff	x_min, 0x0D	  ; overide them
yfall				  ; All four sides work by drawing repeated 
	movlw	0x00		  ; points while incrementing for rise functions
	movwf	LATB, ACCESS	  ; and decrementing for fall funtions 
	decf	0x0A		  ; They use port B to send the information 
	movff	0x0A, PORTD	  ; to the oscilloscope
	movlw	0x01
	movwf	LATB, ACCESS
	call	delay2		  ; Delay necesssary to keep each point on for 
	call	delay2		  ; longer, thus creating a brighter image 
	call	delay2
	call	delay2
	movf	y_min, 0	  ; When the value reaches the end point 
	cpfslt 	0x0A		  ; like here y_min for lowering y_max,
	bra yfall		  ; the loop is stopped
				  
xfall				    ; same for x falling
	movlw	0x00		   
	movwf	LATB, ACCESS
	decf	0x0C
	movff	0x0C, PORTE
	movlw	0x10
	movwf	LATB, ACCESS
	call	delay2
	call	delay2
	call	delay2
	call	delay2
	movf 	x_min, 0
	cpfslt 	0x0C
	bra xfall
	
yrise				; now with y rising
	movlw	0x00
	movwf	LATB, ACCESS
	incf	0x0B
	movff	0x0B, PORTD
	movlw	0x01
	movwf	LATB, ACCESS
	call	delay2
	call	delay2
	call	delay2
	call	delay2
	movf	y_max, 0 
	cpfsgt 	0x0B
	bra yrise	

xrise				; now with x rising
	movlw	0x00

	movwf	LATB, ACCESS
 	incf	0x0D
	movff	0x0D, PORTE
	movlw	0x10
	movwf	LATB, ACCESS
	call	delay2
	call	delay2
	call	delay2
	call	delay2
	movf 	x_max, 0
	cpfsgt 	0x0D
	bra xrise
	
	
	return
	
;Keypad1
	
column1
	movlw 0x0F		    ;basic keypad code, the port is first
	movwf  TRISJ, ACCESS	    ;half-lowered then raised, which gives us 
	call  delay2		    ;where it was pressed
	movlw  0xFF
	movwf  0x57, ACCESS
	movff  PORTJ, 0x54
	movff  0x57, PORTJ
    
row1					
	movlw 0xF0		   ;same as prevous except opposite (checks rows instead of columns)
	movwf  TRISJ, ACCESS
	call  delay2
	movlw  0xFF
	movwf  0x56, ACCESS
	movff  PORTJ, 0x55
	movff  0x56, PORTJ

	return

;keypad 2
column2				    ; same code but for keypad 2,
	movlw 0x0F		    ; different registers and port
	movwf  TRISC, ACCESS 
	call  delay2
	movlw  0xFF
	movwf  0x47, ACCESS
	movff  PORTC, 0x44
	movff  0x47, PORTC
    
row2
	movlw 0xF0
	movwf  TRISC, ACCESS
	call  delay2
	movlw  0xFF
	movwf  0x46, ACCESS
	movff  PORTC, 0x45
	movff  0x46, PORTC


	return
	
paddlemovement


keypadpaddle1input
	movlw	0x56	; ((value of keypad input when '1' pressed) -1)
	cpfslt	0x48	; if keypad input (1) less than this value skip
	bra paddle1moveup   ; move paddle up
	movlw	0x41	; minimum value in 0x48 +1 
	cpfslt	0x48	; if keypad input (1) isnt '1' and isnt nothing, must be move down
	bra paddle1movedown ; move paddle down
	
keypadpaddle2input
	movlw	0x86	; ((value of keypad input when '1' pressed) -1)
	cpfslt	0x58	; if keypad input (2) less than this value skip
	bra paddle2moveup   ; move paddle up
	movlw	0x01	; minimum value in 0x48 +1 
	cpfslt	0x58	; if keypad input (2) isnt '1' and isnt nothing, must be move down
	bra paddle2movedown ; move paddle down	
	return
	
paddle1moveup	
	movlw	0xFD	;roofcheck
	cpfslt	0xF3
	bra	keypadpaddle2input
	incf	0xF2;y_min
	incf	0xF2;y_min
	incf	0xF3;Y-max
	incf	0xF3;Y-max
	bra	keypadpaddle2input ; now check other keypad
paddle1movedown
	movlw	0x02	;floorcheck
	cpfsgt	0xF2
	bra	keypadpaddle2input
	decf	0xF2;y_min
	decf	0xF2;y_min
	decf	0xF3;Y-max
	decf	0xF3;Y-max
	bra	keypadpaddle2input  ; now check other keypad
	
paddle2moveup
	movlw	0xFD	;roofcheck
	cpfslt	0xF8
	return
	incf	0xF7	;y_min
	incf	0xF7	;y_min
	incf	0xF8	;y_max
	incf	0xF8	;y_max
	return	    ; both checks done return to drawing
	
paddle2movedown
	movlw	0x02	;floorcheck
	cpfsgt	0xF7
	return
	decf	0xF7	;y_min
	decf	0xF7	;y_min
	decf	0xF8	;y_max
	decf	0xF8	;y_max
	return	    ; both checks done return to drawing	
	
	
pointchecks
	movlw	0x05	; far side of x boundary on left
	cpfsgt	0xFA	; ball x_min
	bra collideleft	; checks if ball hits paddle when near boundary
	
	movlw	0xFA	; far side of x boundary on right
	cpfslt	0xFB	; ball x_max
	bra collideright	; checks if ball hits paddle when near boundary
	bra jump
	
collideright
	movf	0xF2, 0	; paddle1 ymin
	cpfsgt	0xFD	; ball ymax
	bra point2	; gives player 1 a point if ball ymax<paddle ymin
	movf	0xF3,0	; paddle1   ymax
	cpfslt	0xFC	; ball ymin
	bra point2	; gives player 1 a point if ball ymin>paddle ymax
			
	movf	0xF3, 0	;now checking where the ball hits the paddle
	movwf	0xD0	    
	movf	0xFD, 0
	subwf	0xD0	   ;distance between top of ball and top of paddle
	movlw	0x0D
	cpfsgt	0xD0
	bra	vy2up
	movlw	0x1B
	cpfsgt	0xD0	    ; checks where on the paddle the ball hits
	bra	vy1up	    ; changes vy based on this
	movlw	0x29
	cpfsgt	0xD0
	bra	vy0
	movlw	0x37
	cpfsgt	0xD0
	bra	vy1down	
	bra	vy2down
	
	
	
	
	bra jump		; if not branched (i.e. collides with paddle) return
	
collideleft	
	movf	0xF7, 0	; paddle2 ymin
	cpfsgt	0xFD	; ball ymax
	bra point1	; gives player 2 a point if ball ymax<paddle ymin
	movf	0xF8,0	; paddle2 ymax
	cpfslt	0xFC	; ball ymin
	bra point1	; gives player 2 a point if ball ymin<paddle ymax
	
	movf	0xF8, 0
	movwf	0xD1	    
	movf	0xFD, 0
	subwf	0xD1	   ;distance between top of ball and top of paddle
	movlw	0x0D
	cpfsgt	0xD1
	bra	vy2up
	movlw	0x1B
	cpfsgt	0xD1	    ; this checks where on the paddle the ball hits
	bra	vy1up	    ; changes vy based on this
	movlw	0x29
	cpfsgt	0xD1
	bra	vy0
	movlw	0x37
	cpfsgt	0xD1
	bra	vy1down	
	bra	vy2down
	
	bra jump		; if not branched (i.e. collides with paddle) return

point1
	movlw	0x06
	movwf	0xE0
	incf	0x91	; 0x91 and 0x92 are locations of player points
	movlw	0x09
	cpfsgt	0x91
	goto start	; restarts
	movlw	0x05
	movwf	0x95	; records if player 1 won
	goto setup
point2
	movlw	0x05
	movwf	0xE0
	incf	0x92	; 0x91 and 0x92 are locations of player points
	movlw	0x09
	cpfsgt	0x92
	goto start	; restarts	
	movlw	0x05
	movwf	0x96	; records if player 2 won
	goto setup
	
	; a delay subroutine if you need one, times around loop in delay_count
delay	decfsz	delay_count	; decrement until zero
	bra delay
	return	
	
	
delay2	movlw	0xFF
	movwf	delay_count
indelay	

	decfsz	delay_count	; decrement until zero
	bra indelay
	return	
	
P1WIN		;displays winning message for player 1
	call	LCD_clear
myTable3 data	    "PLAYER 1 WINS"
	constant    myTable3_l=.14	; length of data
	lfsr	FSR0, myArray3	; Load FSR0 with address in RAM	
	movlw	upper(myTable3)	; address of data in PM	
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(myTable3)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(myTable3)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	movlw	myTable3_l	; bytes to read
	movwf 	0x29		; our counter register
loop3 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0
	movff	FSR0, 0x61
	decfsz	0x29		; count down to zero
	bra	loop3		; keep going until finished
		
	movlw	myTable3_l-1	; output message to LCD (leave out "\n")
	lfsr	FSR2, myArray3
	call	LCD_Write_Message
	
	movlw	myTable3_l	; output message to UART
	lfsr	FSR2, myArray3
	call	UART_Transmit_Message
	movlw	0x00
	movwf	0x54
	call	column1
	movlw	0xF3
	cpfsgt	0x54
	goto	$-8
	return
	
P2WIN		;displays winning message f or player 2
	call	LCD_clear	
myTable4 data	    "PLAYER 2 WINS"
	constant    myTable4_l=.14	; length of data
	lfsr	FSR0, myArray3	; Load FSR0 with address in RAM	
	movlw	upper(myTable4)	; address of data in PM	
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(myTable4)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(myTable4)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	movlw	myTable4_l	; bytes to read
	movwf 	0x29		; our counter register
loop4 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0
	movff	FSR0, 0x61
	decfsz	0x29		; count down to zero
	bra	loop4		; keep going until finished
		
	movlw	myTable4_l-1	; output message to LCD (leave out "\n")
	lfsr	FSR2, myArray3
	call	LCD_Write_Message
	
	movlw	myTable4_l	; output message to UART
	lfsr	FSR2, myArray3
	call	UART_Transmit_Message	
	movlw	0x00
	movwf	0x54
	call	column1
	movlw	0xF3
	cpfsgt	0x54
	goto	$-8
	return	
	
	
vy2up			    ; now a set of functions to change ball y movement
	movlw	0x04
	movwf	ballvy
	movlw	0x06
	movwf	0xE1
	bra	jump	
	

vy1up			
	movlw	0x02	; only this value changes between functions, depends on where the ball hits the paddle
	movwf	ballvy
	movlw	0x06
	movwf	0xE1
	bra	jump
	
vy0
	movlw	0x00
	movwf	ballvy
	bra	jump
	
vy1down
	movlw	0x02
	movwf	ballvy	
	movlw	0x05
	movwf	0xE1
	bra	jump	
	
vy2down
	movlw	0x04
	movwf	ballvy
	movlw	0x05
	movwf	0xE1
	bra	jump		
	end
	

	
	
	
