
TITLE Low-Level I/O Procedures

; Author: Taylor Reed
; Last Modified: 12/4/22
; Description: A program that implements two macros for string processing
;		and two procedures that utilize them to retrieve and print integers. 
;		Macro mGetString receives user input in ASCII representation, which proc 
;		ReadVal converts to a signed integer value. Proc WriteVal converts
;		signed integers to thier ASCII representation before calling macro 
;		mDisplayString to print them. The functionality of the macros and procedures
;		is tested in the main program, which prompts the user to enter 10 integers
;		that will fit in a 32-bit register before printing a list of the integers, 
;		the total sum, and the truncated average. Data validation is done by ReadVal.



INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Calls mDisplayString to display prompt and reads user input with ReadString. 
;
; Preconditions: do not use EAX, ECX as arguments
;
; Receives:
; dispPrompt = address of prompt to disply
; buffer	 = max string length
; count		 = string length
; userNum	 = address to store user string
;
; Returns: 
; count		 = length of string entered by user
; userNum	 = string entered by user
; ---------------------------------------------------------------------------------
mGetString MACRO dispPrompt, buffer, count, userNum
	PUSHAD
	
	mDisplayString dispPrompt
	MOV		EDX, userNum
	MOV		ECX, buffer
	CALL	ReadString
	MOV		count, EAX			; stores length of entered string

	POPAD
ENDM


; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays string using WriteString. 
;
; Preconditions: none
;
; Receives:
; string = address of string to display
;
; returns: none
; ---------------------------------------------------------------------------------
mDisplayString MACRO string 
	PUSH	EDX
	MOV		EDX, string
	CALL	WriteString
	POP		EDX
ENDM

; Global Constants
LISTSIZE = 10
LO = -2147483648

.data

	progTitle			BYTE	"Low-Level I/O Procedures by Taylor Reed",13,10,0
	progInstructions	BYTE	"Please provide 10 signed decimal integers. ",
								"Each number must fit in a 32-bit register.",13,10,
								"When you are done, the following will be displayed: ",
								"a list of the integers, their sum, and their average value.",13,10,0
	prompt1				BYTE	"Please enter a signed number: ",0
	errorMsg			BYTE	"Your entry includes invalid characters or does not fit in the register.",13,10,0
	listTitle			BYTE	"You entered the following numbers: ",0
	sumTitle			BYTE	"The sum of these numbers is: ",0
	averageTitle		BYTE	"The average is: ",0
	space				BYTE	", ",0
	goodbye				BYTE	"Bye!",0
	userNum				SDWORD	0					;integer representation of number 
	userList			SDWORD	LISTSIZE DUP(?)		;holds LISTSIZE user integers
	userSum				SDWORD	0		
	userAve				SDWORD	0


.code
main PROC
	; Display program title and instructions
	mDisplayString	OFFSET progTitle
	CALL	CRLF
	mDisplayString	OFFSET progInstructions
	CALL	CRLF

	MOV		EDI, OFFSET userList
	MOV		ECX, LISTSIZE
	_getInput: 
		; call ReadVal to prompt user entry
		PUSH	OFFSET prompt1
		PUSH	OFFSET errorMsg
		PUSH	OFFSET userNum
		CALL	ReadVal

		; add user input to the array and total sum
		MOV		EAX, userNum
		MOV		[EDI], EAX
		ADD		EDI, TYPE userList
		ADD		userSum, EAX	
		LOOP	_getInput
	CALL	CRLF

	; Print List
	mDisplayString OFFSET listTitle
	MOV		ESI, OFFSET userList
	MOV		ECX, LISTSIZE
	_printList:
		MOV		EAX, [ESI]
		PUSH	EAX
		CALL	WriteVal
		ADD		ESI, TYPE userList
		CMP		ECX, 1
		JE		_callPrintListLoop
		mDisplayString OFFSET space
	  _callPrintListLoop:
		LOOP	_printList
	CALL	CRLF

	; Print sum
	mDisplayString OFFSET sumTitle
	PUSH	userSum
	CALL	WriteVal
	CALL	CRLF

	; Calculate & print average
	MOV		EAX, userSum
	MOV		EBX, LISTSIZE
	CDQ
	IDIV	EBX
	MOV		userAve, EAX
	mDisplayString OFFSET averageTitle
	PUSH	userAve
	CALL	WriteVal
	CALL	CRLF
	CALL	CRLF

	; Say bye
	mDisplayString OFFSET goodbye
	CALL	CRLF

	Invoke ExitProcess,0		; exit to operating system
main ENDP


; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Calls mGetString to get user input. Takes string representation of user input
; and converst it to a signed integer. If the input won't fit in a 32-bit register
; or is otherwise invalid (includes letters or inappropriate symbols), an error 
; message is displayed and the user is prompted to enter another number. 
;
; Preconditions: userNum is type SDWORD
;
; Postconditions: none.
;
; Receives:
; [ebp+16]	= address of entry prompt
; [ebp+12]	= address of error message
; [ebp+8]	= address of userNum
;
; returns: userNum is signed integer representation of user's number
; ---------------------------------------------------------------------------------
ReadVal PROC
	LOCAL	UserInput[33]:BYTE	; String representation of user input
	LOCAL	inputCount:DWORD	; Stores length of user input, which is output by mGetString
	LOCAL	UserInt:SDWORD		; Signed integer representation of user input
	LOCAL	Multiplier:SDWORD	; 1 for positive numbers, -1 for negative numbers
	PUSHAD	
	
  _getUserInput:
	; Calls mGetString to get user input
	MOV		EDX, [EBP+16]	
	LEA		EBX, UserInput
	mGetString EDX, 33, inputCount, EBX
	MOV		ESI, EBX
	MOV		UserInt, 0
		
	; Prep to go through string
	CLD
	MOV		ECX, inputCount

	; check for + or - in first character 
	LODSB
	CMP		AL, 45
	JE		_negative
	MOV		Multiplier, 1		; if first char is not -, update Multiplier to 1 
	CMP		AL, 43
	JE		_signed
	DEC		ESI					; if first char is not +/-, dec ESI so first bit is checked in validationLoop
	JMP		_validationLoop
  _negative:
	MOV		Multiplier, -1		; if first char is -, update Multiplier to -1
  _signed:
	DEC		ECX					; dec ECX for signed numbers since we have already reviewed the first value
	_validationLoop:
		; validate current bit contains a number
		MOV		EAX, 0
		LODSB
		CMP		AL, 48
		JL		_notValid
		CMP		AL, 57
		JG		_notValid
		
		; convert user entry to unsigned integer 
		PUSH	EAX				; preserve EAX so AL is not overwritten during multiplication
		MOV		EAX, UserInt
		MOV		EBX, 10
		MUL		EBX
		MOV		UserInt, EAX
		POP		EAX
		JO		_notValid		; if overflow flag is set, entry will not fit in 32-bit register
		SUB		EAX, 48			; convert bit from ASCII to integer value
		ADD		UserInt, EAX
		; more checks for entries that will not fit in 32-bit register
		JNS		_callValidationLoop
		CMP		Multiplier, -1
		JNE		_notValid
		CMP		UserInt, LO
		JG		_notValid
	  _callValidationLoop:
		LOOP	_validationLoop
	JMP		_Finish
		
  _notValid:
	; display error message if entry is invalid
	mDisplayString [EBP+12]		
	JMP		_getUserInput
		
  _Finish:
	; convert unsigned integer to signed integer
	MOV		EAX, UserInt
	IMUL	EAX, Multiplier
	
	; store signed integer in userNum
	MOV		EDI, [EBP+8]		
	MOV		[EDI], EAX

	POPAD
	RET	12

ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts SDWORD to string ASCII representation, then calls mDisplayString
;
; Preconditions: integer must be type SDWORD
;
; Postconditions: none.
;
; Receives:
; [ebp+8] = signed integer value
;
; returns: none
; ---------------------------------------------------------------------------------
WriteVal PROC
	LOCAL IntText[12]:BYTE		; holds ASCII representation of signed integer as it is converted
	LOCAL RevText[12]:BYTE		; revers of IntText, which is the correct order to send to mDisplayString
	LOCAL Counter:DWORD			; length of given integer
	PUSHAD

	MOV		Counter, 0
	LEA		EDI, IntText
	MOV		EAX, [EBP+8]
	CMP		EAX, 0
	JGE		_convertInt
	MOV		EBX, -1				; if user number is negative, make it positive for initial conversion
	IMUL	EAX, EBX


	_convertInt: 
		; Convert integer to ASCII representation (reverse order)
		CLD
		INC		Counter
		MOV		EBX, 10			
		MOV		EDX, 0
		DIV		EBX					; Divide user integer by 10 to isolate smallest value
		ADD		EDX, 48				; Convert smallest value to ASCII
		PUSH	EAX					; Preserve EAX, which contains quoitient 
		MOV		EAX, EDX
		STOSB 
		POP		EAX
		CMP		EAX, 0
		JNE		_convertInt			; continue looping until the full number has been converted
	
	; if original number was negative, add ASCII representation of - to the end of IntText
	MOV		EAX, [EBP+8]
	CMP		EAX, 0
	JGE		_reverseString
	MOV		AL, 45				
	STOSB
	INC		Counter

  _reverseString:
	; Reverse IntText and store in RevText
	MOV		ECX, Counter
	LEA		ESI, IntText
	ADD		ESI, ECX
	DEC		ESI
	LEA		EDI, RevText

	_revLoop:
		STD
		LODSB
		CLD
		STOSB
		LOOP	_revLoop

	;Add null terminator to RevText
	MOV		AL, 0			
	STOSB

	LEA		EDX, RevText	
	mDisplayString EDX

	POPAD
	RET 4
WriteVal ENDP


END main
