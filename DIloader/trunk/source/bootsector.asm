;***************************************************************************************
;* bootsector.asm                                                                      *
;* Created on: ned maj 24 2009                                                         *
;* Part of DIloader - Domen Ipavec boot loader                                         *
;*-------------------------------------------------------------------------------------*
;* Your description here.                                                              *
;*-------------------------------------------------------------------------------------*
;* Copyright (c) 2009 by Domen Ipavec                                                  *
;* All rights reserved.                                                                *
;***************************************************************************************

[BITS 16]
[ORG 0x00]

cld
cli

jmp 07C0h:start ; ensure we are at right address

start:

xor ax, ax
mov ss, ax

mov ax, cs ; other selectors to same as cs
mov ds, ax 
mov es, ax
mov fs, ax
mov gs, ax

mov esp, 07C00h; set stack pointer (esp make sure we don't have junk in higher half)

mov [BootDrive], dl ; Save boot drive, we might corrupt it

;xor ah, ah
;mov al, 02h ; set 80x25 text mode
mov ax, 08h ; same as above, except one byte smaller
int 10h

push LoadingString ; write loading string
call print_string
; add sp, 2
inc sp ; 2 times inc only 2 bytes, while add is 4 bytes
inc sp 

call print_newline

mov ah, 41h ; check if 13h extensions are supported
mov bx, 055AAh
int 13h
jnc Supported13h
	mov ax, NotSupported13hString ; if not fatal error
	jmp fatal_error

no_long_mode: ; no supported long mode (we don't get here we jump back if it is not supported)
	mov ax, NotSupportedLongModeString
	jmp fatal_error

Supported13h:

; Use CPUID to determine if the processor supports long mode. ;
mov   eax, 80000000h ;  Extended-function 8000000h.
cpuid                 ; Is largest extended function
cmp   eax, 80000000h ;  any function > 80000000h?
jbe   no_long_mode    ; If not, no long mode.
mov   eax, 80000001h ;  Extended-function 8000001h.
cpuid                 ; Now EDX = extended-features flags.
bt    edx, 29         ; Test if long mode is supported.
jnc   no_long_mode    ; Exit if not supported.

%include "memoryMap.asm"

%include "enableA20.asm"
	
; we will need unreal mode
push ds                ; save real mode
lgdt [unreal_gdtinfo]         ; load gdt register
mov  eax, cr0          ; switch to pmode by
or al,1                ; set pmode bit
mov cr0, eax
mov bx, 0x08          ; select descriptor 1
mov ds, bx            ; 8h = 1000b
and al,0xFE            ; back to realmode
mov cr0, eax          ; by toggling bit again
pop ds                 ; get back old segment


mov byte [AddressPacket.size], 10h ; size is 10h
mov word [AddressPacket.num], 01h ; we load only 1 sector each time for safety

xor eax, eax
mov [AddressPacket.res], al ; reserved to zero
mov [AddressPacket.blonum], eax ; we init this to 0
mov [AddressPacket.blonum + 4], eax

push FSBuffer ; we will first load to FSBuffer
call set_load_address
inc sp
inc sp

mov eax, 0Fh ; first volume descripto is 10h
VolumeDescriptorsLoop: ; find Primary Volume Descriptor
	inc ax ; we increase each loop, so we init one lower
	push eax
	call load_sector_to_buffer
	add sp, 4
	cmp byte [FSBuffer], 01h ; if primary
	je PrimaryVolumeDescriptorFound
	cmp byte [FSBuffer], 0FFh ; if terminator we went too far
	je VolumeDescriptorLoopError
	cmp ax, 30h ; we shouldn't have that many descriptors
	jne VolumeDescriptorsLoop

VolumeDescriptorLoopError:
	mov ax, VolumeDescriptorError
	jmp fatal_error

PrimaryVolumeDescriptorFound:

mov eax, [FSBuffer + 166] ; total size of directory records
mov [RootDirSize], eax
mov eax, [FSBuffer + 158] ; get first sector num
mov [RootDirFirstSector], eax

push KernelFile
call find_file
add sp, 2

mov edx, eax
shr edx, 16

mov cx, 800h
div cx

cmp dx, 0
je NoRemainder
	inc ax
NoRemainder:

mov cx, 10
cmp ax, cx
jge NoCXChange
	mov cl, al
NoCXChange:

mov [LoadingSize], cx
mov [LoadingAddress], ebx

call load_full_buffer

push LoadBuffer ; check if we have valid elf64 file
push word 5
push ElfIdentifier
push word 5
call string_compare
add sp, 8

cmp al, 1
je elf_file_ok ; if it is not valid elf64 file we print error
	mov eax, InvalidExecFile
	jmp fatal_error
elf_file_ok:

;; LB ... LoadBuffer
;; LB+24 = EntryPoint (8)
;; LB+32 = ProgramHeaderOffset (8)
;; LB+56 = ProgramHeaderNum (2)

push dword [LoadBuffer+28] ; try to push qword but is it correct?
push dword [LoadBuffer+24]

mov ebp, esp

mov ebx, [LoadBuffer+32]
xor ecx, ecx
mov cx, [LoadBuffer+56]
elf_parser_loop:
	cmp dword [LoadBuffer + ebx], 1
	jne elf_parser_loop_end ; we skip it if it is not for loading
		mov edx, [LoadBuffer + ebx + 16] ; address to load
		mov eax, [LoadBuffer + ebx + 8] ; address in file
		mov esi, [LoadBuffer + ebx + 32] ; size in file
		cmp [LoadBuffer + ebx + 40], esi ; cmp sizes
		jng elf_parser_loop_no_zero
			mov edi, [LoadBuffer + ebx + 40] ; if more in memory we zero it
			sub edi, esi
			push edi ; push size
			mov edi, edx
			add edi, esi
			push edi ; push address
			call put_zeros
			add sp, 8
		elf_parser_loop_no_zero:

		cmp esi, 0
		je elf_parser_loop_end ; if we don't have file size, no need to load

			push edx ; we save addresses for next loop (loading)
			push eax
			push esi
	
	elf_parser_loop_end:
	add ebx, 56 		; move to next elf header
	loop elf_parser_loop

mov ecx, 20480 ; size of load buffer (but with it we actually trace current position that is loaded of file)

elf_load_loop:	   ; for each section of elf file
	pop esi ; size in file (pop values pushed in previous loop)
	pop eax ; address in file
	pop edx ; address to load
	
	elf_load_check_startok:
		cmp ecx, eax 	; if the start address of section is not yet in the buffer we must first load till there
		jg elf_load_startok
			call load_full_buffer ; load one full buffer 
			add ecx, 20480	      ; increase current loaded position
			jmp elf_load_check_startok ; and try again
	elf_load_startok:

		mov ebx, eax
		add ebx, esi 	; store end of section in ebx
		cmp ecx, ebx	; if we have end in buffer already we can proceede to the end
		jg elf_load_loop_end
			mov edi, ecx
			sub edi, eax

			mov ebx, 20480
			sub ebx, edi
			
			push ebx
			push edi
			push edx
			call copy
			add sp, 12
	
			add eax, edi
			add edx, edi
			sub esi, edi
			jmp elf_load_check_startok

	elf_load_loop_end:

	mov edi, ecx
	sub edi, eax
	
	mov ebx, 20480
	sub ebx, edi
		
	push ebx
	push esi
	push edx
	call copy
	add sp, 12

	cmp esp, ebp
	jne elf_load_loop

;; enter long mode here;;

; We have to build pages first
xor bx,bx
mov es,bx
mov di,0x1000

mov ax,0x200f
stosw

xor ax,ax
mov cx,0x07ff
rep stosw

mov ax,0x300f
stosw

xor ax,ax
mov cx,0x07ff
rep stosw

mov cx, 0x200
page_table_loop:
	
	mov ax,0x018f
	stosw

	mov ax,bx
	stosw

	add bx, 20h

	xor ax, ax
	stosw
	stosw

	loop page_table_loop

mov eax,10100000b				;Set PAE and PGE
mov cr4,eax

mov edx, 0x00001000				;Point CR3 at PML4
mov cr3,edx

mov ecx,0xC0000080				;Specify EFER MSR

rdmsr						;Enable Long Mode
or eax,0x00000100
wrmsr

mov ebx,cr0					;Activate long mode
or ebx,0x80000001				;by enabling paging and protection simultaneously
mov cr0,ebx					;skipping protected mode entirely

; Load 64-bit 
lgdt [gdt.pointer]

jmp gdt.code:startLongMode

;;; Start of 64-bit code
[BITS 64]
startLongMode equ $ + 7C00h

lidt [pIDT64]

;
; Using fs: and gs: prefixes on memory accesses still uses
; the 32-bit fs.base and gs.base. Reload these 2 registers
; before using the fs: and gs: prefixes. FS and GS can be
; loaded from the GDT using a normal “mov fs,foo” type
; instructions, which loads a 32-bit base into FS or GS.
; Alternatively, use WRMSR to assign 64-bit base values to
; MSR_FS_base or MSR_GS_base.
;
   mov   ecx, 0
   mov   eax, 0
   mov   edx, 0
   wrmsr

pop rax 			; we have jump address pushed 

jmp rax				; jump to the entry point
	
;;;;;;;;;;;;;;;
;; Functions ;;
;;;;;;;;;;;;;;;
[BITS 16]
copy: ; input: address_s(24), size(20), address_k(16)
	push eax
	push ebx
	push ecx	
	push dx

	mov ecx, [esp + 20]; size
	dec ecx
	mov eax, [esp + 24]; we always start at LoadBuffer
	mov ebx, [esp + 16]; address_k
	sub ebx, 7c00h
	add eax, LoadBuffer

	copy_loop:
		mov dl, [eax + ecx]
		mov [ebx + ecx], dl
		loop copy_loop

	mov dl, [eax]
	mov [ebx], dl
	
	pop dx
	pop ecx
	pop ebx
	pop eax
	ret

put_zeros: ; input: size(14), address(10)
	push ecx
	push eax

	mov ecx, [esp + 14]
	mov eax, [esp + 10]
	put_zeros_loop:
		mov byte [eax], 0
		inc eax
		loop put_zeros_loop

	pop eax
	pop ecx
	ret

load_full_buffer: ; input: none we load to LoadBuffer address
	push eax
	push cx
	push dx
	mov eax, [LoadingAddress]
	mov cx, [LoadingSize]
	add ax, cx
	mov [LoadingAddress], eax
	sub ax, cx
	mov dx, LoadBuffer
	load_full_buf_loop:
		push dx
		call set_load_address
		inc sp
		inc sp

		push eax
		call load_sector_to_buffer
		add sp, 4

		inc eax
		add dx, 800h
		loop load_full_buf_loop
	pop dx
	pop cx
	pop eax
	ret	

set_load_address: ; input: address to load (10)
	push eax
	push ebx

	xor eax, eax ; we need an address without segments, so we must add ds*10h to FSBuffer
	mov ax, ds
	imul ax, 10h

	xor ebx, ebx
	mov bx, [esp + 10]
	add eax, ebx
	mov dword [AddressPacket.bufadr], eax

	pop ebx
	pop eax
	ret


find_file: ; input: location of file name - 0 terminated or new line terminated - 0Ah (12); return: eax size, ebx first sector
	push ecx
	push edx
	push si

	xor edx, edx ; pointer to name
	xor ecx, ecx
	mov dx, [esp + 12]

	cmp byte [edx], '/' ; if file name not ok we cannot find file
	jne FileNotFound

	mov eax, [RootDirSize]
	mov ebx, [RootDirFirstSector]

	FileNameLoop:
		mov cx, dx ; we use cx to store start of name
		inc cx
		FileNamePartLoop:
			inc dx
			cmp byte [edx], 0
			je FileFound
			cmp byte [edx], 0Ah
			je FileFound
			cmp byte [edx], '/'
			jne FileNamePartLoop

		push eax
		push ebx
		push cx
		mov si, dx
		sub si, cx
		push si
		push word 2
		call find_name
		add sp, 14
		cmp eax, 0
		jne FileNameLoop
		cmp ebx, 0
		jne FileNameLoop

	FileNotFound:
		mov eax, InvalidFileNameString
		jmp fatal_error

	FileFound:
		push eax
		push ebx
		push cx
		mov si, dx
		sub si, cx
		push si
		push word 0
		call find_name
		add sp, 14
		cmp eax, 0
			jne find_file_return
			cmp ebx, eax
				je FileNotFound

	find_file_return:
	pop si
	pop edx
	pop ecx
	ret


find_name: ; input: size(32), first_sector(28), name location(26), name size(24), dir (2 or 0)(22); return: eax size, ebx first sector
	push ecx
	push edx
	push ebp
	push edi
	push esi

	mov esi, [esp + 32] ; get total size
	add esi, FSBuffer ; we have size + Buffer address in esi, so we can compare to ebx

	mov ebp, [esp + 28] ; get first sector
	push ebp ; and load it
	call load_sector_to_buffer
	add esp, 4
	
	mov ebx, FSBuffer ; first store the address
	xor edi, edi ; set number of iterated sectors to 0
	xor eax, eax
	
	FileNamesLoop:
		sub ebx, eax
	
		cmp byte [ebx], 0
			jnz Continue ; we ain't at end of sector
			inc edi ; we passed another sector
			mov ebx, ebp
			add ebx, edi
			push ebx
			call load_sector_to_buffer ; load this sector
			add sp, 4
			mov ebx, FSBuffer ; we are at start again store the address
			jmp CompareSize
		Continue:
	
		xor ecx, ecx
	
		mov cx, [ebx + 25] ; check if specified type
		and cx, 2
		cmp cx, [esp + 22]
		jne find_name_NoEqual
		
		xor dx, dx
		mov dl, [ebx + 32] ; store length of identifier
	
		cmp dl, 1 ; if length of one
		jne find_name_compare
			cmp byte [ebx + 33], byte 0 ; check if current dir descriptor
				jz find_name_NoEqual ; don't compare

			cmp byte [ebx + 33], byte 1 ; if parent dir descriptor
				jz find_name_NoEqual ; don't compare
	
		find_name_compare:
			cmp cx, 2 ; if dir
				je Dir ; continue
				sub dx, 2 ; if file compare two less (version info)
			Dir:
			push word [esp + 26] ; push searched name
			push word [esp + 26]
			mov cx, bx
			add cx, 33
			push cx ; push current name
			push dx
			call string_compare
			add sp, 8
			cmp al, 1 ; if equal
			jne find_name_NoEqual ; not continue the search
			mov eax, [ebx + 10] ; return size
			mov ebx, [ebx + 2] ; return sector
			jmp find_name_return ; go to return
	
		find_name_NoEqual:
	
		xor eax, eax
		mov al, [ebx] ; add size of this (in eax), so we get address of next(in ebx)
		add ebx, eax
	
		CompareSize:
		
		mov eax, edi
		mov cx, 800h
		mul cx
		add ebx, eax ; add real disk address (with previous sectors)
		cmp ebx, esi ; if we are over size stop
		jc FileNamesLoop

		xor eax, eax ; we didn't find it, return 0
		xor ebx, ebx

	find_name_return:
	pop esi
	pop edi
	pop ebp
	pop edx
	pop ecx
	ret

string_compare: ;input: name1 location(20), name1 size(18), name2 location(16), name2 size(14); return eax - 1 equal, 0 not equal
	push ecx
	push edx
	push ebx

	mov ax, [esp + 14]
	cmp [esp + 18], ax ; check if we even have the same string length
	jne string_compare_NotEqual

	xor ecx, ecx
	xor ebx, ebx
	xor edx, edx

	mov cx, [esp + 14] ; count down
	mov bx, [esp + 20] ; pointer one
	mov dx, [esp + 16] ; pointer two

	string_compare_loop:
		mov al, [edx + ecx - 1]
		cmp [ebx + ecx - 1], al
		jne string_compare_NotEqual
		loop string_compare_loop

	string_compare_Equal: ; if equal
		mov eax, 1 ; we return 1 in eax
		jmp string_compare_return ; go to return

	string_compare_NotEqual: ; if it is not equal we jmp here
		xor eax, eax ; we return 0 in eax

	string_compare_return:
		pop ebx
		pop edx
		pop ecx
		ret

load_sector_to_buffer: ; input: number of sector (example 6th) dword
	push edx ; store registers, so we can restore them
	push ax
	push ecx
	push si

	mov ah, 42h ; we will use int 13h extended read

	mov ecx, [esp + 14]
	mov [AddressPacket.blonum], ecx ; which sector we are loading

	mov dl, [BootDrive] ; we stored boot drive at start
	mov si, AddressPacket ; we need AddressPacket location in si

	mov ecx, 6 ; 6 tries (hmm, quite a lot)
	loading_loop:
		int 13h ; try loading
		jnc loading_success ; return on success
		loop loading_loop ; try again

	mov eax, LoadingErrorString ; not successful
	jmp fatal_error ; print error string

	loading_success: ; successful, restore registers and return
	pop si
	pop ecx
	pop ax
	pop edx
	ret

print_newline: ; no input
	push cx ; we get return on cx
	push bx
	push dx
	push ax

	xor bh, bh ; do on page 0
	mov ah, 03h ; get cursor position func
	int 10h
	inc dh ; increase row position
	xor dl, dl ; zero collumn
	dec ah ; set cursor position func 
	int 10h

	pop ax
	pop dx
	pop bx
	pop cx
	ret

print_string: ; input: address of string
	push ax ; store registers, so we can restore them
	push bx 
	push ecx
	xor ecx, ecx
	mov cx, [esp + 10] ; address of string (sp cannot be used for some reason so we use esp)
	xor bx, bx ;0 for page number
	mov ah, 0Eh ; teletype output function
	print_string_loop:
		mov al, [ecx] ; current char to al
		cmp al, 0 ; if 0
		jz print_string_done ; end loop
		int 10h ; else print it
		inc cx ; increase pointer to string
		jmp print_string_loop ; print again
	print_string_done: ; restore registers and return
		pop ecx
		pop bx
		pop ax 
		ret

fatal_error: ; input: ax - address of string, you can jmp to this, cause it never returns
	push ErrorString ; print Error:
	call print_string
	push ax ; print provided error string
	call print_string
	call print_newline ; go to newline
	push RestartString ; print restart option message
	call print_string

	mov ah, 04h
	int 16h ; flush keyboard buffer
	mov ah, 01h
	wait_for_keypress:
		int 16h
		jz wait_for_keypress ; repeat until key is pressed


	wait_for_controller:
		in al, 064h
		and al, 02h
		cmp al, 0
		jne wait_for_controller ; when equal controller is ready

	mov al, 0FEh ; try restarting
	out 064h, al

	lidt [ZeroSizeIDT] ; try triple fault to restart
	mov al, 0
	div al

	hlt ; halt if restart ain't successful

;; Strings
LoadingString: db 'Loading...', 0
ErrorString: db 'Error: ', 0
RestartString: db 'Remove CD and press any key to restart ...', 0
LoadingErrorString: db "Can't load sector from CD!", 0
NotSupported13hString: db '13h ext unsupported!', 0
InvalidFileNameString: db 'File not found!', 0
VolumeDescriptorError: db 'Filesystem corrupt!', 0
InvalidExecFile: db 'Exec file corrupt!', 0
A20failed: db "Can't enable A20!", 0
NotSupportedLongModeString: db 'Not x86_64 CPU!', 0
MemoryMapFailedString: db "Can't get memory map!", 0
KernelFile: db '/KERNEL/KERNEL.E64', 0
ElfIdentifier: db 07Fh, 'ELF', 2

unreal_gdtinfo:
dw unreal_gdt_end - unreal_gdt - 1   ;size of table
dd unreal_gdt + 7C00h                 ;start of table
	
pIDT64 equ $ + 7C00h           	; IDT table with 0 limit, for 64-bit mode, look up for 7c00h
dw       0    			; IDT limit ..., for base we use zero entry from gdt
ZeroSizeIDT:		      ; 0 size and limit, we use zero entry from gdt
unreal_gdt: dd 0,0        ; entry 0 is always unused
unreal_flatdesc: db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
unreal_gdt_end:

;Global Descriptor Table
gdt:
dq 0x0000000000000000 ;Null Descriptor
.code equ $ - gdt
dq 0x0020980000000000                   
.data equ $ - gdt
dq 0x0000900000000000                   
.pointer:
dw $-gdt-1 ;16-bit Size (Limit)
dq gdt + 7C00h 	; cause we don't have absolute ORG
	
; ensure we have 2 KB
times 2048-($-$$) db 0

;; Variables
BootDrive: db 0

AddressPacket:
.size: db 0
.res: db 0
.num: db 0, 0
.bufadr: db 0, 0, 0, 0
.blonum: db 0, 0, 0, 0, 0, 0, 0, 0

RootDirSize: db 0, 0, 0, 0
RootDirFirstSector: db 0, 0, 0, 0

LoadingSize: db 0, 0
LoadingAddress: db 0, 0, 0, 0

FSBuffer: times 800h db 0

ConfigBuffer: times 800h db 0

LoadBuffer:
