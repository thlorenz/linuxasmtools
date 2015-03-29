;--------------------------------------------------------------
;>1 syscall
; sys_getgroups32 - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_getgroups32                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_getgroups32:                                  
;              mov  eax,205    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getgroups32
sys_getgroups32:
	mov	eax,205
	int	byte 80h
	or	eax,eax
	ret