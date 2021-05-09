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

;Buttons for the frequency select on p0.4, p0.5, p0.6
;fast = p0.4, medium = p0.5, slow = p0.6

;setting switch pins to input pins
MOV P0MDOUT, #00H



;MOV P0MDOUT,#00H  ;Buttons DEC, INC , submit on p0.0 p0.1 p0.2 


TABLE_SEG EQU 100H			; start address of look-up Table
		RED_LED BIT P1.6
		GREEN_LED BIT P1.5
		LEFT_7_SEGMENT EQU P3
		RIGHT_7_SEGMENT EQU P2
		S1 BIT P0.0
		S2 BIT P0.1
		SUBMIT BIT P0.2
		
		ORG 0					;tells the compiler all subsequent code starting at address 0
		CALL OFF
		;initially 30 on  7segments
		MOV R1, #00H                   
		MOV R2, #03H                   
		MOV DPTR, #TABLE_SEG 

;load chosen max time on 7segs
INIT: 
	MOV A, R1
	MOVC A, @A+DPTR
	MOV RIGHT_7_SEGMENT, A
	MOV A, R2 
	MOVC A, @A+DPTR
	MOV LEFT_7_SEGMENT, A


CHECK:	JB SUBMIT,START ;start if submit
				JB S1,INC1;increment 1 if s1
				JB S2,INC2;increment2 if s2
				SJMP INIT ;if not any return to write to 7seg and read switches

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
			MOV A, R1
			MOVC A, @A+DPTR
			MOV P2, A
			MOV A, R2 
			MOVC A, @A+DPTR
			MOV P3, A

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
			JNB SUBMIT, CHECK
			JMP START

ON:	SETB GREEN_LED
		CLR RED_LED
		RET
		
OFF:	CLR GREEN_LED
			SETB RED_LED
			RET

TOG:	CPL GREEN_LED
			CPL RED_LED
			RET
			
;look up table for right seven segment common cathode
    ORG TABLE_SEG
    DB 3FH,06H,5BH,4FH,66H,6DH,7DH,07H,7FH,6FH



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
    JB P0.4, fastfreq 

    JB P0.5, medfreq

    JB P0.6, slowfreq

    ACALL medfreq ;if no switch is closed, choose the medium frequency

    CONT:
        RET	
				
END
				