;--------------------------------------------------------------
;>1 syscall
; sys_geteuid32 - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_geteuid32                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_geteuid32:                                    
;              mov  eax,201    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_geteuid32
sys_geteuid32:
	mov	eax,201
	int	byte 80h
	or	eax,eax
	ret