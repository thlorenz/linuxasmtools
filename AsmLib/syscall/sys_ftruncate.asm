;--------------------------------------------------------------
;>1 syscall
; sys_ftruncate - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_ftruncate                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_ftruncate:                                    
;              mov  eax,93     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ftruncate
sys_ftruncate:
	mov	eax,93
	int	byte 80h
	or	eax,eax
	ret