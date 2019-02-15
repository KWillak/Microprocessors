	#include p18f87k22.inc

rst	code	0x0000	; reset vector
	goto	start
	
int_hi	code	0x0008	; high vector, no low vector
	btfss	INTCON,TMR0IF	; check that this is timer0 interrupt
	retfie	FAST		; if not then return
	movlw	0x00
	movwf	LATB, ACCESS
	incf	LATE		; increment PORTD
	incf	LATD
	movlw	0x11
	movwf	LATB, ACCESS
	bcf	INTCON,TMR0IF	; clear interrupt flag
	retfie	FAST		; fast return from interrupt

main	code
start	clrf	TRISE		; Set PORTD as all outputs
	clrf	LATE		; Clear PORTD outputs
	clrf	TRISD
	clrf	LATD
	clrf	TRISB		; Set PORTB as all outputs
	clrf	LATB		
	movlw	b'10000111'	; Set timer0 to 16-bit, Fosc/4/256
	movwf	T0CON		; = 62.5KHz clock rate, approx 1sec rollover
	bsf	INTCON,TMR0IE	; Enable timer0 interrupt
	bsf	INTCON,GIE	; Enable all interrupts
	
	goto	$		; Sit in infinite loop
	end
