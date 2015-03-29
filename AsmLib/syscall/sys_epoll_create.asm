;--------------------------------------------------------------
;>1 syscall
; sys_epoll_create - kernel function                        
;
;    INPUTS 
;     see AsmRef function -> sys_epoll_create                                    
;
;    Note: functon call consists of four instructions
;          
;          sys_epoll_create:                                 
;              mov  eax,254    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_epoll_create
sys_epoll_create:
	mov	eax,254
	int	byte 80h
	or	eax,eax
	ret