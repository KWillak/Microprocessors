
#include p18f87k22.inc

	
	code
	org 0x0
	
	
	org 0x100		    ; Main code starts here at address 0x100


acs0        udata_acs   ; named variables in access ram
x_min       res 1   ; reserve 1 byte for 
x_max	    res 1   ; reserve 1 byte for variable LCD_cnt_h
y_min       res 1   ; reserve 1 byte for ms counter
y_max	    res 1   ; reserve 1 byte for temporary use
ballvy	    res 1   ; reserve 1 byte for counting through nessagedelay_count res 1   ; reserve one byte for counter in the delay routine
ballvx	    res 1 ;
delay_count res 1   ; reserve one byte for counter in the delay routine	
cyclecounter res 1

start1	code      ; only performed once, and everytime a point is scored

start   clrf	TRISE		; Set PORTD as all outputs
	clrf	LATE		; Clear PORTD outputs
	clrf	TRISD
	clrf	LATD
	clrf	TRISB		; Set PORTB as all outputs
	clrf	LATB	
	bsf	PADCFG1,REPU,BANKED
	clrf	LATC
	clrf	LATJ 
;	clrf	TRISC
;	clrf	TRISF
			    ;now paddle1 intialisations		    
	movlw   0xFA
	movwf	0xF0	;0x02
	movlw	0xFE
	movwf	0xF1	;0x00
	movlw	0x55
	movwf	0xF2	;0x01
	movlw   0x99	
	movwf   0xF3	;0x03
	
			     ;now paddle2 intialisations
	movlw   0x05
	movwf	0xF5	;0x02
	movlw	0x09
	movwf	0xF6	;0x00
	movlw	0x55	
	movwf	0xF7	;0x01
	movlw   0x99	
	movwf   0xF8	;0x03
		
			    ;now ball initialisations
	movlw   0x7D
	movwf	0xFA	;0x02
	movlw	0x83
	movwf	0xFB	;0x00
	movlw	0x7D	
	movwf	0xFC	;0x01
	movlw   0x83	
	movwf   0xFD	;0x03
			    ; now ball speed intialisations
	movlw	0x04
	movwf	ballvx
	movlw	0x02
	movwf	ballvy	
			    ; now ball direction initialisations
	movlw	0x06
	movwf	0xE0
	movlw	0x06
	movwf	0xE1
			    ; paddle 1 size variable
	movf	0xF8, 0
	movwf	0xD3
	movf	0xF7, 0
	subwf	0xD3	    
			    ; paddle 2 size variable	
	movf	0xF3, 0
	movwf	0xD4
	movf	0xF2, 0
	subwf	0xD4
	
	
jump
	movlw	0x02		;delays within drawing
	movwf	0x55		;
	movlw	0x02		  
	movwf	0x56
	movlw	0x02
	movwf	0x57; end of delays within drawing
		
		
	
	movlw   0x01
	movwf   cyclecounter	;this works for some reason, dont touch
	
paddle1
	movf	0xF0, 0 
	movwf	x_min	;0x02
	movf	0xF1, 0 
	movwf	x_max	;0x00
	movf	0xF2, 0 
	movwf	y_min	;0x01
	movf	0xF3, 0 
	movwf   y_max	;0x03
	call draw
	decfsz	0x56
	bra paddle1

	
paddle2
	movf	0xF5, 0 
	movwf	x_min	;0x02
	movf	0xF6, 0 
	movwf	x_max	;0x00
	movf	0xF7, 0 	
	movwf	y_min	;0x01
	movf	0xF8, 0 
	movwf   y_max	;0x03
	call draw
	decfsz	0x57
	bra paddle2

ball
	movf	0xFA, 0 
	movwf	x_min	;0x02
	movf	0xFB, 0 
	movwf	x_max	;0x00
	movf	0xFC, 0 	
	movwf	y_min	;0x01
	movf	0xFD, 0 	
	movwf   y_max	;0x03
	
	call draw	
	decfsz	0x55
	bra ball
	call ballmovement
kepyadcheck
	call  column1
	call  column2
keypadoutput 

	movf  0x55, W
	andwf  0x54
	movff  0x54, 0x58
	


	movf  0x45, W
	andwf  0x44
	movff  0x44, 0x48
	
