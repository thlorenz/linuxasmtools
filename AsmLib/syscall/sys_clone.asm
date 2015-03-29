;--------------------------------------------------------------
;>1 syscall
; sys_clone - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_clone                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_clone:                                        
;              mov  eax,120    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_clone
sys_clone:
	mov	eax,120
	int	byte 80h
	or	eax,eax
	ret