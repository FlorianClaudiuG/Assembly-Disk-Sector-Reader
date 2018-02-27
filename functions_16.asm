; Various sub-routines that will be useful to the boot loader code	

; Output Carriage-Return/Line-Feed (CRLF) sequence to screen using BIOS

Console_Write_CRLF:
    	mov 		ah, 0Eh					; Output CR
    	mov 		al, 0Dh
    	int 		10h
    	mov 		al, 0Ah					; Output LF
    	int 		10h
    	ret

; Write to the console using BIOS.
; 
; Input: SI points to a null-terminated string

Console_Write_16:
	mov 	ah, 0Eh						; BIOS call to output value in AL to screen

Console_Write_16_Repeat:
	lodsb							; Load byte at SI into AL and increment SI
    	test 		al, al					; If the byte is 0, we are done
	je 		Console_Write_16_Done
	int 		10h					; Output character to screen
	jmp 		Console_Write_16_Repeat

Console_Write_16_Done:
    ret

;Write ASCII symbol for byte value.
;
;Input: SI points to memory location where byte is stored

Console_Write_ASCII:
	mov		ah, 0Eh
	mov		al, byte [si]
	cmp		al, 32
	jbe		Output_Underscore
	int		10h
	ret

Output_Underscore:
	mov		ah, 0Eh
	mov 		al, 5Fh
	int		10h
	ret

; Write string to the console using BIOS followed by CRLF
; 
; Input: SI points to a null-terminated string

Console_WriteLine_16:
	call 		Console_Write_16
	call 		Console_Write_CRLF
	ret

; Write content of bx as an int to the screen.
;
; Input: BX = Value to output
	
Console_Write_Int:
	mov		si, IntBuffer + 4
	mov		ax, bx
	
GetDigit:
	xor		dx, dx
	mov		cx, 10
	div 		cx
	add		dl, 48
	mov		[si], dl
	dec 		si
	cmp		dx, 0
	jne		GetDigit
	inc 		si
	call		Console_Write_16
	ret
	
IntBuffer	db '      ', 0

;Write contents of bx as a hexadecimal number to the screen.
;
;Input: BX = Value to output

Console_Write_Hex_16:
	mov		cx, 4
	jmp		HexLoop
	
Console_Write_Hex_8:
	mov		cx, 2
	rol		bx, 8
	
HexLoop:
	rol		bx, 4
	mov		si, bx
	and		si, 000Fh
	mov		al, byte[si + HexChars]
	mov		ah, 0Eh
	int 		10h
	loop		HexLoop

Console_Write_Space:
	mov		ah, 0Eh
	mov		al, 20h
	int		10h
	ret
	
HexChars	db '0123456789ABCDEF'