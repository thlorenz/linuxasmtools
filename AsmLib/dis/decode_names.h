  [section .data]
;
; opcode names and other strings
;
names:
	db 0	;dummy entry to make first offset=1 not zero
;
;the first entries are frequently used names that can be accessed
;by a byte index

_dec	db "dec",0
_inc	db "inc",0
_mov	db "mov",0
_pop	db "pop",0
_push	db "push",0
_xchg	db "xchg",0
_rep	db "rep",0
_repne	db "repne",0
_lock	db "lock",0

;the following names are accessed by a word index

_aaa	db "aaa",0
_aad	db "aad",0
_aam	db "aam",0
_aas	db "aas",0
_adc	db "adc",0
_add	db "add",0
;_addpd	db "addpd",0
;_addps	db "addps",0
;_addsd	db "addsd",0
_and	db "and",0
;_andnpd	db "andnpd",0
;_andnps	db "andnps",0
;_andpd	db "andpd",0
;_andps	db "andps",0
;_arpl	db "arpl",0
_bound	db "bound",0
_bsf	db "bsf",0
_bsr	db "bsr",0
_bswap	db "bswap",0
_bt	db "bt",0
_btc	db "btc",0
_btr	db "btr",0
_bts	db "bts",0
_call	db "call",0
_cbw	db "cbw",0
_cdq	db "cdq",0
_cdqe	db "cdqe",0
_clc	db "clc",0
_cld	db "cld",0
;_clflush	db "clflush",0
_cli	db "cli",0
_clts	db "clts",0
_cmc	db "cmc",0
_cmova	db "cmova",0
_cmovna db "cmovna",0
_cmovo	db "cmovo",0
_cmovno	db "cmovno",0
_cmovc	db "cmovc",0
_cmovnc	db "cmovnc",0
_cmove	db "cmove",0
_cmovne	db "cmovne",0
_cmovba	db "cmovba",0
_cmovnba	db "cmovnba",0
_cmovs	db "cmovs",0
_cmovns	db "cmovns",0
_cmovp	db "cmovp",0
_cmovnp	db "cmovnp",0
_cmovl	db "cmovl",0
_cmovnl	db "cmovnl",0
_cmovle	db "cmovle",0
_cmovg	db "cmovg",0
_cmp	db "cmp",0
_cmppd	db "cmppd",0
_cmpps	db "cmpps",0
_cmps	db "cmps",0
_cmpsb	db "cmpsb",0
_cmpsd	db "cmpsd",0
_cmpsq	db "cmpsq",0
_cmpxchg	db "cmpxchg",0
;_cmpxchg8b	db "cmpxchg8b",0
;_comisd	db "comisd",0
;_comiss	db "comiss",0
_cpuid	db "cpuid",0
_cqd	db "cqd",0
_cqo	db "cqo",0
;_cvtdq2pd	db "cvtdq2pd",0
;_cvtdq2ps	db "cvtdq2ps",0
;_cvtpd2dq	db "cvtpd2dq",0
;_cvtpd2pi	db "cvtpd2pi",0
;_cvtpd2ps	db "cvtpd2ps",0
;_cvtpi2pd	db "cvtpi2pd",0
;_cvtpi2ps	db "cvtpi2ps",0
;_cvtps2dq	db "cvtps2dq",0
;_cvtps2pd	db "cvtps2pd",0
;_cvtps2pi	db "cvtps2pi",0
;_cvtsd2si	db "cvtsd2si",0
;_cvtsd2ss	db "cvtsd2ss",0
;_cvtsi2sd	db "cvtsi2sd",0
;_cvtsi2ss	db "cvtsi2ss",0
;_cvtss2sd	db "cvtss2sd",0
;_cvtss2si	db "cvtss2si",0
;_cvttpd2dq	db "cvttpd2dq",0
;_cvttpd2pi	db "cvttpd2pi",0
;_cvttps2dq	db "cvttps2dq",0
;_cvttps2pi	db "cvttps2pi",0
;_cvttsd2si	db "cvttsd2si",0
;_cvttsi2sd	db "cvttsi2sd",0
;_cvttsi2ss	db "cvttsi2ss",0
;_cvttss2si	db "cvttss2si",0
_cwd	db "cwd",0
_cwde	db "cwde",0
_daa	db "daa",0
_das	db "das",0
_div	db "div",0
;_divpd	db "divpd",0
;_divps	db "divps",0
;_divsd	db "divsd",0
;_emms	db "emms",0
_enter	db "enter",0
_esc	db "esc",0
_f2xm1	db "f2xm1",0
_fsxm1	db "fsxm1",0
_fabs	db "fabs",0
_fadd	db "fadd",0
_faddp	db "faddp",0
_fbld	db "fbld",0
_fbstp	db "fbstp",0
_fchs	db "fchs",0
_fclex	db "fclex",0
_fcmovb	db "fcmovb",0
_fcmovbe	db "fcmovbe",0
_fcmove	db "fcmove",0
_fcmovnb	db "fcmovnb",0
_fcmovnbe	db "fcmovnbe",0
_fcmovne	db "fcmovne",0
_fcmovnu	db "fcmovnu",0
_fcmovu	db "fcmovu",0
_fcom	db "fcom",0
_fcomi	db "fcomi",0
_fcomp	db "fcomp",0
_fcomip	db "fcomip",0
_fcompp	db "fcompp",0
_fcos	db "fcos",0
_fdecstp	db "fdecstp",0
_fdiv	db "fdiv",0
_fdivp	db "fdivp",0
_fdivr	db "fdivr",0
_fdivrp	db "fdivrp",0
_femms	db "femms",0
_ffree	db "ffree",0
_fiadd	db "fiadd",0
_ficom	db "ficom",0
_ficomp	db "ficomp",0
_fidiv	db "fidiv",0
_fidivr	db "fidivr",0
_fidw	db "fidw",0
_fidwr	db "fidwr",0
_fild	db "fild",0
_fimul	db "fimul",0
_fincstp	db "fincstp",0
_finit	db "finit",0
_fist	db "fist",0
_fistp	db "fistp",0
_fisub	db "fisub",0
_fisubr	db "fisubr",0
_fld	db "fld",0
_fld1	db "fld1",0
_fldcw	db "fldcw",0
_fldenv	db "fldenv",0
_fldl2e	db "fldl2e",0
_fldl2t	db "fldl2t",0
_fldlg2	db "fldlg2",0
_fldln2	db "fldln2",0
_fldpi	db "fldpi",0
_fldx	db "fldx",0
_fldz	db "fldz",0
_fmul	db "fmul",0
_fmulp	db "fmulp",0
_fnclex	db "fnclex",0
_fncstp	db "fncstp",0
_fninit	db "fninit",0
_fnop	db "fnop",0
_fnsave	db "fnsave",0
_fnstcw	db "fnstcw",0
_fnstenv	db "fnstenv",0
_fnstsw	db "fnstsw",0
_fpatan	db "fpatan",0
_fprem	db "fprem",0
_fprem1	db "fprem1",0
_fptan	db "fptan",0
_fpxtract	db "fpxtract",0
_frndint	db "frndint",0
_frstor	db "frstor",0
_fsave	db "fsave",0
_fscale	db "fscale",0
_fsin	db "fsin",0
_fsincos	db "fsincos",0
_fsqrt	db "fsqrt",0
_fst	db "fst",0
_fstcw	db "fstcw",0
_fstenv	db "fstenv",0
_fstp	db "fstp",0
_fstsw	db "fstsw",0
_fsub	db "fsub",0
_fsubp	db "fsubp",0
_fsubr	db "fsubr",0
_fsubrp	db "fsubrp",0
_ftst	db "ftst",0
_fucom	db "fucom",0
_fucomi	db "fucomi",0
_fucomip	db "fucomip",0
_fucomp	db "fucomp",0
_fucompp	db "fucompp",0
_fwait	db "fwait",0
_fxam	db "fxam",0
_fxch	db "fxch",0
_fxrstor	db "fxrstor",0
_fxsave	db "fxsave",0
_fxtract	db "fxtract",0
_fyl2x	db "fyl2x",0
_fyl2xp1	db "fyl2xp1",0
_hlt	db "hlt",0
_idiv	db "idiv",0
_imul	db "imul",0
_in	db "in",0
_ins	db "ins",0
_insb	db "insb",0
_insd	db "insd",0
_int	db "int",0
_int3	db "int3",0
_into	db "into",0
_invd	db "invd",0
;_invlpg	db "invlpg",0
_iret	db "iret",0
;_iretd	db "iretd",0
;_iretq	db "iretq",0
;_jcxz	db "jcxz",0
_jecxz	db "jecxz",0
_jmp	db "jmp",0
;_jrcxz	db "jrcxz",0
_jo	db "jo",0
_jno	db "jno",0
_jc	db "jc",0
_jnc	db "jnc",0
_je	db "je",0
_jne	db "jne",0
_jna	db "jna",0
_ja	db "ja",0
_js	db "js",0
_jns	db "jns",0
_jp	db "jp",0
_jnp	db "jnp",0
_jl	db "jl",0
_jnl	db "jnl",0
_jle	db "jle",0
_jg	db "jg",0
_lahf	db "lahf",0
_lar	db "lar",0
;_ldmxcsr	db "ldmxcsr",0
_lds	db "lds",0
_lea	db "lea",0
_leave	db "leave",0
_les	db "les",0
;_lfence	db "lfence",0
_lfs	db "lfs",0
_lgdt	db "lgdt",0
_lgs	db "lgs",0
_lidt	db "lidt",0
_lldt	db "lldt",0
_lmsw	db "lmsw",0
;_loadall db "loadall",0
_lods	db "lods",0
_lodsb	db "lodsb",0
_lodsd	db "lodsd",0
_lodsq	db "lodsq",0
_loop	db "loop",0
_loope	db "loope",0
_loopn	db "loopn",0
_loopne	db "loopne",0
_loopnz	db "loopnz",0
_loopz	db "loopz",0
_lsl	db "lsl",0
_lss	db "lss",0
_ltr	db "ltr",0
;_maskmovdqu	db "maskmovdqu",0
;_maskmovq	db "maskmovq",0
;_maxpd	db "maxpd",0
;_maxps	db "maxps",0
;_maxsd	db "maxsd",0
;_maxss	db "maxss",0
;_mfence	db "mfence",0
;_minpd	db "minpd",0
;_minps	db "minps",0
;_minsd	db "minsd",0
;_minss	db "minss",0
;_movapd	db "movapd",0
;_movaps	db "movaps",0
;_movd	db "movd",0
;_movdq2q	db "movdq2q",0
;_movdqa	db "movdqa",0
;_movdqu	db "movdqu",0
;_movhlps	db "movhlps",0
;_movhpd	db "movhpd",0
;_movhps	db "movhps",0
;_movlhps	db "movlhps",0
;_movlpd	db "movlpd",0
;_movlps	db "movlps",0
;_movmskpd	db "movmskpd",0
;_movmskps	db "movmskps",0
;_movnig	db "movnig",0
;_movntdq	db "movntdq",0
;_movnti	db "movnti",0
;_movntpd	db "movntpd",0
;_movntps	db "movntps",0
;_movntq	db "movntq",0
;_movq	db "movq",0
;_movq2dq	db "movq2dq",0
;_movqa	db "movqa",0
_movs	db "movs",0
_movsb	db "movsb",0
_movsd	db "movsd",0
;_movsq	db "movsq",0
_movsx	db "movsx",0
;_movsxd	db "movsxd",0
;_movupd	db "movupd",0
;_movups	db "movups",0
_movzx	db "movzx",0
_mul	db "mul",0
;_mulpd	db "mulpd",0
;_mulps	db "mulps",0
;_mulsd	db "mulsd",0
_neg	db "neg",0
_nop	db "nop",0
_not	db "not",0
_or	db "or",0
;_orpd	db "orpd",0
;_orps	db "orps",0
_out	db "out",0
_outs	db "outs",0
_outsb	db "outsb",0
_outsd	db "outsd",0
;_packssdw	db "packssdw",0
;_packsswb	db "packsswb",0
;_packusdw	db "packusdw",0
;_packuswb	db "packuswb",0
;_paddb	db "paddb",0
;_paddd	db "paddd",0
;_paddq	db "paddq",0
;_paddsb	db "paddsb",0
;_paddsw	db "paddsw",0
;_paddusb	db "paddusb",0
;_paddusw	db "paddusw",0
;_paddw	db "paddw",0
;_pand	db "pand",0
;_pandn	db "pandn",0
;_pavgb	db "pavgb",0
;_pavgusb	db "pavgusb",0
;_pavgw	db "pavgw",0
;_pcmpeqb	db "pcmpeqb",0
;_pcmpeqd	db "pcmpeqd",0
;_pcmpeqw	db "pcmpeqw",0
;_pcmpgtb	db "pcmpgtb",0
;_pcmpgtd	db "pcmpgtd",0
;_pcmpgtw	db "pcmpgtw",0
;_pextrw	db "pextrw",0
;_pf2id	db "pf2id",0
;_pf2iw	db "pf2iw",0
;_pfacc	db "pfacc",0
;_pfadd	db "pfadd",0
;_pfcmpeq	db "pfcmpeq",0
;_pfcmpge	db "pfcmpge",0
;_pfcmpgt	db "pfcmpgt",0
;_pfmax	db "pfmax",0
;_pfmin	db "pfmin",0
;_pfmul	db "pfmul",0
;_pfnacc	db "pfnacc",0
;_pfpnacc	db "pfpnacc",0
;_pfrcp	db "pfrcp",0
;_pfrcpit1	db "pfrcpit1",0
;_pfrcpit2	db "pfrcpit2",0
;_pfrsqit1	db "pfrsqit1",0
;_pfrsqrt	db "pfrsqrt",0
;_pfsub	db "pfsub",0
;_pfsubr	db "pfsubr",0
;_pi2fd	db "pi2fd",0
;_pi2fw	db "pi2fw",0
;_pinsrw	db "pinsrw",0
;_pmaddwd	db "pmaddwd",0
;_pmaxsw	db "pmaxsw",0
;_pmaxub	db "pmaxub",0
;_pminsw	db "pminsw",0
;_pminub	db "pminub",0
;_pmovmskb	db "pmovmskb",0
;_pmulhrw	db "pmulhrw",0
;_pmulhuw	db "pmulhuw",0
;_pmulhw	db "pmulhw",0
;_pmullw	db "pmullw",0
;_pmuludq	db "pmuludq",0
_popa	db "popa",0
;_popad	db "popad",0
_popf	db "popf",0
;_popfd	db "popfd",0
;_popfq	db "popfq",0
;_por	db "por",0
;_prefetch	db "prefetch",0
;_psadbw	db "psadbw",0
;_pshufd	db "pshufd",0
;_pshufhw	db "pshufhw",0
;_pshuflw	db "pshuflw",0
;_pshufw	db "pshufw",0
;_pslld	db "pslld",0
;_pslldq	db "pslldq",0
;_psllq	db "psllq",0
;_psllw	db "psllw",0
;_psrad	db "psrad",0
;_psraw	db "psraw",0
;_psraq	db "psraq",0
;_psrld	db "psrld",0
;_psrldq	db "psrldq",0
;_psrlq	db "psrlq",0
;_psrlw	db "psrlw",0
;_psubb	db "psubb",0
;_psubd	db "psubd",0
;_psubq	db "psubq",0
;_psubsb	db "psubsb",0
;_psubsw	db "psubsw",0
;_psubusb	db "psubusb",0
;_psubusw	db "psubusw",0
;_psubw	db "psubw",0
;_pswapd	db "pswapd",0
;_punpckhbw	db "punpckhbw",0
;_punpckhdq	db "punpckhdq",0
;_punpckhqdq	db "punpckhqdq",0
;_punpckhwd	db "punpckhwd",0
;_punpcklbw	db "punpcklbw",0
;_punpckldq	db "punpckldq",0
;_punpcklqdq	db "punpcklqdq",0
;_punpcklwd	db "punpcklwd",0
_pusha	db "pusha",0
;_pushad	db "pushad",0
_pushf	db "pushf",0
;_pushfd	db "pushfd",0
;_pushfq	db "pushfq",0
;_pxor	db "pxor",0
_rcl	db "rcl",0
;_rcpps	db "rcpps",0
_rcr	db "rcr",0
;_rdivisr	db "rdivisr",0
;_rdmsr	db "rdmsr",0
;_rdpmc	db "rdpmc",0
;_rdtsc	db "rdtsc",0
_ret	db "ret",0
_retf	db "retf",0
_rol	db "rol",0
_ror	db "ror",0
_rsm	db "rsm",0
;_rsqrtps	db "rsqrtps",0
_sahf	db "sahf",0
_sal	db "sal",0
_salc	db "salc",0
_sar	db "sar",0
_sbb	db "sbb",0
_scas	db "scas",0
_scasb	db "scasb",0
_scasd	db "scasd",0
;_scasq	db "scasq",0
_seto	db "seto",0
_setno	db "setno",0
_setc	db "setc",0
_setnc	db "setnc",0
_sete	db "sete",0
_setne	db "setne",0
_seta	db "seta",0
_setna	db "setna",0
_setnba	db "setnba",0
_sets	db "sets",0
_setns	db "setns",0
_setp	db "setp",0
_setnp	db "setnp",0
_setl	db "setl",0
_setnl	db "setnl",0
_setng	db "setng",0
_setg	db "setg",0
;_sfence	db "sfence",0
;_sgdt	db "sgdt",0
_shl	db "shl",0
_shld	db "shld",0
_shr	db "shr",0
_shrd	db "shrd",0
;_shufpd	db "shufpd",0
;_shufps	db "shufps",0
;_sidt	db "sidt",0
;_sldt	db "sldt",0
_smsw	db "smsw",0
;_sqrtpd	db "sqrtpd",0
;_sqrtps	db "sqrtps",0
;_sqrtsd	db "sqrtsd",0
_stc	db "stc",0
_std	db "std",0
_sti	db "sti",0
;_stmxcsr	db "stmxcsr",0
_stos	db "stos",0
_stosb	db "stosb",0
_stosd	db "stosd",0
_str	db "str",0
_sub	db "sub",0
;_subpd	db "subpd",0
;_subps	db "subps",0
;_subsd	db "subsd",0
;_swapgs	db "swapgs",0
;_syscall	db "syscall",0
;_sysenter	db "sysenter",0
;_sysexit	db "sysexit",0
;_sysret	db "sysret",0
_test	db "test",0
;_ucomisd	db "ucomisd",0
;_ucomiss	db "ucomiss",0
;_ud2	db "ud2",0
;_unpckhpd	db "unpckhpd",0
;_unpckhps	db "unpckhps",0
;_unpcklpd	db "unpcklpd",0
;_unpcklps	db "unpcklps",0
;_verr	db "verr",0
;_verw	db "verw",0
_wait	db "wait",0
;_wbinvd	db "wbinvd",0
;_wrmsr	db "wrmsr",0
_xadd	db "xadd",0
_xlat	db "xlat",0
_xlatb	db "xlatb",0
_xor	db "xor",0
;_xorpd	db "xorpd",0
;_xorps	db "xorps",0

