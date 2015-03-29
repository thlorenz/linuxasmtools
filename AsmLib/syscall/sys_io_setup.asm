;--------------------------------------------------------------
;>1 syscall
; sys_io_setup - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_io_setup                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_io_setup:                                     
;              mov  eax,245    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_io_setup
sys_io_setup:
	mov	eax,245
	int	byte 80h
	or	eax,eax
	ret