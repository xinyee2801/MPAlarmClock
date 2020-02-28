# Microprocessors
Repository for Physics Year 3 microprocessors lab.

An alarm clock using the PIC18 microprocessor. Uses the Real-Time Clock and Calendar (RTCC) module and an internal oscillator block that provides a 16 MHz clock (±2% accuracy). Time in the RTCC registers are kept as binary coded decimals.

Current time is updated using the UARTconnect.py and the COM4 port, while alarm time is set in the RTCC.asm file. Two push buttons are connected to PORTD to turn the alarm off or snooze the alarm for 5 minutes.

The time and alarm time are displayed using the 16x2 LCD screen connected to PORTB.
