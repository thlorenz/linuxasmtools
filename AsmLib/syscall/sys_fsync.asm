;--------------------------------------------------------------
;>1 syscall
; sys_fsync - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_fsync                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_fsync:                                        
;              mov  eax,118    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fsync
sys_fsync:
	mov	eax,118
	int	byte 80h
	or	eax,eax
	ret