; use the INT 0x15, eax= 0xE820 BIOS function to get a memory map

do_e820:
	push es
	xor ax, ax
	mov es, ax
	mov di, 0502h
	xor ebx, ebx		; ebx must be 0 to start
	xor bp, bp		; keep an entry count in bp
	jmp .e820lp

.failed:
	mov eax, MemoryMapFailedString		; "function unsupported" error exit
	jmp fatal_error

.first_time:
	int 0x15
	jc .failed	; carry set on first call means "unsupported function"
	mov edx, 0x0534D4150	; Some BIOSes apparently trash this register?
	cmp eax, edx		; on success, eax must have been reset to "SMAP"
	jne .failed
	test ebx, ebx		; ebx = 0 implies list is only 1 entry long (worthless)
	je .failed
	jmp .jmpin

.e820lp:
	mov edx, 0x0534D4150	; Place "SMAP" into edx
	mov eax, 0xe820		; eax, ecx get trashed on every int 0x15 call
	mov [es:di + 20], dword 1	; force a valid ACPI 3.X entry
	mov ecx, 24		; ask for 24 bytes again
	test bp, bp
	je .first_time
	int 0x15
	jc .e820f		; carry set means "end of list already reached"
.jmpin:
	jcxz .e820lp		; skip any 0 length entries
	inc bp			; got a good entry: ++count, move to next storage spot
	add di, 24
	test ebx, ebx		; if ebx resets to 0, list is complete
	jne .e820lp
.e820f:
	mov [es:0500h], bp	; store the entry count
	pop es
