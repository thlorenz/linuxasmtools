
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
  [section .text]

;-------------------------------------------------------------------
; sys_parse - local function to parse input line
;  input: esi = ptr to command line as follows:
;               -executable filename
;               -0     (end of filename)
;               -optional parameter or 0 if end of parameters
;               -0     (end of parameter)
;               -optional parameter or 0 if end of parameters
;               -0     (end of parameter)
;               -(add additional parameters here)
;         note: executable filename can be full path, local file
;               else the $PATH is searched for file.
; optput: al=0  if success and:
;               [execve_full_path] = ptr to full executable path
;               [exc_args]         = array of parameters, first
;                                    parameter is executable name
;         al=-1 if enviro_ptrs not set up.
  global sys_parse
sys_parse:
  mov	[parse_ptr],esi
  cmp	byte [esi],'/'		;check if full path
  je	sys_full		;jmp if esi points to full path + parameters
;get local path
  mov	eax,183		;kernel call getcwd
  mov	ebx,lib_buf+200
  mov	ecx,200		;lenght of buffer
  int	80h
;add filename and all parameters to end of path
  mov	esi,ebx
  call	str_end
  mov	edi,esi
  mov	al,'/'
  stosb
  call	append_entry_string
;check if we have execute access to file
  mov	eax,33		;kernel access call
  mov	ecx,1		;modes read & write & execute
  mov	ebx,lib_buf+200
  int	80h
  or	eax,eax
  jz	sys_full	;jmp if local executable
;
; this is not a local executable or full path,
; try searching the path
;
  mov	ebx,[enviro_ptrs]
  or	ebx,ebx
  jz	spa_fail			;jmp if pointer setup
  mov	ebp,[parse_ptr]
  call	env_exec
  jc	spa_fail			;jmp if name not found
  mov	esi,ebx			;esi=ptr to full path of executable
  mov	edi,lib_buf+200
  call	str_move
sp_bk_lp:
  dec	edi
  cmp	byte [edi],'/'
  jne	sp_bk_lp		;find executable filename start
  inc	edi
  call	append_entry_string
;
;full path plus parameters at -esi-
;
sys_full:
  mov	edx,execve_full_path		;parameter ptrs build area
;store pointers to parameters
spa_lp1:
  cmp	byte [esi],0
  je	spa_done			;jmp if no more parameters
  push	esi			;save current parameter ptr
; scan to end of path/parameter
spa_lp2:
  lodsb
  or	al,al			;check if end of parameters
  jne	spa_lp2			;loop till end of full path
;
  pop	ebx
  mov	[edx],ebx
  add	edx,4			;move to next pointer stuff
  xor	eax,eax
  mov	[edx],eax		;pre-stuff terminating zero dword for pointers
  jmp	short spa_lp1		;go do next parameter
spa_fail:
  mov	al,-1			;env setup needed
spa_done:
  ret
;-------------
  [section .data]
parse_ptr:  dd	0	;ptr to entry strings
  [section .text]
;------------------------------------------------------------
append_entry_string:
  mov	esi,[parse_ptr]
sp_mov_lp1:
  call	str_move	;append file name
  inc	edi
  cmp	byte [esi],0	;end of all parameters
  jne	sp_mov_lp1	;loop till all parameters moved
  xor	eax,eax
  stosd
  mov	esi,lib_buf+200
  ret
;--------------------------------------------------------------------
;>1 sys
;  sys_fork_run - fork and execute program
; INPUTS
;    esi = ptr to command line as follows:
;       name - executable name terminated with zero byte
;       separator - zero byte if end of all parameters, else next parameter appears here
;       paramaterx - any string terminated with zero byte
;       end - a zero byte.
;
;    examples: db "/bin/dir",0               ;no parameters, full path
;              db "myprog,0,"parameter1",0,0 ;local executable, one parameter
;              db "dir",0,"*",0,0            ;executable on path, one parameter
;
;    [enviro_ptrs] - must be initialized by env_stack call at start
;                    of program.
;    buffer "lib_buf" is used to build path
; OUTPUT
;    eax = -1 if error
;        = launched PID if success
; NOTES
;   source file: sys_run.asm
;<
; * ----------------------------------------------
  global sys_fork_run
sys_fork_run:
  call	sys_parse
  or	al,al
  jz	sfr_cont	;jmp if parse ok
  mov	eax,-1
  jmp	short sfr_exit
;
; fork our program into two parts
;  returns:  eax = zero to child, pid to parent or negative error
;
sfr_cont:
  mov	eax,2
  int	80h		;fork
  mov	ebx,eax		;save PID
  or	eax,eax		;check if we are child process
  jnz	sparent		;jmp if parent
;
; this is the child - call kernel execve function
  mov	ebx,[execve_full_path]
  mov	ecx,execve_full_path
  mov	edx,[enviro_ptrs]
  mov	eax,11		;execve
  int	80h
