;--------------------------------------------------------------
;>1 syscall
; sys_ipc - kernel function                                 
;
;    INPUTS 
;     see AsmRef function -> sys_ipc                                             
;
;    Note: functon call consists of four instructions
;          
;          sys_ipc:                                          
;              mov  eax,117    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ipc
sys_ipc:
	mov	eax,117
	int	byte 80h
	or	eax,eax
	ret