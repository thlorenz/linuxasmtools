;--------------------------------------------------------------
;>1 syscall
; sys_vm86old - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_vm86old                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_vm86old:                                      
;              mov  eax,113    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_vm86old
sys_vm86old:
	mov	eax,113
	int	byte 80h
	or	eax,eax
	ret