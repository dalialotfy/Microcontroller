$NOMOD51	 ;to suppress the pre-defined addresses by keil
$include (C8051F020.H)		; to declare the device peripherals	with it's addresses
ORG 00H					   ; to start writing the code from the base 0


;disable the watch dog
MOV WDTCN,#11011110B ;0DEH
MOV WDTCN,#10101101B ;0ADH

; config of clock
MOV OSCICN , #14H ; 2MH clock

; config cross bar
MOV XBR0 , #00H
MOV XBR1 , #00H
MOV XBR2 , #040H  ; Cross bar enabled , weak Pull-up enabled 

;config,setup
MOV P1MDOUT, #0FFh
MOV P2MDOUT, #0FFh
MOV P0MDOUT, #00001100B ;leds on p0.2 p0.3
MOV P74OUT,#00001000B ;5.4:5.7 out


;TABLE_SEG EQU 100H			; start address of look-up Table
;RED_LED BIT P0.2
;GREEN_LED BIT P0.3
;LEFT_7_SEGMENT EQU P2
;RIGHT_7_SEGMENT EQU P1
;S1 BIT P0.4
;S2 BIT P0.5
;SUBMIT BIT P0.6
		

;initially 30 on  7segments
BEGINING: ACALL OFF
					MOV R1, #00H                   
					MOV R2, #03H                   
					MOV DPTR, #400h 

;load chosen max time on 7segs
INIT:
	CLR A 
	MOV A, R1
	MOVC A, @A+DPTR
	MOV P1, A
	MOV A, R2 
	MOVC A, @A+DPTR
	MOV P2,A


CHECK:	
				CLR A
				MOV A,P5		
        RRC A			; Rotate A to the right to check P5.0 (submit)
        JNC START 	;If carry high jump to start
        RRC A		  ; Rotate A to check P5.1 (inc1)
        JNC INC1	  
        RRC A			; Rotate A to check P5.2(inc2) 
        JNC INC2    		
        SJMP INIT		// Read switch status again.JB P0.6,START ;start if submit
				

INC1:	CJNE R1, #09H, IN1 ; check if 9 reached return to zero
			MOV R1,#00H
			ACALL DELAY
			SJMP INIT 
	
			IN1:INC R1
					ACALL DELAY
					SJMP INIT


INC2:	CJNE R2,#09H,IN2 ; check if 9 reached return to 1 (minimum is 10)
			MOV R2,#01H
			ACALL DELAY
			SJMP INIT
	
			IN2:INC R2
					ACALL DELAY
					SJMP INIT

START:
	MOV 60H,R1
	MOV 70H,R2
	JMP MAIN



MAIN:	ACALL DELAY
			CLR A
			MOV A, R1
			MOVC A, @A+DPTR
			MOV P1, A
			MOV A, R2 
			MOVC A, @A+DPTR
			MOV P2, A

DEC1:	CJNE R1,#00H,DC1
			MOV R1,#09H
			SJMP DEC2
			DC1:DEC R1
			JMP MAIN

DEC2:	CJNE R2,#00H,DC2
			SJMP REST
			DC2:DEC R2
			JMP MAIN
	
REST:	CALL TOG
      MOV R1,60H
			MOV R2,70H
			JNB P0.6, CHECK
			JMP START

ON:	SETB P0.3
		CLR P0.2
		RET
		
OFF:	CLR P0.3
			SETB P0.2
			RET

TOG:	CPL P0.3
			CPL P0.2
			RET
			

;setting the register values for high frequency delay
fastfreq:
        MOV R4,#03H
        MOV R5 ,#0FFH
        MOV R6, #0FFH
		ACALL LOOP
		AJMP CONT
		

;setting the register values for medium frequency delay
medfreq:
        MOV R4,#07H
        MOV R5 ,#0FFH
        MOV R6, #0FFH
		ACALL LOOP
		AJMP CONT

;setting the register values for slow frequency delay
slowfreq:
        MOV R4,#011H
        MOV R5 ,#0FFH
        MOV R6, #0FFH
		ACALL LOOP
		AJMP CONT

;the delay loop			        
LOOP:	DJNZ R6, LOOP
        DJNZ R5, LOOP
        DJNZ R4, LOOP
		RET

DELAY:
    CLR A
    MOV A, P4
    RRC A
    JNC fastfreq
    RRC A
    JNC medfreq
    RRC A
    JNC slowfreq

    ACALL medfreq ;if no switch is closed, choose the medium frequency

    CONT:
        RET	
				
		
ORG 400H
DB 3FH,06H,5BH,4FH,66H,6DH,7DH,07H,7FH,6FH			

END