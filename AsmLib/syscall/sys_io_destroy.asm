;--------------------------------------------------------------
;>1 syscall
; sys_io_destroy - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_io_destroy                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_io_destroy:                                   
;              mov  eax,246    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_io_destroy
sys_io_destroy:
	mov	eax,246
	int	byte 80h
	or	eax,eax
	ret