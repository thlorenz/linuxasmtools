;--------------------------------------------------------------
;>1 syscall
; sys_epoll_pwait - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_epoll_pwait                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_epoll_pwait:                                  
;              mov  eax,319    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_epoll_pwait
sys_epoll_pwait:
	mov	eax,319
	int	byte 80h
	or	eax,eax
	ret