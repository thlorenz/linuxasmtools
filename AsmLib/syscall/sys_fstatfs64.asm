;--------------------------------------------------------------
;>1 syscall
; sys_fstatfs64 - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_fstatfs64                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_fstatfs64:                                    
;              mov  eax,269    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fstatfs64
sys_fstatfs64:
	mov	eax,269
	int	byte 80h
	or	eax,eax
	ret