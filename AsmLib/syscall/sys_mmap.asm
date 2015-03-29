;--------------------------------------------------------------
;>1 syscall
; sys_mmap - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_mmap                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_mmap:                                         
;              mov  eax,90     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mmap
sys_mmap:
	mov	eax,90
	int	byte 80h
	or	eax,eax
	ret