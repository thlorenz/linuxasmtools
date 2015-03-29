;--------------------------------------------------------------
;>1 syscall
; sys_fadvise64_64 - kernel function                        
;
;    INPUTS 
;     see AsmRef function -> sys_fadvise64_64                                    
;
;    Note: functon call consists of four instructions
;          
;          sys_fadvise64_64:                                 
;              mov  eax,272    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fadvise64_64
sys_fadvise64_64:
	mov	eax,272
	int	byte 80h
	or	eax,eax
	ret