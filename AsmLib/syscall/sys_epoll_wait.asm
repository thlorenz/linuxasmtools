;--------------------------------------------------------------
;>1 syscall
; sys_epoll_wait - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_epoll_wait                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_epoll_wait:                                   
;              mov  eax,256    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_epoll_wait
sys_epoll_wait:
	mov	eax,256
	int	byte 80h
	or	eax,eax
	ret