_byte  db "byte",0
_word  db "word",0
_dword db "dword",0
_short db "short",0
_opsz	db "opsz",0
_adsz	db "adsz",0

registers:
_eax  db	'eax',0		;0
_ecx  db	'ecx',0		;1
_edx  db	'edx',0		;2
_ebx  db	'ebx',0		;3
_esp  db	'esp',0		;4
_ebp  db	'ebp',0		;5
_esi  db	'esi',0		;6
_edi  db	'edi',0		;7
regs_mode16:
_ax  db	'ax',0		;8 -0
_cx  db	'cx',0		;9 -1
_dx  db	'dx',0		;10-2
_bx  db	'bx',0		;11-3
_sp  db	'sp',0		;12-4
_bp  db	'bp',0		;13-5
_si  db	'si',0		;14-6
_di  db	'di',0		;15-7
regs_byte:
_al  db	'al',0		;16-0
_cl  db	'cl',0		;17-1
_dl  db	'dl',0		;18-2
_bl  db	'bl',0		;19-3
_ah  db	'ah',0		;20-4
_ch  db	'ch',0		;21-5
_dh  db	'dh',0		;22-6
_bh  db	'bh',0		;23-7
regs_seg:
_es  db	'es',0		;24-0
_cs  db	'cs',0		;25-1
_ss  db	'ss',0		;26-2
_ds  db	'ds',0		;27-3
_fs  db	'fs',0		;28-4
_gs  db	'gs',0		;29-5

