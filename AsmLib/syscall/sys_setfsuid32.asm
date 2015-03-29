;--------------------------------------------------------------
;>1 syscall
; sys_setfsuid32 - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_setfsuid32                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_setfsuid32:                                   
;              mov  eax,215    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setfsuid32
sys_setfsuid32:
	mov	eax,215
	int	byte 80h
	or	eax,eax
	ret