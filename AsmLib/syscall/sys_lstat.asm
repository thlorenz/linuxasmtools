;--------------------------------------------------------------
;>1 syscall
; sys_lstat - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_lstat                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_lstat:                                        
;              mov  eax,107    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_lstat
sys_lstat:
	mov	eax,107
	int	byte 80h
	or	eax,eax
	ret