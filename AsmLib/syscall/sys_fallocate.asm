;--------------------------------------------------------------
;>1 syscall
; sys_fallocate - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_fallocate                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_fallocate:                                    
;              mov  eax,324    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fallocate
sys_fallocate:
	mov	eax,324
	int	byte 80h
	or	eax,eax
	ret