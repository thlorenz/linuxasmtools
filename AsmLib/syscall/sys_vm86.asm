;--------------------------------------------------------------
;>1 syscall
; sys_vm86 - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_vm86                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_vm86:                                         
;              mov  eax,166    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_vm86
sys_vm86:
	mov	eax,166
	int	byte 80h
	or	eax,eax
	ret