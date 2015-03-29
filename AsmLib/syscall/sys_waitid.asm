;--------------------------------------------------------------
;>1 syscall
; sys_waitid - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_waitid                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_waitid:                                       
;              mov  eax,284    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_waitid
sys_waitid:
	mov	eax,284
	int	byte 80h
	or	eax,eax
	ret