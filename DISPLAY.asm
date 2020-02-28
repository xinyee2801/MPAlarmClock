#include p18f87k22.inc
    
    global	DISPLAY_Setup, DISPLAY_Time, DISPLAY_Alarm
    extern	LCD_Write_Hex, LCD_Send_Byte_D, LCD_Write_Message
    extern	LCD_clear, LCD_line2, LCD_hide, LCD_time, LCD_alarm
	
acs0	 udata_acs	; Reserve data space in access ram
counter	 res 1		; Reserve one byte for a counter variable
 
tables	 udata	0x400   ; Reserve data anywhere in RAM (here at 0x400)
myArray  res 0x20	; Reserve 32 bytes for message data
myArray2 res 0x20	; Reserve 32 bytes for message data
myArray3 res 0x20	; Reserve 32 bytes for message data
 
pdata	code		; A section of programme memory for storing data
	
	; ******* Tables, data in programme memory, and its length ******
myTable data	    "Time : \n"		; Message, plus carriage return
	constant    myTable_l=.8	; Length of data
myTable2
	data	    "Alarm: \n"		; Message, plus carriage return
	constant    myTable_2=.8	; Length of data 
myTable3
	data	    "OFF     \n"	; Message, plus carriage return
	constant    myTable_3=.9	; Length of data 

DISPLAY	code
	
DISPLAY_Setup
	lfsr	FSR0, myArray	; Load FSR0 with address in RAM	
	movlw	upper(myTable)	; Address of data in PM
	movwf	TBLPTRU		; Load upper bits to TBLPTRU
	movlw	high(myTable)	; Address of data in PM
	movwf	TBLPTRH		; Load high byte to TBLPTRH
	movlw	low(myTable)	; Address of data in PM
	movwf	TBLPTRL		; Load low byte to TBLPTRL
	movlw	myTable_l	; Bytes to read
	movwf 	counter		; The counter register

loop 	tblrd*+			; One byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; Move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter		; Count down to zero
	bra	loop		; Keep going until finished
	
start2	lfsr	FSR0, myArray2	; Load FSR0 with address in RAM	
	movlw	upper(myTable2)	; Address of data in PM
	movwf	TBLPTRU		; Load upper bits to TBLPTRU
	movlw	high(myTable2)	; Address of data in PM
	movwf	TBLPTRH		; Load high byte to TBLPTRH
	movlw	low(myTable2)	; Address of data in PM
	movwf	TBLPTRL		; Load low byte to TBLPTRL
	movlw	myTable_2	; Bytes to read
	movwf 	counter		; The counter register

loop2 	tblrd*+			; One byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; Move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter		; Count down to zero
	bra	loop2		; Keep going until finished
	
start3	lfsr	FSR0, myArray3	; Load FSR0 with address in RAM	
	movlw	upper(myTable3)	; Address of data in PM
	movwf	TBLPTRU		; Load upper bits to TBLPTRU
	movlw	high(myTable3)	; Address of data in PM
	movwf	TBLPTRH		; Load high byte to TBLPTRH
	movlw	low(myTable3)	; Address of data in PM
	movwf	TBLPTRL		; Load low byte to TBLPTRL
	movlw	myTable_3	; Bytes to read
	movwf 	counter		; The counter register

loop3 	tblrd*+			; One byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; Move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter		; Count down to zero
	bra	loop3		; Keep going until finished
	
SetDisplay		
	movlw	myTable_l -1	    ; Output message to LCD (leave out "\n")
	lfsr	FSR2, myArray	
	call	LCD_Write_Message   ; Write 'Time:  '
	call	LCD_line2	    
	movlw	myTable_2 -1	    
	lfsr	FSR2, myArray2	
	call	LCD_Write_Message   ; Display 'Alarm: '
	return

DISPLAY_Time
	call	LCD_time
	bsf	RTCCFG, RTCPTR0
	bcf	RTCCFG, RTCPTR1	
	movf	RTCVALL, W	    ; Display hours
	call	LCD_Write_Hex	
	movlw	0x3a		    ; Display ':'
	call	LCD_Send_Byte_D
	bcf	RTCCFG, RTCPTR0
	bcf	RTCCFG, RTCPTR1	
	movf	RTCVALH, W	    ; Display minutes
	call	LCD_Write_Hex	
	movlw	0x3a		    ; Display ':'
	call	LCD_Send_Byte_D	
	movf	RTCVALL, W	    ; Display seconds
	call	LCD_Write_Hex
	return
	
DISPLAY_Alarm
	call	LCD_alarm
	btfsc	PORTD, RD3
	bra	Alarm_Set	
Alarm_Not_Set
	movlw	myTable_3 -1	    ; Output message to LCD (leave out "\n")
	lfsr	FSR2, myArray3
	call	LCD_Write_Message   ; Write 'OFF'
	call	LCD_hide	    ; Hide Cursor
	return
	
Alarm_Set
	bsf	ALRMCFG, ALRMPTR0
	bcf	ALRMCFG, ALRMPTR1
	movf	ALRMVALL, W	    ; Display hours
	call	LCD_Write_Hex	
	movlw	0x3a		    ; Display ':'
	call	LCD_Send_Byte_D	
	bcf	ALRMCFG, ALRMPTR0
	bcf	ALRMCFG, ALRMPTR1		
	movf	ALRMVALH, W	    ; Display minutes
	call	LCD_Write_Hex		
	movlw	0x3a		    ; Display ':'
	call	LCD_Send_Byte_D
	movf	ALRMVALL, W	    ; Display minutes
	call	LCD_Write_Hex	
	call	LCD_hide	    ; Hide cursor
	return
	
	end