;
; if we get here all attempts to execute a program failed
;
  mov	eax,1
  int	byte 80h
;
; wait for external program to complete
;  input: ebx = process id to wait for
;  returns: eax = id of job exiting, or negative error
;
sparent:
sfr_exit:
  ret
 
;--------------------------------------------------------------------
;>1 sys
;  sys_run_die - launches executable then dies
; INPUTS
;    esi = ptr to command line as follows:
;       name - executable name terminated with zero byte
;       separator - zero byte if end of all parameters, else next parameter appears here
;       paramaterx - any string terminated with zero byte
;       end - a zero byte.
;
;    examples: db "/bin/ls",0,0                 ;no parameters, full path
;              db "myprogram,0,"parameter1",0,0 ;local executable, one parameter
;              db "dir",0,"*",0,0               ;executable on path, one parameter
;
;    [enviro_ptrs] - must be initialized by env_stack call at start
;                    of program.
;    buffer "lib_buf" is used to build path
; OUTPUT
;    al = byte two of execve_status if error occured, else
;         no return occurs.
;    [execve_status] - contains results from execve
;      al = 0 success
;      al = 11 could not launch child
;      al = 12 name not found on path
;      al = negative (system error code)
;           -1=enviro_ptrs not setup
;      flags set for jz,js,jnz,jns jumps
; NOTES
;    source file: sys_run.asm
;     
;    sys_run_die begins by checking if the full path is provided, if
;    not it looks in the local directory, if not found it searchs
;    the path.  When found the file is executed
;<
;  * ----------------------------------------------
  extern str_move,lib_buf,env_exec
  extern enviro_ptrs
  extern str_end

  global sys_run_die
sys_run_die:
  call	sys_parse
  or	al,al
  jnz	srd_exit
; call kernel execve function
  mov	ebx,[execve_full_path]
  mov	ecx,execve_full_path
  mov	edx,[enviro_ptrs]
  mov	eax,11		;execve
  int	80h
;
; if we get here all attempts to execute a program failed
;
  mov	ebx,11h			;no child process
srd_exit:
  or	eax,eax
  ret	    		;abort out

;--------------------------------------------------------------------
;>1 sys
;  sys_run_wait - execute program and wait for completiion
; INPUTS
;    esi = ptr to command line as follows:
;       name - executable name terminated with zero byte
;       separator - zero byte if end of all parameters, else next parameter appears here
;       paramaterx - any string terminated with zero byte
;       end - a zero byte.
;
;    examples: db "/bin/dir",0               ;no parameters, full path
;              db "myprog,0,"parameter1",0,0 ;local executable, one parameter
;              db "dir",0,"*",0,0            ;executable on path, one parameter
;
;    [enviro_ptrs] - must be initialized by env_stack call at start
;                    of program.
;    buffer "lib_buf" is used to build path
; OUTPUT
;    failure - eax= negative error code
;
;    possible
;    success - eax=pid of completed process
;              
;              if bl=0 then bh=process exit code
;              if bl=1-7e then bh=signal that killed process
;              if bl=7f then bh=signal that stopped process
;              if bl=ff then bh=signal that continued process
;    flags set for "js" and "jns" on eax state
; NOTES
;   source file: sys_run.asm
;<
; * ----------------------------------------------
  global sys_run_wait
sys_run_wait:
  call	sys_parse
  or	al,al
  jnz	srw_exit
;
; fork our program into two parts
;  returns:  eax = zero to child, pid to parent or negative error
;
  mov	eax,2
  int	80h		;fork
  mov	ebx,eax		;save PID
  or	eax,eax		;check if we are child process
  jnz	parent		;jmp if parent
;
; this is the child - call kernel execve function
  mov	ebx,[execve_full_path]
  mov	ecx,execve_full_path
  mov	edx,[enviro_ptrs]
  mov	eax,11		;execve
  int	80h
;
; if we get here all attempts to execute a program failed
;
  mov	al,11h			;no child process
  jmp	short srw_exit 		;abort out
;
; wait for external program to complete
;  input: ebx = process id to wait for
;  returns: eax = id of job exiting, or negative error
;
parent:
  mov	ecx,execve_status
  xor	edx,edx
  mov	eax,7
  int	80h			;wait for child, PID in ebx
  mov	bx,[execve_status]
srw_exit:
  or	eax,eax
  ret


;
;--------------------------------------------
 [section .data]

parameters_ptr:		dd	0	;temp for parsing

execve_full_path:	dd	0
exc_args:		dd	0	;ptr to parameter1
			dd	0	;ptr to parameter2
			dd	0	;ptr to parameter3
			dd	0,0,0,0	;additional parameters

execve_status		db	0,0,0,0,0,0,0,0

  [section .text]
       