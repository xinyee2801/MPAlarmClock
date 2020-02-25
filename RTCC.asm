#include p18f87k22.inc
    
    global	RTCC_Setup, RTCC_Ring, RTCC_Stop_Ring, RTCC_Snooze
    extern	UART_Receive_Byte                                                   

acs0	    udata_acs   ; named variables in access ram
timetest    res 1	; reserve 1 byte for BCD test    
timetest2   res 1	; reserve 1 byte for BCD2 test 
    
RTCC	code
	
RTCC_Setup
	movlw	0x0a
	movwf	timetest	
	movlw	0x59
	movwf	timetest2
	
	movlb	0x0f
	bsf	INTCON, GIE
	movlw	0x55	    ; RTCWREN enable routine 
	movwf	EECON2	    ; Refer page 230 of Family Data Sheet
	movlw	0xAA
	movwf	EECON2
	bsf	RTCCFG, RTCWREN
	bsf	RTCCFG, RTCEN
	bcf	PADCFG1, RTSECSEL1
	bcf	PADCFG1, RTSECSEL0
	
	bsf	RTCCFG, RTCPTR0		; Set pointer to hour
	bcf	RTCCFG, RTCPTR1			
	call	UART_Receive_Byte
	movwf	RTCVALL
	bcf	RTCCFG, RTCPTR0		; Set pointer to minutes and seconds
	bcf	RTCCFG, RTCPTR1			
	call	UART_Receive_Byte
	movwf	RTCVALH	
	call	UART_Receive_Byte
	movwf	RTCVALL
	bsf	RTCCFG, RTCOE	
	bsf	RTCCFG, RTCSYNC		
	
	bsf	ALRMCFG, ALRMPTR0	; Set pointer to hour
	bcf	ALRMCFG, ALRMPTR1		
	movlw	0x15			; Set hour to 15
	movwf	ALRMVALL
	bcf	ALRMCFG, ALRMPTR0	; Set pointer to minutes and seconds
	bcf	ALRMCFG, ALRMPTR1		
	movlw	0x59			; Set minutes to 36
	movwf	ALRMVALH
	movlw	0x00			; Set seconds to 00
	movwf	ALRMVALL
	
	bcf	TRISD, RD3
	
	movlw	0x0C
	movwf	ALRMRPT
	bsf	ALRMCFG, AMASK1
	bsf	ALRMCFG, AMASK2
	bsf	ALRMCFG, ALRMEN
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
	bsf	T2CON, TMR2ON
	return

RTCC_Stop_Ring
	btfss	PORTD, RD2
	return
	bcf	T2CON, TMR2ON
	bcf	ALRMCFG, ALRMEN
	bcf	PORTD, RD3
	return
	
RTCC_Snooze
	btfss	PORTD, RD2
	return
	bcf	T2CON, TMR2ON
	bcf	ALRMCFG, ALRMEN
	bcf	ALRMCFG, ALRMPTR0	; Set pointer to minutes and seconds
	bcf	ALRMCFG, ALRMPTR1		
	movlw	0x05			
	addwf	ALRMVALH, RTCVALH
	movlw	0x0f
	andwf	ALRMVALH, W
	cpfsgt	timetest
	call	BCD	
	movf	RTCVALL, ALRMVALL
	bsf	ALRMCFG, ALRMEN
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
 