; ****************  file:  system.inc *****************

  struc	stat_struc
.st_dev: resd 1
.st_ino: resd 1
.st_mode: resw 1
.st_nlink: resw 1
.st_uid: resw 1
.st_gid: resw 1
.st_rdev: resd 1
.st_size: resd 1
.st_blksize: resd 1
.st_blocks: resd 1
.st_atime: resd 1
.__unused1: resd 1
.st_mtime: resd 1
.__unused2: resd 1
.st_ctime: resd 1
.__unused3: resd 1
.__unused4: resd 1
.__unused5: resd 1
;  ---  stat_struc_size
  endstruc


; elf file header ----------------------------------------------------------

struc elfheader
.magic		resb	4	;constant id
.e_class	resb	1	;1=elf32
.e_data		resb	1	;1=2's compliment, little endian
.e_ver    	resb	1	;1=current version
.e_os		resb	1	;0=UNIX-System V
.e_abi		resb	1	;always 0
.e_pad		resb	7	;unused
.e_type		resw	1	;1=relocatable 2=executable 3=shared obj 4=core
.e_machine	resw	1	;3=intel 386
.e_version	resd	1	;usually 1
.e_entry	resd	1	;program entry point
.e_phoff	resd	1	;offset into file -> program header table
.e_shoff	resd	1	;offset into file -> section header table
.e_flags	resd	1	;processor specific flags
.e_hsize	resw	1	;size of this header in bytes (usually 34h)
.e_phensize	resw	1	;size of program header tables (usually 20h)
.e_phnum	resw	1	;number of program headers in this file
.e_shentsize	resw	1	;size of section headers (usually 28h)
.e_shnum	resw	1	;number of entries in section header table, or 0 if no table
.e_shstrndx	resw	1	;section header string index
elfheader_struc_size:
endstruc

; elf program header ---------------------------------------------------------
;
; program header tables are optional and describe how to create
; a image (memory load).  Executable programs will have 
; program header tables.  Relocatable files may not have aany and
; objects will have them.
;
; The table is an array of structures.  .e_phnum states how many
; structures are present. Each structure is defined as follows:
;
struc elfprog
.p_type		resd	1 ;0=null 1=loadable 2=dynamic 3=interp 4=note 5=shlib 6=hpdr
.p_offset	resd	1 ;offset from beginning of file to this sections data
.p_virtual	resd	1 ;virtual memory address for segment
.p_addr		resd	1 ;physical memory address for segment
.p_filesz	resd	1 ;segment size (input file image)
.p_memsz	resd	1 ;segment size (when in memory)
.p_flags	resd	1 ;bit 01h=execute 02h=writable 04h=readable
.p_align	resd	1 ;0,1 = no alignment, else mod .p_align ?(ignored)?
elfprog_struc_size:
endstruc

; elf section header ---------------------------------------------------------
;
; the section header tables describe segemnts or data blocks.  These
; can be code,symbol tables, etc.  Each section header can be refered
; to by a index starting from 0.  The elf header contains a index
; for the string section (see .e_shstrndx).
;
struc elfsection
.sh_name	resd	1 ;index into "section strings" for name of this section
                          ;see section .shstrtab (this is not the sysmbol string table)
.sh_type	resd	1 ;0=NULL 1=PROGBITS 2=SYMTAB 3=STRTAB 4=RELA 6=HASH 7=NOTE
                          ;8=NOBITS 9=REL 10=SHLIB 11=DYNSYM
.sh_flags	resd	1 ;bits 01h=writeable 02h=allocate 04h=execute
.sh_addr	resd	1 ;if loadable then address appears here
.sh_offset	resd	1 ;byte offset into file for this sections data, NOBITS is exception
.sh_size	resd	1 ;section size, if NOBITS then file size=0 and memory size here
.sh_link	resd	1 ;index to another section that is connected (hash+strings)
.sh_info	resd	1 ;extra info, may be symbol table size if .symtab with link field
.sh_addralign	resd	1 ;0,1=none else 4,16 are common byte alignments found here
.sh_entsize	resd	1 ;if symtab this is size of entry
elfsection_struc_size:
endstruc

