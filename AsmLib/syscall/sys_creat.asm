;--------------------------------------------------------------
;>1 syscall
; sys_creat - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_creat                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_creat:                                        
;              mov  eax,8      
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_creat
sys_creat:
	mov	eax,8
	int	byte 80h
	or	eax,eax
	ret