[BITS 64]

%define CHANDLER c_isr_handler 	;some constants used later
%define IDT_IST 000b
%define IDT_TYPE 1110b
%define IDT_DPL 11b
%define IDT_P 1b
%define IDT_SELECTOR 0x8

%macro ISR 1 			; isr routine pushing number and error code if not pushed
	isr%1:	
		cli
		%if %1 = 8	;check if it is interrupt, that has error code
		%elif %1 = 10
		%elif %1 = 11
		%elif %1 = 12
		%elif %1 = 13
		%elif %1 = 14
		%elif %1 = 17
		%else
			push qword 0 ;otherwise we push 0
		%endif
		push qword %1 	;push int num.
		jmp isr_common
%endmacro
	
%macro IDT_ENTRY 1 		; Wrong idt entry, we have to switch part of address later on
	dd (IDT_IST) | (IDT_TYPE << 8) | (IDT_DPL << 13) | (IDT_P << 15) | (IDT_SELECTOR << 16)
	dq isr%1
	dd 0
%endmacro
	
%assign n 0 			; We define 256 isr routines
%rep 256
	ISR n
	%assign n n+1
%endrep

idt:
%assign n 0			; and 256 idt entries
%rep 256
	IDT_ENTRY n
	%assign n n+1
%endrep

idt_ptr:			; idt pointer
	dw idt_ptr - idt - 1
	dq idt
	
[extern CHANDLER]
	
isr_common:
	push rax ; pushes everything
	push rbx
	push rcx
	push rdx
	push rdi
	push rsi
	push rbp
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
	
	call CHANDLER

	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rbp
	pop rsi
	pop rdi
	pop rdx
	pop rcx
	pop rbx
	pop rax
	
	add rsp, 16
	sti
	iretq

[global idt_init] 		; wanna be called from C
idt_init:
	push rax
	push rbx
	push rcx
	push rdx
	mov rcx, 256		;replace parts of idt entries
	mov rbx, idt		; 256 times
	isr_init_loop:
		mov word ax, [rbx] ; switch parts
		mov word dx, [rbx + 4]
		mov word [rbx + 4], ax
		mov word [rbx], dx
		add rbx, 16	;move pointer to next entry
		loop isr_init_loop
	lidt[idt_ptr]		;load idt
	pop rdx
	pop rcx
	pop rbx
	pop rax
	ret