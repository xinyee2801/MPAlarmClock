#include p18f87k22.inc
    
    global	RTCC_Setup, RTCC_Ring, RTCC_Stop_Ring, RTCC_Snooze
    extern	UART_Receive_Byte                                                   

acs0	    udata_acs   ; Named variables in access ram
timetest    res 1	; Reserve 1 byte for BCD test    
timetest2   res 1	; Reserve 1 byte for BCD2 test 
    
RTCC	code
	
RTCC_Setup
	movlw	0x09		; Move 0x0a into timetest
	movwf	timetest	; To ensure time stays in BCD
	movlw	0x59		; Move 0x59 into timetest2
	movwf	timetest2	; To prevent minutes from going beyond 60
	
	movlb	0x0f
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
	
	; Alarm to be changed manually here
	bsf	ALRMCFG, ALRMPTR0	
	bcf	ALRMCFG, ALRMPTR1	; Set pointer to hour
	movlw	0x18			
	movwf	ALRMVALL		; Set hour to 15
	bcf	ALRMCFG, ALRMPTR0	
	bcf	ALRMCFG, ALRMPTR1	; Set pointer to minutes and seconds
	movlw	0x04			
	movwf	ALRMVALH		; Set minutes to 59
	movlw	0x00			
	movwf	ALRMVALL		; Set seconds to 00
		
	bsf	ALRMCFG, AMASK1
	bsf	ALRMCFG, AMASK2		; Ring the alarm only once a day
	bsf	ALRMCFG, CHIME		; Turn CHIME on, ALRMEN won't turn off
	bsf	ALRMCFG, ALRMEN		; Enable alarm
	bcf	TRISD, RD3		; Set RD3 as output	
	bsf	PORTD, RD3		; Turn RD3 on, as alarm is on
	
	; PWM setup
	bsf	TRISD, RD0
	bsf	TRISD, RD1
	bsf	TRISD, RD2		; Set pins as output
	movlw	0xff
	movwf	PR2			; Set PWM period
	bsf	CCP4CON, DC4B0
	bsf	CCP4CON, DC4B1		; Set PWM duty cycle
	movlw	0x07
	movwf	CCPR4L			; Set PWM duty cycle (10 bits)
	bcf	TRISG, RG3		; CCP4 pin output
	bsf	T2CON, T2CKPS1		; Set TMR2 prescale value
	bcf	T2CON, TMR2ON		; Disable the buzzer
	bsf	CCP4CON, CCP4M3		
	bsf	CCP4CON, CCP4M2		; Configure module for PWM operation
	
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
	addwf	ALRMVALH
	movlw	0x0f		
	andwf	ALRMVALH, W		; Obtain ones value of ALRMVALH
	cpfsgt	timetest		; Check if ones is greater than 
	call	BCD			; Subroutine to keep time in BCD
	movff	RTCVALL, ALRMVALL	; Update seconds for snooze
	bsf	ALRMCFG, ALRMEN		; Enable the alarm
	return
	
BCD	movlw	0x10
	addwf	ALRMVALH
	movlw	0x0a
	subwf	ALRMVALH
	movf	ALRMVALH, W
	cpfsgt	timetest2		; Check if minutes greater than 59
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
 
