;--------------------------------------------------------------
;>1 syscall
; sys_olduname - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_olduname                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_olduname:                                     
;              mov  eax,109    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_olduname
sys_olduname:
	mov	eax,109
	int	byte 80h
	or	eax,eax
	ret