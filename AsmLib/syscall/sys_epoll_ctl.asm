;--------------------------------------------------------------
;>1 syscall
; sys_epoll_ctl - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_epoll_ctl                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_epoll_ctl:                                    
;              mov  eax,255    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_epoll_ctl
sys_epoll_ctl:
	mov	eax,255
	int	byte 80h
	or	eax,eax
	ret