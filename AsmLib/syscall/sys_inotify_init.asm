;--------------------------------------------------------------
;>1 syscall
; sys_inotify_init - kernel function                        
;
;    INPUTS 
;     see AsmRef function -> sys_inotify_init                                    
;
;    Note: functon call consists of four instructions
;          
;          sys_inotify_init:                                 
;              mov  eax,291    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_inotify_init
sys_inotify_init:
	mov	eax,291
	int	byte 80h
	or	eax,eax
	ret