; Second stage of the boot loader

BITS 16

ORG 9000h
	jmp 	Second_Stage

%include "functions_16.asm"
%include "bpb.asm"					; The BIOS Parameter Block (i.e. information about the disk format)
%include "floppy16.asm"					; Routines to access the floppy disk drive

; Start of the second stage of the boot loader
	
Second_Stage:
    	mov		[boot_device], dl		; Boot device number is passed in from first stage in DL. Save it to pass to kernel later.
    	mov 		si, second_stage_msg		; Output our greeting message
    	call 		Console_WriteLine_16

Program:
	mov		si, input_message		;Request input from user
	call		Console_Write_16

Input:
	xor		bx, bx
	xor 		cx, cx
	xor 		ax, ax
	mov		dx, 10				;Prepare DL to use as operand for the mul instruction to create our int

Keyboard_Read:						
	xor		ah, ah
	int		16h
	
Input_Check:
	cmp		al, 0Dh				;Enter
	je		Assign_Registers
	cmp		al, 30h				;Check if it's a digit
	jl		Keyboard_Read
	cmp		al, 39h
	jg		Keyboard_Read
	mov		ah, 0Eh
	int 		10h
	xor		ah, ah
	sub		al, 30h				;This leaves al with the digit we want
	cmp		cx, 0				;We need to multiply our digit by 10, but only if it's not the first one
	jg		Multiple_Digits
	inc		cx				
	push		ax				;Because both mul and int 16h modify AL, we push it to the stack
	xor		ax, ax
	jmp		Keyboard_Read

Multiple_Digits:
	mov		bx, ax				;Store digit from keyboard
	pop		ax				;Retrieve our number from the stack
	inc		cx				;Increase number of digits
	push		dx
	mul 		dx				;Multiply by 10 then add the next digit
	pop		dx
	add 		ax, bx
	cmp		ax, 0B40h			;There are only 2880 sectors in this disk (according to bpb.asm)
	jge		Sector_Error
	push		ax				;Store result
	xor		ax, ax				;Empty AX for the next input
	jmp 		Keyboard_Read

Assign_Registers:
	cmp		cx, 0				;In case enter was pressed with no digit inserted
	je		Keyboard_Read
	call 		Console_Write_CRLF
	pop		ax				;Restore AX to starting sector number
	mov		cx, 1
	mov		bx, 0D000h
	call		ReadSectors
	call		Console_Write_CRLF
	xor		dx, dx
	mov		dl, byte [0D000h]		;Take starting byte from starting address
	mov		si, 0D000h			;Set pointer to start

	mov		cx, 2				;It takes us two passes to display a sector
Output:									
	push		cx				;To accomodate for multiple loops, we use the stack as many times as deemed necessary.
	mov		cx, 16				;Display 16 lines

Display_Line:
	push		cx

Display_Offset:						
	mov		dx, si						
	sub		dx, 0D000h			;Calculate offset
	push		si				;Save this address to use with ASCII display
	mov		bx, dx				;Prepare offset for output
	push		si
	push		cx
	call		Console_Write_Hex_16
	pop		cx
	pop		si
	push		cx
	mov		cx, 16				;Display 16 bytes

Display_Bytes:
	mov		bx, [si]			;Take byte at address
	push		cx
	push		si							
	call		Console_Write_Hex_8 		;Output byte to screen
	pop		si
	pop		cx
	inc		si				;Move to next byte
	loop		Display_Bytes
	pop		cx
	pop		si				;Return to the saved address by popping SI from the stack
	
	mov		cx, 16				;Display 16 ASCII characters
Display_ASCII:
	push		si
	call		Console_Write_ASCII		;Output
	pop		si
	inc		si							
	loop		Display_ASCII
	call		Console_Write_CRLF
	pop		cx							
	loop		Display_Line

Continue:
	pop		cx				;Display rest of sector after input
	cmp		cx, 1				;If it's the last pass through, prepare for next input
	je 		Next_Input					
	push		si
	mov		si, continue_message
	call		Console_Write_CRLF
	call		Console_WriteLine_16		;Ask for any key to continue
	call		Console_Write_CRLF
	pop		si
	xor		ah, ah
	int 		16h
	loop		Output

Next_Input:
	xor		ah, ah
	call		Console_Write_CRLF
	jmp		Program

Sector_Error:
	push 		ax
	push		si
	mov		si, sector_error_msg
	call		Console_Write_CRLF
	call		Console_WriteLine_16
	xor		ah, ah
	int 		16h
	pop		si
	pop		ax
	jmp		Program

	
second_stage_msg  db  'Second stage of boot loader running', 0
input_message	  db  'Enter the starting sector number to read: ', 0
continue_message  db  'Press any key to continue...', 0
sector_error_msg  db  'Error! Only 2880 sectors available on disk. Press any key to continue...', 0
boot_device		  db  0
