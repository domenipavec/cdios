;;
;; enableA20.asm (adapted from Visopsys OS-loader)
;;
;; Copyright (c) 2000, J. Andrew McLaughlin
;; You're free to use this code in any manner you like, as long as this
;; notice is included (and you give credit where it is due), and as long
;; as you understand and accept that it comes with NO WARRANTY OF ANY KIND.
;; Contact me at <andy@visopsys.org> about any bugs or problems.
;;

;; This subroutine will enable the A20 address line in the keyboard
;; controller.  Takes no arguments.  Returns 0 in EAX on success,
;; -1 on failure.  Written for use in 16-bit code, see lines marked
;; with 32-BIT for use in 32-bit code.

call check_a20 ; if already enabled
cmp ax, 1
je A20.end

mov ax, 2401h
int 15h

call check_a20
cmp ax, 1
je A20.end

call    a20wait ; we disable keyboard first
mov     al,0xAD
out     0x64,al


;; Keep a counter so that we can make up to 5 attempts to turn
;; on A20 if necessary
mov CX, 5

A20.startAttempt1:
;; Wait for the controller to be ready for a command
call a20wait

;; Tell the controller we want to read the current status.
;; Send the command D0h: read output port.
mov AL, 0D0h
out 64h, AL

;; Wait for the controller to be ready with a byte of data
call a20wait_read

;; Read the current port status from port 60h
in AL, 60h
push ax

;; Wait for the controller to be ready for a command
call a20wait

;; Tell the controller we want to write the status byte again
mov AL, 0D1h
out 64h, AL

;; Wait for the controller to be ready for the data
call a20wait

;; Turn on the A20 enable bit
pop ax
or AL, 00000010b
out 60h, AL

;; Finally, we will attempt to read back the A20 status
;; to ensure it was enabled.

call check_a20

;; Is A20 enabled?
cmp AX, 1

;; Check the result.  If carry is on, A20 is on.
je A20.success

;; Should we retry the operation?  If the counter value in ECX
;; has not reached zero, we will retry
loop A20.startAttempt1


;; Well, our initial attempt to set A20 has failed.  Now we will
;; try a backup method (which is supposedly not supported on many
;; chipsets, but which seems to be the only method that works on
;; other chipsets).


;; Keep a counter so that we can make up to 5 attempts to turn
;; on A20 if necessary
mov CX, 5

A20.startAttempt2:
;; Wait for the keyboard to be ready for another command
call a20wait

;; Tell the controller we want to turn on A20
mov AL, 0DFh
out 64h, AL

;; Again, we will attempt to read back the A20 status
;; to ensure it was enabled.

call check_a20

;; Is A20 enabled?
cmp AX, 1

;; Check the result.  If carry is on, A20 is on, but we might warn
;; that we had to use this alternate method
je A20.success

;; Should we retry the operation?  If the counter value in ECX
;; has not reached zero, we will retry
loop A20.startAttempt2


;; OK, we weren't able to set the A20 address line.  Do you want
;; to put an error message here?
call    a20wait ; and enable keyboard again
mov     al,0xAE
out     0x64,al

mov EAX, A20failed
jmp fatal_error

a20wait: ; some wait functions here
        in      al,0x64
        test    al,2
        jnz     a20wait
        ret
 
 
a20wait_read:
        in      al,0x64
        test    al,1
        jz      a20wait_read
        ret

check_a20:
	pushf
	push ds
	push es
	push di
	push si
	push bx
	
	xor ax, ax ; ax = 0
	mov es, ax
	
	not ax ; ax = 0xFFFF
	mov ds, ax
	
	mov di, 0x0500
	mov si, 0x0510
	
	mov al, byte [es:di]
	push ax
	
	mov al, byte [ds:si]
	push ax
	
	mov byte [es:di], 0x00
	mov byte [ds:si], 0xFF

	wbinvd 			; flush caches

	mov ax, 0
	
	cmp byte [es:di], 0xFF
	je check_a20_exit

	mov ax, 1

	check_a20_exit:
	
	pop bx
	mov byte [ds:si], bl
	
	pop bx
	mov byte [es:di], bl

	pop bx
	pop si
	pop di
	pop es
	pop ds
	popf
	
	ret

A20.success:

call    a20wait ; and enable keyboard again
mov     al,0xAE
out     0x64,al

A20.end: