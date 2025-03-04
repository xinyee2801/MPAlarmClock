#include p18f87k22.inc

    global  LCD_Setup, LCD_Write_Message, LCD_delay_ms, LCD_Send_Byte_D
    global  LCD_Write_Hex, LCD_clear, LCD_line2, LCD_hide, LCD_time, LCD_alarm

acs0    udata_acs   ; Named variables in access ram
LCD_cnt_l   res 1   ; Reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h   res 1   ; Reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms  res 1   ; Reserve 1 byte for ms counter
LCD_tmp	    res 1   ; Reserve 1 byte for temporary use
LCD_counter res 1   ; Reserve 1 byte for counting through nessage

acs_ovr	access_ovr
LCD_hex_tmp res 1   ; Reserve 1 byte for variable LCD_hex_tmp	

	constant    LCD_E=5	; LCD enable bit
    	constant    LCD_RS=4	; LCD register select bit

LCD	code
    
LCD_Setup
	clrf    LATB
	movlw   b'11000000'	; RB0:5 all outputs
	movwf	TRISB
	movlw   .40
	call	LCD_delay_ms	; Wait 40ms for LCD to start up properly
	movlw	b'00110000'	; Function set 4-bit
	call	LCD_Send_Byte_I
	movlw	.10		; Wait 40us
	call	LCD_delay_x4us
	movlw	b'00101000'	; 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	.10		; Wait 40us
	call	LCD_delay_x4us
	movlw	b'00101000'	; Repeat, 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	.10		; Wait 40us
	call	LCD_delay_x4us
	movlw	b'00001111'	; Display on, cursor on, blinking on
	call	LCD_Send_Byte_I
	movlw	.10		; Wait 40us
	call	LCD_delay_x4us
	movlw	b'00000001'	; Display clear
	call	LCD_Send_Byte_I
	movlw	.2		; Wait 2ms
	call	LCD_delay_ms
	movlw	b'00000110'	; Entry mode incr by 1 no shift
	call	LCD_Send_Byte_I
	movlw	.10		; Wait 40us
	call	LCD_delay_x4us
	return

LCD_Write_Hex			; Writes byte stored in W as hex
	movwf	LCD_hex_tmp
	swapf	LCD_hex_tmp,W	; High nibble first
	call	LCD_Hex_Nib
	movf	LCD_hex_tmp,W	; Then low nibble
LCD_Hex_Nib			; Writes low nibble as hex character
	andlw	0x0f
	movwf	LCD_tmp
	movlw	0x0a
	cpfslt	LCD_tmp
	addlw	0x07		; Number is greater than 9 
	addlw	0x26
	addwf	LCD_tmp,W
	call	LCD_Send_Byte_D ; Write out ascii
	return
	
LCD_Write_Message		; Message stored at FSR2, length stored in W
	movwf   LCD_counter
LCD_Loop_message
	movf    POSTINC2, W
	call    LCD_Send_Byte_D
	decfsz  LCD_counter
	bra	LCD_Loop_message
	return

LCD_Send_Byte_I			; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp
	swapf   LCD_tmp,W	; Swap nibbles, high nibble goes first
	andlw   0x0f		; Select just low nibble
	movwf   LATB		; Output data bits to LCD
	bcf	LATB, LCD_RS	; Instruction write clear RS bit
	call    LCD_Enable	; Pulse enable Bit 
	movf	LCD_tmp,W	; Swap nibbles, now do low nibble
	andlw   0x0f		; Select just low nibble
	movwf   LATB		; Output data bits to LCD
	bcf	LATB, LCD_RS    ; Instruction write clear RS bit
        call    LCD_Enable	; Pulse enable Bit 
	return

LCD_Send_Byte_D			; Transmits byte stored in W to data reg
	movwf   LCD_tmp
	swapf   LCD_tmp,W	; Swap nibbles, high nibble goes first
	andlw   0x0f		; Select just low nibble
	movwf   LATB		; Output data bits to LCD
	bsf	LATB, LCD_RS	; Data write set RS bit
	call    LCD_Enable	; Pulse enable Bit 
	movf	LCD_tmp,W	; Swap nibbles, now do low nibble
	andlw   0x0f		; Select just low nibble
	movwf   LATB		; Output data bits to LCD
	bsf	LATB, LCD_RS    ; Data write set RS bit	    
        call    LCD_Enable	; Pulse enable Bit 
	movlw	.19		; Delay 40us
	call	LCD_delay_x4us
	return

LCD_Enable			; Pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATB, LCD_E	; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, LCD_E	; Writes data to LCD
	return
    
; ** A few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms			; Delay given in ms in W
	movwf	LCD_cnt_ms
lcdlp2	movlw	.250		; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms
	bra	lcdlp2
	return
    
LCD_delay_x4us			; Delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l	; Now need to multiply by 16
	swapf   LCD_cnt_l,F	; Swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l,W	; Move low nibble to W
	movwf	LCD_cnt_h	; Then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l,F	; Keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay			; Delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1	decf 	LCD_cnt_l,F	; No carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h,F	; No carry when 0x00 -> 0xff
	bc 	lcdlp1		; Carry, then loop again
	return			; Carry reset so return

LCD_line2			; Set DDRAM to start of line 2
	movlw	b'11000000'
	call	LCD_Send_Byte_I
	movlw	.10
	call	LCD_delay_x4us
	return
	
LCD_hide			; Set DDRAM out of screen
	movlw	b'10010000'
	call	LCD_Send_Byte_I
	movlw	.10
	call	LCD_delay_x4us
	return
	
LCD_time			; Set DDRAM to write time
	movlw	b'10000111'
	call	LCD_Send_Byte_I
	movlw	.10
	call	LCD_delay_x4us
	return	
	
LCD_alarm			; Set DDRAM to write alarm
	movlw	b'11000111'
	call	LCD_Send_Byte_I
	movlw	.10
	call	LCD_delay_x4us
	return	
	
LCD_clear			; Clear screen
	movlw	b'00000001'	; Display clear
	call	LCD_Send_Byte_I
	movlw	.2		; Wait 2ms
	call	LCD_delay_ms
	return
	
	end





