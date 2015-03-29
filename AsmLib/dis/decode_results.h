;
; decode_results.h - current disassembly state and information for caller
;
align 16
;-----------------------------------------------------------------------
;                                                  codes C-cleared by dis
;                                                        S-set by dis
;                                                        P-set by process
dis_block:	 ;block of data returned to caller 
warn_flag db   0 ;bit 01h = warning, nasm can not generate this opcode
		 ;bit 02h = warning seg override found?
                 ;bit 04h = warinng seg register operation found
		 ;bit 08h = warning unusual instruction, retn, push ax,
		 ;bit 10h =
		 ;bit 20h =
		 ;bit 40h =

error_flag db  	0 ;bit  01h = illegal instruction                C P
		  ;bit  02h = instruction size wrong
		  ;bit  04h = unknown program state      
                  ;bit  08h = unexpected prefix

instruction_type db   0 ;bit 00h - normal instruction
                        ;bit 01h - floating point
                        ;bit 02h - conditional jmp
                        ;bit 04h - proteced mode (system) instruction
			;bit 08h - non-conditonal jmp (ret,call,jmp)
                        ;bit 10h -

operand_type	db   0  ;bit 01h - jmp adr at operand
                        ;bit 02h - call adr at operand
                        ;bit 04h - read/write byte adr at operand
                        ;bit 08h - read/write word adr at operand
                        ;bit 10h - read/write dword adr at operand
                        ;bit 20h - probable adr in immediate (const) data

operand 	dd   0  ;address (physical) for jmp,read,write, or operand if actions=0
inst_length	dd   0	;length of instruction                     S

;
; prefix flags
;
state_flag:	db  	0 ;0= instruction decoded,return  info.      C P
			  ;40=escape prefix found, continue
			  ;20=seg prefix found, continue
			  ;10=66h opsize found, continue
                          ;08=67h address  size, continue
                          ;04=f2h  repne prefix found
                          ;02=f3h rep prefix found

;the prefix flag is set by non-prefix opcodes and signals
;the end of decode.  It contains legal prefix's for this opcode.

prefix_flag: db   0       ;80=found non-prefix opcode, decode done   C P
			  ;40=escape prefix legal for opcode
			  ;20=xx seg prefix legal for opcode
			  ;10=66h opsize prefix legal for opcode
                          ;08=67h address prefix legal for opcode
                          ;04=f3h rep legal for this opcode
                          ;02=f2h  repne legal for this opcode


inst_end dd   0   ;ptr end of data in instruction_asciiz               S
inst     times 140 db 0 ;ascii instruction build area                        SP