;----------------------------------------
__aaa	equ	_aaa - names
__aad	equ	_aad - names
__aam	equ	_aam - names
__aas	equ	_aas - names
__adc	equ	_adc - names
__add	equ	_add - names
;__addpd	equ	_addpd - names
;__addps	equ	_addps - names
;__addsd	equ	_addsd - names
__and	equ	_and - names
;__andnpd	equ	_andnpd - names
;__andnps	equ	_andnps - names
;__andpd	equ	_andpd - names
;__andps	equ	_andps - names
;__arpl	equ	_arpl - names
__bound	equ	_bound - names
__bsf	equ	_bsf - names
__bsr	equ	_bsr - names
__bswap	equ	_bswap - names
__bt	equ	_bt - names
__btc	equ	_btc - names
__btr	equ	_btr - names
__bts	equ	_bts - names
__call	equ	_call - names
__cbw	equ	_cbw - names
__cdq	equ	_cdq - names
__cdqe	equ	_cdqe - names
__clc	equ	_clc - names
__cld	equ	_cld - names
;__clflush	equ	_clflush - names
__cli	equ	_cli - names
__clts	equ	_clts - names
__cmc	equ	_cmc - names
__cmovo	equ	_cmovo - names
__cmovno	equ	_cmovno - names
__cmovc	equ	_cmovc - names
__cmovnc	equ	_cmovnc - names
__cmove	equ	_cmove - names
__cmovne	equ	_cmovne - names
__cmovba	equ	_cmovba - names
__cmova		equ	_cmova - names
__cmovna	equ	_cmovna - names
__cmovs	equ	_cmovs - names
__cmovns	equ	_cmovns - names
__cmovp	equ	_cmovp - names
__cmovnp	equ	_cmovnp - names
__cmovl	equ	_cmovl - names
__cmovnl	equ	_cmovnl - names
__cmovle	equ	_cmovle - names
__cmovg	equ	_cmovg - names
__cmp	equ	_cmp - names
__cmppd	equ	_cmppd - names
__cmpps	equ	_cmpps - names
__cmps	equ	_cmps - names
__cmpsb	equ	_cmpsb - names
__cmpsd	equ	_cmpsd - names
__cmpsq	equ	_cmpsq - names
__cmpxchg	equ	_cmpxchg - names
;__cmpxchg8b	equ	_cmpxchg8b - names
;__comisd	equ	_comisd - names
;__comiss	equ	_comiss - names
__cpuid	equ	_cpuid - names
__cqd	equ	_cqd - names
__cqo	equ	_cqo - names
;__cvtdq2pd	equ	_cvtdq2pd - names
;__cvtdq2ps	equ	_cvtdq2ps - names
;__cvtpd2dq	equ	_cvtpd2dq - names
;__cvtpd2pi	equ	_cvtpd2pi - names
;__cvtpd2ps	equ	_cvtpd2ps - names
;__cvtpi2pd	equ	_cvtpi2pd - names
;__cvtpi2ps	equ	_cvtpi2ps - names
;__cvtps2dq	equ	_cvtps2dq - names
;__cvtps2pd	equ	_cvtps2pd - names
;__cvtps2pi	equ	_cvtps2pi - names
;__cvtsd2si	equ	_cvtsd2si - names
;__cvtsd2ss	equ	_cvtsd2ss - names
;__cvtsi2sd	equ	_cvtsi2sd - names
;__cvtsi2ss	equ	_cvtsi2ss - names
;__cvtss2sd	equ	_cvtss2sd - names
;__cvtss2si	equ	_cvtss2si - names
;__cvttpd2dq	equ	_cvttpd2dq - names
;__cvttpd2pi	equ	_cvttpd2pi - names
;__cvttps2dq	equ	_cvttps2dq - names
;__cvttps2pi	equ	_cvttps2pi - names
;__cvttsd2si	equ	_cvttsd2si - names
;__cvttsi2sd	equ	_cvttsi2sd - names
;__cvttsi2ss	equ	_cvttsi2ss - names
;__cvttss2si	equ	_cvttss2si - names
__cwd	equ	_cwd - names
__cwde	equ	_cwde - names
__daa	equ	_daa - names
__das	equ	_das - names
__dec	equ	_dec - names
__div	equ	_div - names
;__divpd	equ	_divpd - names
;__divps	equ	_divps - names
;__divsd	equ	_divsd - names
;__emms	equ	_emms - names
__enter	equ	_enter - names
__esc	equ	_esc - names
__f2xm1	equ	_f2xm1 - names
__fsxm1	equ	_fsxm1 - names
__fabs	equ	_fabs - names
__fadd	equ	_fadd - names
__faddp	equ	_faddp - names
__fbld	equ	_fbld - names
__fbstp	equ	_fbstp - names
__fchs	equ	_fchs - names
__fclex	equ	_fclex - names
__fcmovb	equ	_fcmovb - names
__fcmovbe	equ	_fcmovbe - names
__fcmove	equ	_fcmove - names
__fcmovnb	equ	_fcmovnb - names
__fcmovnbe	equ	_fcmovnbe - names
__fcmovne	equ	_fcmovne - names
__fcmovnu	equ	_fcmovnu - names
__fcmovu	equ	_fcmovu - names
__fcom	equ	_fcom - names
__fcomi	equ	_fcomi - names
__fcomp	equ	_fcomp - names
__fcomip	equ	_fcomip - names
__fcompp	equ	_fcompp - names
__fcos	equ	_fcos - names
__fdecstp	equ	_fdecstp - names
__fdiv	equ	_fdiv - names
__fdivp	equ	_fdivp - names
__fdivr	equ	_fdivr - names
__fdivrp	equ	_fdivrp - names
__femms	equ	_femms - names
__ffree	equ	_ffree - names
__fiadd	equ	_fiadd - names
__ficom	equ	_ficom - names
__ficomp	equ	_ficomp - names
__fidiv	equ	_fidiv - names
__fidivr	equ	_fidivr - names
__fidw	equ	_fidw - names
__fidwr	equ	_fidwr - names
__fild	equ	_fild - names
__fimul	equ	_fimul - names
__fincstp	equ	_fincstp - names
__finit	equ	_finit - names
__fist	equ	_fist - names
__fistp	equ	_fistp - names
__fisub	equ	_fisub - names
__fisubr	equ	_fisubr - names
__fld	equ	_fld - names
__fld1	equ	_fld1 - names
__fldcw	equ	_fldcw - names
__fldenv	equ	_fldenv - names
__fldl2e	equ	_fldl2e - names
__fldl2t	equ	_fldl2t - names
__fldlg2	equ	_fldlg2 - names
__fldln2	equ	_fldln2 - names
__fldpi	equ	_fldpi - names
__fldx	equ	_fldx - names
__fldz	equ	_fldz - names
__fmul	equ	_fmul - names
__fmulp	equ	_fmulp - names
__fnclex	equ	_fnclex - names
__fncstp	equ	_fncstp - names
__fninit	equ	_fninit - names
__fnop	equ	_fnop - names
__fnsave	equ	_fnsave - names
__fnstcw	equ	_fnstcw - names
__fnstenv	equ	_fnstenv - names
__fnstsw	equ	_fnstsw - names
__fpatan	equ	_fpatan - names
__fprem	equ	_fprem - names
__fprem1	equ	_fprem1 - names
__fptan	equ	_fptan - names
__fpxtract	equ	_fpxtract - names
__frndint	equ	_frndint - names
__frstor	equ	_frstor - names
__fsave	equ	_fsave - names
__fscale	equ	_fscale - names
__fsin	equ	_fsin - names
__fsincos	equ	_fsincos - names
__fsqrt	equ	_fsqrt - names
__fst	equ	_fst - names
__fstcw	equ	_fstcw - names
__fstenv	equ	_fstenv - names
__fstp	equ	_fstp - names
__fstsw	equ	_fstsw - names
__fsub	equ	_fsub - names
__fsubp	equ	_fsubp - names
__fsubr	equ	_fsubr - names
__fsubrp	equ	_fsubrp - names
__ftst	equ	_ftst - names
__fucom	equ	_fucom - names
__fucomi	equ	_fucomi - names
__fucomip	equ	_fucomip - names
__fucomp	equ	_fucomp - names
__fucompp	equ	_fucompp - names
__fwait	equ	_fwait - names
__fxam	equ	_fxam - names
__fxch	equ	_fxch - names
__fxrstor	equ	_fxrstor - names
__fxsave	equ	_fxsave - names
__fxtract	equ	_fxtract - names
__fyl2x	equ	_fyl2x - names
__fyl2xp1	equ	_fyl2xp1 - names
__hlt	equ	_hlt - names
__idiv	equ	_idiv - names
__imul	equ	_imul - names
__in	equ	_in - names
__inc	equ	_inc - names
__ins	equ	_ins - names
__insb	equ	_insb - names
__insd	equ	_insd - names
__int	equ	_int - names
__int3	equ	_int3 - names
__into	equ	_into - names
__invd	equ	_invd - names
;__invlpg	equ	_invlpg - names
__iret	equ	_iret - names
;__iretd	equ	_iretd - names
;__iretq	equ	_iretq - names
;__jcxz	equ	_jcxz - names
__jecxz	equ	_jecxz - names
__jmp	equ	_jmp - names
;__jrcxz	equ	_jrcxz - names
__jo	equ	_jo - names
__jno	equ	_jno - names
__jc	equ	_jc - names
__jnc	equ	_jnc - names
__je	equ	_je - names
__jne	equ	_jne - names
__jna	equ	_jna - names
__ja	equ	_ja - names
__js	equ	_js - names
__jns	equ	_jns - names
__jp	equ	_jp - names
__jnp	equ	_jnp - names
__jl	equ	_jl - names
__jnl	equ	_jnl - names
__jle	equ	_jle - names
__jg	equ	_jg - names
__lahf	equ	_lahf - names
__lar	equ	_lar - names
;__ldmxcsr	equ	_ldmxcsr - names
__lds	equ	_lds - names
__lea	equ	_lea - names
__leave	equ	_leave - names
__les	equ	_les - names
;__lfence	equ	_lfence - names
__lfs	equ	_lfs - names
__lgdt	equ	_lgdt - names
__lgs	equ	_lgs - names
__lidt	equ	_lidt - names
__lldt	equ	_lldt - names
__lmsw	equ	_lmsw - names
;__loadall equ	_loadall - names
__lock	equ	_lock - names
__lods	equ	_lods - names
__lodsb	equ	_lodsb - names
__lodsd	equ	_lodsd - names
__lodsq	equ	_lodsq - names
__loop	equ	_loop - names
__loope	equ	_loope - names
__loopn	equ	_loopn - names
__loopne	equ	_loopne - names
__loopnz	equ	_loopnz - names
__loopz	equ	_loopz - names
__lsl	equ	_lsl - names
__lss	equ	_lss - names
__ltr	equ	_ltr - names
;__maskmovdqu	equ	_maskmovdqu - names
;__maskmovq	equ	_maskmovq - names
;__maxpd	equ	_maxpd - names
;__maxps	equ	_maxps - names
;__maxsd	equ	_maxsd - names
;__maxss	equ	_maxss - names
;__mfence	equ	_mfence - names
;__minpd	equ	_minpd - names
;__minps	equ	_minps - names
;__minsd	equ	_minsd - names
;__minss	equ	_minss - names
__mov	equ	_mov - names
;__movapd	equ	_movapd - names
;__movaps	equ	_movaps - names
;__movd	equ	_movd - names
;__movdq2q	equ	_movdq2q - names
;__movdqa	equ	_movdqa - names
;__movdqu	equ	_movdqu - names
;__movhlps	equ	_movhlps - names
;__movhpd	equ	_movhpd - names
;__movhps	equ	_movhps - names
;__movlhps	equ	_movlhps - names
;__movlpd	equ	_movlpd - names
;__movlps	equ	_movlps - names
;__movmskpd	equ	_movmskpd - names
;__movmskps	equ	_movmskps - names
;__movnig	equ	_movnig - names
;__movntdq	equ	_movntdq - names
;__movnti	equ	_movnti - names
;__movntpd	equ	_movntpd - names
;__movntps	equ	_movntps - names
;__movntq	equ	_movntq - names
;__movq	equ	_movq - names
;__movq2dq	equ	_movq2dq - names
;__movqa	equ	_movqa - names
__movs	equ	_movs - names
__movsb	equ	_movsb - names
__movsd	equ	_movsd - names
;__movsq	equ	_movsq - names
__movsx	equ	_movsx - names
;__movsxd	equ	_movsxd - names
;__movupd	equ	_movupd - names
;__movups	equ	_movups - names
__movzx	equ	_movzx - names
__mul	equ	_mul - names
;__mulpd	equ	_mulpd - names
;__mulps	equ	_mulps - names
;__mulsd	equ	_mulsd - names
__neg	equ	_neg - names
__nop	equ	_nop - names
__not	equ	_not - names
__or	equ	_or - names
;__orpd	equ	_orpd - names
;__orps	equ	_orps - names
__out	equ	_out - names
__outs	equ	_outs - names
__outsb	equ	_outsb - names
__outsd	equ	_outsd - names
;__packssdw	equ	_packssdw - names
;__packsswb	equ	_packsswb - names
;__packusdw	equ	_packusdw - names
;__packuswb	equ	_packuswb - names
;__paddb	equ	_paddb - names
;__paddd	equ	_paddd - names
;__paddq	equ	_paddq - names
;__paddsb	equ	_paddsb - names
;__paddsw	equ	_paddsw - names
;__paddusb	equ	_paddusb - names
;__paddusw	equ	_paddusw - names
;__paddw	equ	_paddw - names
;__pand	equ	_pand - names
;__pandn	equ	_pandn - names
;__pavgb	equ	_pavgb - names
;__pavgusb	equ	_pavgusb - names
;__pavgw	equ	_pavgw - names
;__pcmpeqb	equ	_pcmpeqb - names
;__pcmpeqd	equ	_pcmpeqd - names
;__pcmpeqw	equ	_pcmpeqw - names
;__pcmpgtb	equ	_pcmpgtb - names
;__pcmpgtd	equ	_pcmpgtd - names
;__pcmpgtw	equ	_pcmpgtw - names
;__pextrw	equ	_pextrw - names
;__pf2id	equ	_pf2id - names
;__pf2iw	equ	_pf2iw - names
;__pfacc	equ	_pfacc - names
;__pfadd	equ	_pfadd - names
;__pfcmpeq	equ	_pfcmpeq - names
;__pfcmpge	equ	_pfcmpge - names
;__pfcmpgt	equ	_pfcmpgt - names
;__pfmax	equ	_pfmax - names
;__pfmin	equ	_pfmin - names
;__pfmul	equ	_pfmul - names
;__pfnacc	equ	_pfnacc - names
;__pfpnacc	equ	_pfpnacc - names
;__pfrcp	equ	_pfrcp - names
;__pfrcpit1	equ	_pfrcpit1 - names
;__pfrcpit2	equ	_pfrcpit2 - names
;__pfrsqit1	equ	_pfrsqit1 - names
;__pfrsqrt	equ	_pfrsqrt - names
;__pfsub	equ	_pfsub - names
;__pfsubr	equ	_pfsubr - names
;__pi2fd	equ	_pi2fd - names
;__pi2fw	equ	_pi2fw - names
;__pinsrw	equ	_pinsrw - names
;__pmaddwd	equ	_pmaddwd - names
;__pmaxsw	equ	_pmaxsw - names
;__pmaxub	equ	_pmaxub - names
;__pminsw	equ	_pminsw - names
;__pminub	equ	_pminub - names
;__pmovmskb	equ	_pmovmskb - names
;__pmulhrw	equ	_pmulhrw - names
;__pmulhuw	equ	_pmulhuw - names
;__pmulhw	equ	_pmulhw - names
;__pmullw	equ	_pmullw - names
;__pmuludq	equ	_pmuludq - names
__pop	equ	_pop - names
__popa	equ	_popa - names
;__popad	equ	_popad - names
__popf	equ	_popf - names
;__popfd	equ	_popfd - names
;__popfq	equ	_popfq - names
;__por	equ	_por - names
;__prefetch	equ	_prefetch - names
;__psadbw	equ	_psadbw - names
;__pshufd	equ	_pshufd - names
;__pshufhw	equ	_pshufhw - names
;__pshuflw	equ	_pshuflw - names
;__pshufw	equ	_pshufw - names
;__pslld	equ	_pslld - names
;__pslldq	equ	_pslldq - names
;__psllq	equ	_psllq - names
;__psllw	equ	_psllw - names
;__psrad	equ	_psrad - names
;__psraw	equ	_psraw - names
;__psraq	equ	_psraq - names
;__psrld	equ	_psrld - names
;__psrldq	equ	_psrldq - names
;__psrlq	equ	_psrlq - names
;__psrlw	equ	_psrlw - names
;__psubb	equ	_psubb - names
;__psubd	equ	_psubd - names
;__psubq	equ	_psubq - names
;__psubsb	equ	_psubsb - names
;__psubsw	equ	_psubsw - names
;__psubusb	equ	_psubusb - names
;__psubusw	equ	_psubusw - names
;__psubw	equ	_psubw - names
;__pswapd	equ	_pswapd - names
;__punpckhbw	equ	_punpckhbw - names
;__punpckhdq	equ	_punpckhdq - names
;__punpckhqdq	equ	_punpckhqdq - names
;__punpckhwd	equ	_punpckhwd - names
;__punpcklbw	equ	_punpcklbw - names
;__punpckldq	equ	_punpckldq - names
;__punpcklqdq	equ	_punpcklqdq - names
;__punpcklwd	equ	_punpcklwd - names
__push	equ	_push - names
__pusha	equ	_pusha - names
;__pushad	equ	_pushad - names
__pushf	equ	_pushf - names
;__pushfd	equ	_pushfd - names
;__pushfq	equ	_pushfq - names
;__pxor	equ	_pxor - names
__rcl	equ	_rcl - names
;__rcpps	equ	_rcpps - names
__rcr	equ	_rcr - names
;__rdivisr	equ	_rdivisr - names
;__rdmsr	equ	_rdmsr - names
;__rdpmc	equ	_rdpmc - names
;__rdtsc	equ	_rdtsc - names
__rep	equ	_rep - names
__repne	equ	_repne - names
__ret	equ	_ret - names
__retf	equ	_retf - names
__rol	equ	_rol - names
__ror	equ	_ror - names
__rsm	equ	_rsm - names
;__rsqrtps	equ	_rsqrtps - names
__sahf	equ	_sahf - names
__sal	equ	_sal - names
__salc	equ	_salc - names
__sar	equ	_sar - names
__sbb	equ	_sbb - names
__scas	equ	_scas - names
__scasb	equ	_scasb - names
__scasd	equ	_scasd - names
;__scasq	equ	_scasq - names
__seto	equ	_seto - names
__setno	equ	_setno - names
__setc	equ	_setc - names
__setnc	equ	_setnc - names
__sete	equ	_sete - names
__setne	equ	_setne - names
__seta	equ	_seta - names
__setna	equ	_setna - names
__setnba	equ	_setnba - names
__sets	equ	_sets - names
__setns	equ	_setns - names
__setp	equ	_setp - names
__setnp	equ	_setnp - names
__setl	equ	_setl - names
__setnl	equ	_setnl - names
__setng	equ	_setng - names
__setg	equ	_setg - names
;__sfence	equ	_sfence - names
;__sgdt	equ	_sgdt - names
__shl	equ	_shl - names
__shld	equ	_shld - names
__shr	equ	_shr - names
__shrd	equ	_shrd - names
;__shufpd	equ	_shufpd - names
;__shufps	equ	_shufps - names
;__sidt	equ	_sidt - names
;__sldt	equ	_sldt - names
__smsw	equ	_smsw - names
;__sqrtpd	equ	_sqrtpd - names
;__sqrtps	equ	_sqrtps - names
;__sqrtsd	equ	_sqrtsd - names
__stc	equ	_stc - names
__std	equ	_std - names
__sti	equ	_sti - names
;__stmxcsr	equ	_stmxcsr - names
__stos	equ	_stos - names
__stosb	equ	_stosb - names
__stosd	equ	_stosd - names
__str	equ	_str - names
__sub	equ	_sub - names
;__subpd	equ	_subpd - names
;__subps	equ	_subps - names
;__subsd	equ	_subsd - names
;__swapgs	equ	_swapgs - names
;__syscall	equ	_syscall - names
;__sysenter	equ	_sysenter - names
;__sysexit	equ	_sysexit - names
;__sysret	equ	_sysret - names
__test	equ	_test - names
;__ucomisd	equ	_ucomisd - names
;__ucomiss	equ	_ucomiss - names
;__ud2	equ	_ud2 - names
;__unpckhpd	equ	_unpckhpd - names
;__unpckhps	equ	_unpckhps - names
;__unpcklpd	equ	_unpcklpd - names
;__unpcklps	equ	_unpcklps - names
;__verr	equ	_verr - names
;__verw	equ	_verw - names
__wait	equ	_wait - names
;__wbinvd	equ	_wbinvd - names
;__wrmsr	equ	_wrmsr - names
__xadd	equ	_xadd - names
__xchg	equ	_xchg - names
__xlat	equ	_xlat - names
__xlatb	equ	_xlatb - names
__xor	equ	_xor - names
;__xorpd	equ	_xorpd - names
;__xorps	equ	_xorps - names

__byte  equ	_byte - names
__word  equ     _word - names
__dword equ     _dword - names
__short equ     _short - names
__opsz  equ	_opsz - names
__adsz	equ	_adsz - names

__es	equ	_es - regs_seg
__cs	equ	_cs - regs_seg
__ss	equ	_ss - regs_seg
__ds	equ	_ds - regs_seg
__fs	equ	_fs - regs_seg
__gs	equ	_gs - regs_seg