inputactivation
	call paddlemovement
	bra pointchecks
	bra jump
	
	
ballmovement
	movf	ballvx, 0
	movwf	0x21
	movf	ballvy, 0
	movwf	0x20
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
yinc
	incf    0xFC
	incf	0xFD
	decf	0x20
	movlw	0x01
	cpfslt	0x20
	bra ballymove
	bra ballxmove
ydec	
	decf    0xFC
	decf	0xFD
	decf	0x20
	movlw	0x01
	cpfslt	0x20
	bra ballymove
	bra ballxmove
	
ballxmove
	movlw	0x05
	cpfsgt	0xE0
	bra xdec	
xinc	
	
	incf	0XFA
	incf	0xFB
	decf	0x21
	movlw	0x01
	cpfslt	0x21
	bra ballxmove
	bra finmove
xdec	
	decf    0xFA
	decf	0xFB
	decf	0x21
	movlw	0x01
	cpfslt	0x21
	bra ballymove
	bra finmove
	
finmove	
	
	movf	0xFA, 0 
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
	movff	y_max, 0x0A
	movff	y_min, 0x0B
	movff	x_max, 0x0C
	movff	x_min, 0x0D
yfall
	movlw	0x00
	movwf	LATB, ACCESS
	decf	0x0A
	movff	0x0A, PORTD
	movlw	0x01
	movwf	LATB, ACCESS
	call	delay2
	call	delay2
	call	delay2
	call	delay2
	movf	y_min, 0
	cpfslt 	0x0A
	bra yfall
	
xfall
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
	
yrise
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

xrise
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
	movlw 0x0F
	movwf  TRISJ, ACCESS 
	call  delay2
	movlw  0xFF
	movwf  0x57, ACCESS
	movff  PORTJ, 0x54
	movff  0x57, PORTJ
    
row1
	movlw 0xF0
	movwf  TRISJ, ACCESS
	call  delay2
	movlw  0xFF
	movwf  0x56, ACCESS
	movff  PORTJ, 0x55
	movff  0x56, PORTJ

	;movff  PORTC, PORTF

	return


column2
	movlw 0x0F
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
	movlw	0x86	; ((value of keypad input when '1' pressed) -1)
	cpfslt	0x48	; if keypad input (1) less than this value skip
	bra paddle1moveup   ; move paddle up
	movlw	0x01	; minimum value in 0x48 +1 
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

	incf	0xF2;y_min
	incf	0xF2;y_min
	incf	0xF3;Y-max
	incf	0xF3;Y-max
	bra	keypadpaddle2input ; now check other keypad
paddle1movedown
	decf	0xF2;y_min
	decf	0xF2;y_min
	decf	0xF3;Y-max
	decf	0xF3;Y-max
	bra	keypadpaddle2input  ; now check other keypad
	
paddle2moveup
	incf	0xF7	;y_min
	incf	0xF7	;y_min
	incf	0xF8	;y_max
	incf	0xF8	;y_max
	return	    ; both checks done return to drawing
	
paddle2movedown
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
	
	movf	0xF8, 0
	movwf	0xD0	
	movf	0xFD, 0
	subwf	0xD0
	
		
	
	
	
	
	
	bra jump		; if not branched (i.e. collides with paddle) return
	
collideleft	
	movf	0xF7, 0	; paddle2 ymin
	cpfsgt	0xFD	; ball ymax
	bra point1	; gives player 2 a point if ball ymax<paddle ymin
	movf	0xF8,0	; paddle2 ymax
	cpfslt	0xFC	; ball ymin
	bra point1	; gives player 2 a point if ball ymin<paddle ymax
	bra jump		; if not branched (i.e. collides with paddle) return

point1
	incf 0x91	; 0x91 and 0x92 are locations of player points
	goto start	; restarts
point2
	incf 0x92	; 0x91 and 0x92 are locations of player points
	goto start	; restarts	
	
	
	
	
;ballmove
;	decfsz	cyclecounter
;	goto	draw
;	
;
;	incf    y_max
;;	incf	y_min
;	movlw	0xFA
;	cpfslt	y_max
;	goto	jump
;
;	nop
;	bra	draw
	
	
	
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

	
	
	
	
	end
	
;collisions 
	
;sides
	
;topbottom	
;	org	0x18
	
	
;	retfie
	
	
	