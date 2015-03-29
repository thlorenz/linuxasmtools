;--------------------------------------------------------------
;>1 syscall
; sys_pivot_root - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_pivot_root                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_pivot_root:                                   
;              mov  eax,217    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_pivot_root
sys_pivot_root:
	mov	eax,217
	int	byte 80h
	or	eax,eax
	ret