;--------------------------------------------------------------
;>1 syscall
; sys_pread64 - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_pread64                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_pread64:                                      
;              mov  eax,180    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_pread64
sys_pread64:
	mov	eax,180
	int	byte 80h
	or	eax,eax
	ret