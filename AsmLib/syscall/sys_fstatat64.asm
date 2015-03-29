;--------------------------------------------------------------
;>1 syscall
; sys_fstatat64 - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_fstatat64                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_fstatat64:                                    
;              mov  eax,300    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fstatat64
sys_fstatat64:
	mov	eax,300
	int	byte 80h
	or	eax,eax
	ret