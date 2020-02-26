#include p18f87k22.inc

    global  UART_Setup, UART_Transmit_Message, UART_Receive_Byte

acs0    udata_acs	    ; Named variables in access ram
UART_counter res 1	    ; Reserve 1 byte for variable UART_counter

UART    code
    
UART_Setup
	bsf	RCSTA1, SPEN    ; Enable
	bcf	TXSTA1, SYNC    ; Synchronous
	bcf	TXSTA1, CSRC	; Master mode
	bsf	RCSTA1, CREN	; Enable continuous receive until CREN cleared
	bcf	TXSTA1, BRGH    ; Slow speed
	bsf	TXSTA1, TXEN    ; Enable transmit
	bcf	BAUDCON1, BRG16 ; 8-bit generator only
	movlw   .103		
	movwf   SPBRG1		; Gives 9600 Baud rate (actually 9615)
	bsf	TRISC, TX1	; TX1 pin as output
	bcf	TRISC, RX1	; RX1 pin as input
	return

UART_Transmit_Message		    ; Message stored at FSR2, length stored in W
	movwf   UART_counter
UART_Loop_message
	movf    POSTINC2, W
	call    UART_Transmit_Byte  
	decfsz  UART_counter	    ; Transmits all characters in FSR2
	bra	UART_Loop_message
	return

UART_Transmit_Byte		    ; Transmits byte stored in W
	btfss   PIR1,TX1IF	    ; TX1IF is set when TXREG1 is empty
	bra	UART_Transmit_Byte
	movwf   TXREG1
	return

UART_Receive_Byte		    ; Receives byte sent via PC
	btfss   PIR1, RC1IF	    ; Tests if signal is received
	bra	UART_Receive_Byte   ; Loop until signal obatined
	movf    RCREG1, W	   
	return
    
	end





