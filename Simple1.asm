	#include p18f87k22.inc

	
	code
	org 0x0
	goto	start
	
	org 0x100		    ; Main code starts here at address 0x100


delay_count res 1   ; reserve one byte for counter in the delay routine
 
start	clrf	TRISE		; Set PORTD as all outputs
	clrf	LATE		; Clear PORTD outputs
	clrf	TRISD
	clrf	LATD
	clrf	TRISB		; Set PORTB as all outputs
	clrf	LATB	



squarewave

yfall
	movlw	0x00
	movwf	LATB, ACCESS
	decf	PORTD
	movlw	0x01
	movwf	LATB, ACCESS
	
	movlw 	0xFE
	cpfsgt 	PORTD, ACCESS
	bra yfall
	
xfall
	movlw	0x00
	movwf	LATB, ACCESS
	decf	PORTE
	movlw	0x10
	movwf	LATB, ACCESS
	
	movlw 	0xFE
	cpfsgt 	PORTE, ACCESS
	bra xfall
	
yrise
	movlw	0x00
	movwf	LATB, ACCESS
	incf	PORTD
	movlw	0x01
	movwf	LATB, ACCESS
	
	movlw 	0xFE
	cpfsgt 	PORTD, ACCESS
	bra yrise	

xrise
	movlw	0x00
	movwf	LATB, ACCESS
	incf	PORTE
	movlw	0x10
	movwf	LATB, ACCESS
	
	movlw 	0xFE
	cpfsgt 	PORTE, ACCESS
	bra xrise
	
;	incf	LATE		; increment PORTD
;	incf	LATD
;	movlw	0x11
;	movwf	LATB, ACCESS
;	movlw	0x00
;	movwf	LATB, ACCESS
	
	
	call squarewave

	; a delay subroutine if you need one, times around loop in delay_count
delay	decfsz	delay_count	; decrement until zero
	bra delay
	return	


	end

	
	
	
	
	
	
	
	
	
	end