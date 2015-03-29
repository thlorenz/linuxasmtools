;--------------------------------------------------------------
;>1 syscall
; sys_lchown32 - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_lchown32                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_lchown32:                                     
;              mov  eax,198    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_lchown32
sys_lchown32:
	mov	eax,198
	int	byte 80h
	or	eax,eax
	ret