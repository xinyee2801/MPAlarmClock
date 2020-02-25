#include p18f87k22.inc

    ; Importing external subroutines
    extern  UART_Setup, UART_Transmit_Message	    
    extern  LCD_Setup, LCD_delay_ms		 
    extern  RTCC_Setup, RTCC_Ring, RTCC_Stop_Ring, RTCC_Snooze	
    extern  DISPLAY_Setup, DISPLAY_Time, DISPLAY_Alarm

rst	code	0    ; Reset vector
	goto	setup
	
main	code
	
	; ******* Programme FLASH read Setup Code ***********************
setup	bcf	EECON1, CFGS	; Point to Flash program memory  
	bsf	EECON1, EEPGD 	; Access Flash program memory
	call	UART_Setup	; Setup UART
	call	LCD_Setup	; Setup LCD
	call	DISPLAY_Setup	; Setup DISPLAY
	call	RTCC_Setup	; Setup RTCC
	goto	startloop

	; ******* Main programme ****************************************
startloop
	call	DISPLAY_Time	; Display the current time using subroutine
	call	DISPLAY_Alarm	; Display the alarm (if on) using subroutine
	movlw	.200		
	call    LCD_delay_ms	; Set delay to keep screen on for 200ms
	
	; Checking triggers in PORTD
	btfsc	PORTD, RD2	; Check if RTCC Alarm Pulse is on
	call	RTCC_Ring	; If on, ring the buzzer
	btfsc	PORTD, RD0	; Check if Stop Button is pressed
	call	RTCC_Stop_Ring	; If yes, turn off buzzer and ALRMEN
	btfsc	PORTD, RD1	; Check if Snooze Button pressed
	call	RTCC_Snooze	; If yes, turn off buzzer, add 5 mins to alarm
	
	bra	startloop	; Loop code indefinitely
	
	goto	$		; goto current line in code
		
	end
