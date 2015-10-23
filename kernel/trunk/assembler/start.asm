[BITS 64]

%define STACK_SIZE 1000h
	
SECTION .text
	
[extern idt_init]
[extern kmain]

[global start]
start:
	mov rsp, stack_end
	
	call idt_init
	
	jmp kmain



SECTION .bss

stack_begin:
    RESB STACK_SIZE		; reserve place for kernel stack
stack_end:
