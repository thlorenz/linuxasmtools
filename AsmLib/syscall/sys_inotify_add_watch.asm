;--------------------------------------------------------------
;>1 syscall
; sys_inotify_add_watch - kernel function                   
;
;    INPUTS 
;     see AsmRef function -> sys_inotify_add_watch                               
;
;    Note: functon call consists of four instructions
;          
;          sys_inotify_add_watch:                            
;              mov  eax,292    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_inotify_add_watch
sys_inotify_add_watch:
	mov	eax,292
	int	byte 80h
	or	eax,eax
	ret