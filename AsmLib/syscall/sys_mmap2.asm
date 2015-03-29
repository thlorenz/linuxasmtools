;--------------------------------------------------------------
;>1 syscall
; sys_mmap2 - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_mmap2                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_mmap2:                                        
;              mov  eax,192    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mmap2
sys_mmap2:
	mov	eax,192
	int	byte 80h
	or	eax,eax
	ret