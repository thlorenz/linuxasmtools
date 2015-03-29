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
sys_parse:
  mov	[parse_ptr],esi
;replace spaces with zeros
sp_lp1:
  lodsb
  cmp	al,' '
  jne	sp_lp1
  mov	[esi -1],byte 0
  cmp	[esi],byte ' '
  jne	sp_lp1
  mov	[esi],byte 0		;put double zero at end
  
  mov	esi,[parse_ptr]
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
  mov	esi,rusage_struc
  mov	eax,114
  int	80h			;wait for child, PID in ebx
  mov	ax,[execve_status]
srw_exit:
  or	al,al
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

rusage_struc:
ru_utime_s:       dd  0  ;struct timeval ru_utime; /* user time used */
ru_utime_u:	  dd  0  ;microseconds
ru_stime_s:       dd  0 ;struct timeval ru_stime; /* system time used */
ru_stime_u:	  dd  0 ;microseconds
                dd  0 ; ru_maxrss;        /* maximum resident set size */
                dd  0 ; ru_ixrss;         /* integral shared memory size */
                dd  0 ; ru_idrss;         /* integral unshared data size */
                dd  0 ; ru_isrss;         /* integral unshared stack size */
                dd  0 ; ru_minflt;        /* page reclaims */
                dd  0 ; ru_majflt;        /* page faults */
                dd  0 ; ru_nswap;         /* swaps */
                dd  0 ; ru_inblock;       /* block input operations */
                dd  0 ; ru_oublock;       /* block output operations */
                dd  0 ; ru_msgsnd;        /* messages sent */
                dd  0 ; ru_msgrcv;        /* messages received */
                dd  0 ; ru_nsignals;      /* signals received */
                dd  0 ; ru_nvcsw;         /* voluntary context switches */
                dd  0 ; ru_nivcsw;        /* involuntary context switches */

  [section .text]
       