; elf symtab format ----------------------------------------------------------
;
; the symbol table consists of two sections, .symtab and .strtab (strings)
; the .symtab section points into the strings for some types.  Its format
; is:
;
struc symtab
.st_name	resd	1 ;if non-zero then it is index into strtab
.st_value	resd	1 ;symbol value or address
.st_size	resd	1 ;0=unknown, else number of bytes
.st_info	resb	1 ;types: 00=NOTYPE 01=OBJECT 02=FUNC 03=SECTION 04=FILE  -or- below
                          ;bind:  00=LOCAL 10h=GLOBAL 20h=WEAK  -or- with above. 
.st_other	resb	1 ;unused
.st_shndx	resw	1 ;associates symbol with section#, if 0fff1h then no section assoc.
                          ;example: 0=symbol appears in first section, 1=symbol in section 1
elfsymtab_struc_size:
endstruc

;--------------------------------------------------------------------------------
;-- structure used by asmdis_sym.dat file
struc sym
.sym_adr    resd 1	;address, if not in .text.data.bss then dymamic
.sym_typ    resb 1	;type, 50=data 60=code 00=external
.sym_ascii  resb 1      ;asciiz symbol name
endstruc
; 

;-----------------------------------------------------------------------------
;flag image table structure, bit definitions
;
; 0xxx xxxx - data
; 1xxx xxxx - code
;
; x0xx xxxx - start of data/instruction
; x1xx xxxx - data/instruction body
;
; xx00 xxxx - no label here
; xx01 xxxx - symbol table has label for this location
; xx10 xxxx - label hit, type in low 4 bits
; xx11 xxxx - symbol table has label & hits, type in low 4 bits
;
; data start states               data body states
; -----------------               ----------------
; 00xx 0000 - db                  0100 0000 - db,dw,dd,ptr body
; 00xx 0001 - dw
; 00xx 0010 - dd
; 00xx 0011 -              
; 00xx 0100 - string start        0100 0100 - string body
; 00xx 1000 - repeat start        0100 1000 - repeat db body
;
; code start states               code body state
; -----------------               ---------------
; 10xx 0000 - normal code         1100 0000 - non-start body
; 10xx 0001 - jmp target
; 10xx 0010 - call target
;
;
;--------------------------------------------------------------------------------
; output of dis (disassembler) set eax to below -------------------------
; note: if this structure changes, the file results.h also must change.
;
struc Dis
.warn_flg resb 1 ;bit 01h = warning, nasm can not generate this opcode
		 ;bit 02h = warning seg override found?
                 ;bit 04h = warinng seg register operation found
		 ;bit 08h = warning unusual instruction, retn, push ax,
		 ;bit 10h =
		 ;bit 20h =
		 ;bit 40h =

.error_flg resb	1 ;bit  01h = illegal instruction                C P
		  ;bit  02h = instruction size wrong
		  ;bit  04h = unknown program state      
                  ;bit  08h = unexpected prefix

.instruction_typ resb 1 ;bit 00h - normal instruction
                        ;bit 01h - floating point
                        ;bit 02h - conditional jmp
                        ;bit 04h - proteced mode (system) instruction
			;bit 08h - non-conditonal jmp (ret,call,jmp)
                        ;bit 10h -

.operand_typ	resb 1  ;bit 01h - jmp adr at operand
                        ;bit 02h - call adr at operand
                        ;bit 04h - read/write byte adr at operand
                        ;bit 08h - read/write word adr at operand
                        ;bit 10h - read/write dword adr at operand
                        ;bit 20h - probable adr in immediate (const) data

.operand_ 	resd 1  ;address (physical) for jmp,read,write, or operand if actions=0
.inst_len	resd 1	;length of instruction                     S

;
; prefix flags
;
.state_flg:	resb	1 ;0= instruction decoded,return  info.      C P
			  ;40=escape prefix found, continue
			  ;20=seg prefix found, continue
			  ;10=66h opsize found, continue
                          ;08=67h address  size, continue
                          ;04=f2h  repne prefix found
                          ;02=f3h rep prefix found

;the prefix flag is set by non-prefix opcodes and signals
;the end of decode.  It contains legal prefix's for this opcode.

.prefix_flg: resb 1       ;80=found non-prefix opcode, decode done   C P
			  ;40=escape prefix legal for opcode
			  ;20=xx seg prefix legal for opcode
			  ;10=66h opsize prefix legal for opcode
                          ;08=67h address prefix legal for opcode
                          ;04=f3h rep legal for this opcode
                          ;02=f2h  repne legal for this opcode


.inst_end_ resd 1   ;ptr end of data in instruction_asciiz               S
.inst_     resb 140 ;ascii instruction build area                        SP

Dis_struc_size:
endstruc


