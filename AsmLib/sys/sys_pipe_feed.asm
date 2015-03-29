
;   Copyright (C) 2007 Jeff Owens
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.


  [section .text align=1]
  extern dword_to_ascii,lib_buf,str_move
  extern file_simple_read
  extern check_pid

  [section .text]
;---------------------------------------------------------
;****f* sys/sys_pipe_feed *
; NAME
;>1 sys
;  sys_pipe_feed - launch program and pipe to it's STDIN
; INPUTS
;    eax = ptr to program string
;          this is an ELF executable.
;          Not all programs accept a pipe for STDIN
;    ebx = pointer to function that will feed characters
;          to ELF executable in eax
;          The feed program recieves child pid in eax
;          and write pipe (fd) in ebx.
;    a simple feed program to watch for ESC key:
;      feed_keys:
;        mov	[fk_pid],eax		;save child pid
;        mov	[fk_pipe],ebx		;save output pipe
;      key_loop:
;        call	key_mouse2
;      
;        or	al,al
;        jz	feed_keys		;jmp if zero read
;      
;        cmp	word [kbuf],001bh
;        je	fk_done			;if esc pressed exit
;      
;        mov	ebx,[child_pid]
;        call	check_pid
;        cmp	al,'Z'		;zombie?
;        je	fk_done
;        cmp	al,'T'		;stopped?
;        je	fk_done
;      
;        mov	ebx,[fk_pipe]
;        mov	ecx,kbuf
;      ; now pipe (feed) key to our child
;      char_loop:
;        mov	edx,1
;        mov	eax,4
;        int	80h
;      
;        or	eax,eax
;        js	fk_done
;        inc	ecx
;        cmp	byte [ecx],0
;        jne	char_loop
;        jmp	key_loop
;      fk_done:
;        ret
;      ;--------------
;        [section .data]
;      fk_pid:	dd	0
;      fk_pipe: dd	0
;        [section .text]
; OUTPUT
;    eax = shell program exit status (in -al-)
;          (if eax negative an error occured)
; NOTES
;    source file: sys_pipe_feed.asm
;<
;  * ----------------------------------------------
;*******
  [section .text]
  extern enviro_ptrs
  extern key_mouse2
  extern kbuf
;
  global sys_pipe_feed
sys_pipe_feed:
  mov	[callers_feed_process],ebx
; parse callers command into fields and save pointers
  mov	edi,lib_buf
  mov	esi,eax
  mov	ecx,callers_cmd
save_parameter:
  mov	[ecx],edi
  add	ecx,4		;move to next store point
scan_lp:
  lodsb
  stosb
  cmp	al,' '
  jne	scan_cont
  mov	byte [edi -1],0
  jmp	short save_parameter
scan_cont:
  or	al,al
  jnz	scan_lp		;scan for parameters
  
  mov	eax,42		;pipe
  mov	ebx,filides
  int	80h

;  call	block

; fork
  mov	eax,2		;fork
  int	80h
  mov	[child_pid],eax
  or	eax,eax
  jz	child_process
; parent process continues, eax = child PID

  mov	eax,6		;close
  mov	ebx,[read_fd]	;  pipe for reading
  int	80h

  mov	eax,6		;close
  mov	ebx,1		;  stdout
  int	80h
; the parent now feeds keystrokes to write_fd
; until an exit key is read or the child dies
;
  mov	ebx,[child_pid]
  call	check_pid
  js	kill_child	;exit if child dead
  cmp	al,'Z'		;zombie?
  je	kill_child
  cmp	al,'T'		;stopped?
  je	kill_child

  mov	eax,[child_pid]
  mov	ebx,[write_fd]
  call	[callers_feed_process]
;
;kill child
kill_child:
  mov	eax,6		;close
  mov	ebx,[write_fd]	;  pipe for writing
  int	80h

  mov	eax,37
  mov	ebx,[child_pid]
  mov	ecx,9		;kill signal
  int	80h

;wait for child to exit
wait_child:
  mov	ebx,[child_pid]
  mov	ecx,execve_status
  xor	edx,edx
  mov	eax,7
  int	80h			;wait for child, PID in ebx
;get status of child process
  sub	eax,eax
  mov	al,byte [execve_status +1]
  or	al,al
  ret  
;-------------------
child_process:

  mov	eax,6		;close
  mov	ebx,[write_fd]	;  pipe for writing
  int	80h

  mov	eax,63		;dup2
  mov	ebx,[read_fd]
  mov	ecx,0		;read_fd -> stdin
  int	80h

; execute shell program
  mov	ebx,[execve_full_path]
  mov	ecx,execve_full_path
  mov	edx,[enviro_ptrs]
  mov	eax,11		;execve
  int	80h
;
; if we get here all attempts to execute a program failed
;
abort:
  mov	eax,6		;close write pipe
  mov	ebx,[read_fd]
  int	80h

  mov	eax,6		;close write pipe
  mov	ebx,[write_fd]
  int	80h
  
  mov	ebx,11h			;no child process
  mov	eax,1
  int	80h			;abort out
;--------------------------------------------
 [section .data]

callers_cmd:
execve_full_path:	dd	0 ;shell_string
exc_args:		dd	0 ;shell_parm	;ptr to parameter1
            		dd	0	;ptr to parameter2
			dd	0	;ptr to parameter3
			dd	0
			dd	0

execve_status		db	0,0,0,0,0,0,0,0

filides:		;filled in by pipe function
read_fd: dd	0
write_fd: dd	0
;
; child data area
child_pid  dd	0
callers_feed_process	dd	0

  [section .text]
;-------------------

  


