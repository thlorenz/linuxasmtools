;--------------------------------------------------------------
;>1 syscall
; sys_request_key - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_request_key                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_request_key:                                  
;              mov  eax,287    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_request_key
sys_request_key:
	mov	eax,287
	int	byte 80h
	or	eax,eax
	ret