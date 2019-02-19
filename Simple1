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

			    ;now paddle1 intialisations		    
	movlw   0xF0
	movwf	0xF0	;0x02
	movlw	0xFE
	movwf	0xF1	;0x00
	movlw	0x60
	movwf	0xF2	;0x01
	movlw   0x90	
	movwf   0xF3	;0x03
	
			     ;now paddle2 intialisations
	movlw   0x05
	movwf	0xF5	;0x02
	movlw	0x15
	movwf	0xF6	;0x00
	movlw	0x60	
	movwf	0xF7	;0x01
	movlw   0x90	
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
	movlw	0x02
	movwf	ballvx
	movlw	0x03
	movwf	ballvy	
			    ; now ball direction initialisations
	movlw	0x06
	movwf	0xE0
	movlw	0x06
	movwf	0xE1
	
	
	
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
	movf 	x_max, 0
	cpfsgt 	0x0D
	bra xrise
	
;	incf	LATE		; increment PORTD
;	incf	LATD
;	movlw	0x11
;	movwf	LATB, ACCESS
;	movlw	0x00
;	movwf	LATB, ACCESS
	
	
	return

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
	
	
	
	
	
