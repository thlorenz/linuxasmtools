;--------------------------------------------------------------
;>1 syscall
; sys_set_tid_address - kernel function                     
;
;    INPUTS 
;     see AsmRef function -> sys_set_tid_address                                 
;
;    Note: functon call consists of four instructions
;          
;          sys_set_tid_address:                              
;              mov  eax,258    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_set_tid_address
sys_set_tid_address:
	mov	eax,258
	int	byte 80h
	or	eax,eax
	ret