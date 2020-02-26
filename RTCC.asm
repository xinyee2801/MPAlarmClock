#include p18f87k22.inc
    
    global	RTCC_Setup, RTCC_Ring, RTCC_Stop_Ring, RTCC_Snooze
    extern	UART_Receive_Byte                                                   

acs0	    udata_acs   ; Named variables in access ram
timetest    res 1	; Reserve 1 byte for BCD test    
timetest2   res 1	; Reserve 1 byte for BCD2 test 
    
RTCC	code
	
RTCC_Setup
	movlw	0x0a		; Move 0x0a into timetest
	movwf	timetest	; To ensure time stays in BCD
	movlw	0x59		; Move 0x59 into timetest2
	movwf	timetest2	; To prevent minutes from going beyond 60
	
	movlb	0x0f
	bsf	INTCON, GIE
	movlw	0x55	    		; RTCWREN enable routine 
	movwf	EECON2	   		; Refer page 230 of Family Data Sheet
	movlw	0xAA
	movwf	EECON2
	bsf	RTCCFG, RTCWREN		; Enable writing to RTCC module
	bsf	RTCCFG, RTCEN		; Enable RTCC
	bcf	PADCFG1, RTSECSEL1	
	bcf	PADCFG1, RTSECSEL0	; Set RTCC pin to output alarm pulse
	
	bsf	RTCCFG, RTCPTR0		
	bcf	RTCCFG, RTCPTR1		; Set pointer to hour	
	call	UART_Receive_Byte	
	movwf	RTCVALL			; Updates current hour from UART
	bcf	RTCCFG, RTCPTR0		
	bcf	RTCCFG, RTCPTR1		; Set pointer to minutes and seconds
	call	UART_Receive_Byte	
	movwf	RTCVALH			; Updates current minute from UART
	call	UART_Receive_Byte	
	movwf	RTCVALL			; Updates current second from UART
	bsf	RTCCFG, RTCOE		; Enables actual RTCC output	
	bsf	RTCCFG, RTCSYNC		; 
	
	; Alarm to be changed manually here
	bsf	ALRMCFG, ALRMPTR0	
	bcf	ALRMCFG, ALRMPTR1	; Set pointer to hour
	movlw	0x15			
	movwf	ALRMVALL		; Set hour to 15
	bcf	ALRMCFG, ALRMPTR0	
	bcf	ALRMCFG, ALRMPTR1	; Set pointer to minutes and seconds
	movlw	0x59			
	movwf	ALRMVALH		; Set minutes to 59
	movlw	0x00			
	movwf	ALRMVALL		; Set seconds to 00
		
	movlw	0x0C
	movwf	ALRMRPT
	bsf	ALRMCFG, AMASK1
	bsf	ALRMCFG, AMASK2
	bsf	ALRMCFG, ALRMEN
	bcf	TRISD, RD3		; Set RD3 as output	
	bsf	PORTD, RD3
	
	; PWM setup
	bsf	TRISD, RD0
	bsf	TRISD, RD1
	bSf	TRISD, RD2
	
	movlw	0xff
	movwf	PR2 
	bsf	CCP4CON, DC4B0
	bsf	CCP4CON, DC4B1
	movlw	0x07
	movwf	CCPR4L
	bcf	TRISG, RG3
	bsf	T2CON, T2CKPS1
	bcf	T2CON, TMR2ON
	bsf	CCP4CON, CCP4M3
	bsf	CCP4CON, CCP4M2
	bsf	INTCON, TMR0IE
	bsf	INTCON, GIE
	
	return

RTCC_Ring
	bsf	T2CON, TMR2ON		; Ring the buzzer
	return

RTCC_Stop_Ring
	btfss	PORTD, RD2		; Test if alarm is on
	return
	bcf	T2CON, TMR2ON		; Stop the buzzer
	bcf	ALRMCFG, ALRMEN		; Disable the alarm
	bcf	PORTD, RD3		; Signal on RD3 that alarm is off
	return
	
RTCC_Snooze
	btfss	PORTD, RD2		; Test if alarm is set
	return
	bcf	T2CON, TMR2ON		; Stop the buzzer
	bcf	ALRMCFG, ALRMEN		; Disable the alarm
	bcf	ALRMCFG, ALRMPTR0	; Set pointer to minutes and seconds
	bcf	ALRMCFG, ALRMPTR1		
	movlw	0x05			; Snooze 5 minutes from button press
	addwf	ALRMVALH, RTCVALH
	movlw	0x0f
	andwf	ALRMVALH, W
	cpfsgt	timetest
	call	BCD			; Subroutine to keep time in BCD
	movff	RTCVALL, ALRMVALL	
	bsf	ALRMCFG, ALRMEN		; Enable the alarm
	return
	
BCD	movlw	0x10
	addwf	ALRMVALH
	movlw	0x0a
	subwf	ALRMVALH
	movf	ALRMVALH, W
	cpfsgt	timetest2
	call	BCD2	
	return

BCD2	movlw	0x60
	subwf	ALRMVALH
	bsf	ALRMCFG, ALRMPTR0	
	bcf	ALRMCFG, ALRMPTR1
	movlw	0x01
	addwf	ALRMVALL
	return
	
	end
 
