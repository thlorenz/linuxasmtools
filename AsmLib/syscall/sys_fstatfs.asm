;--------------------------------------------------------------
;>1 syscall
; sys_fstatfs - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_fstatfs                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_fstatfs:                                      
;              mov  eax,100    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fstatfs
sys_fstatfs:
	mov	eax,100
	int	byte 80h
	or	eax,eax
	ret