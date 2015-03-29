;--------------------------------------------------------------
;>1 syscall
; sys_oldolduname - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_oldolduname                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_oldolduname:                                  
;              mov  eax,59     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_oldolduname
sys_oldolduname:
	mov	eax,59
	int	byte 80h
	or	eax,eax
	ret