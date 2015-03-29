
;   Copyright (C) 2007 Jeff Owens
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.


  [section .text align=1]

;------------------ x_key_translate.inc -----------------------

struc key_pkt
.code	resb 1		;code = 2
.key	resb 1		;x code (not scan code)
.seq	resw 1		;pkt sequence#
.time	resd 1		;time of event
.root	resd 1		;root win id
.ewinn	resd 1		;event win id
.cwin	resd 1		;child win (0=none)
.rootx	resw 1		;root pix column
.rooty	resw 1		;root pix row
.eventx resw 1		;event pix column
.eventy resw 1		;event pix row
.mask	resw 1		;event bits
.same	resb 1		;same screen bool
	resb 1		;unused
;mask bits are:
; 10-numlock 08-alt 04-ctrl 02-caplock 01-shift
endstruc

;---------------------
;>1 keyboard
;  x_key_translate - convert event packet to key codes
; INPUTS
;  ebp = window block
;  ecx = event packet pointer
; OUTPUT:
;  "js" flag set if printable ascii, (ah has 80h bit set)
;  ah=flag
;   80=printable ascii 40=non-printable
;   20=modifier key  10-numlock
;   08-alt 04-ctrl 02-caplock 01-shift
;  al= printable ascii if flag 80h bit set
;  al= non printable ascii if flag 40h set, this bit should
;      never be set, it is for error checking.  Normally, non
;      printable characters have bits 80h, and 40h zeroed.
;  al= t-code if no 80h or 40h flag bits
;
;       unshifted          shifted
;x-code t-code    name       code   name
;-----  ------- -------    -----  ----------------
;  8     
;  9       201b (Escape)	
; 10     0x8031 (1)          0x8021 (exclam)	
; 11     0x8032 (2)          0x8040 (at)	
; 12     0x8033 (3)          0x8023 (numbersign)	
; 13     0x8034 (4)          0x8024 (dollar)	
; 14     0x8035 (5)          0x8025 (percent)	
; 15     0x8036 (6)          0x805e (asciicircum)	
; 16     0x8037 (7)          0x8026 (ampersand)	
; 17     0x8038 (8)          0x802a (asterisk)	
; 18     0x8039 (9)          0x8028 (parenleft)	
; 19     0x8030 (0)          0x8029 (parenright)	
; 20     0x802d (minus)      0x805f (underscore)	
; 21     0x803d (equal)      0x802b (plus)	
; 22       0008 (BackSpace)         (Terminate_Server)	
; 23       0009 (Tab)          0020 (ISO_Left_Tab)	
; 24     0x8071 (q)          0x8051 (Q)	
; 25     0x8077 (w)          0x8057 (W)	
; 26     0x8065 (e)          0x8045 (E)	
; 27     0x8072 (r)          0x8052 (R)	
; 28     0x8074 (t)          0x8054 (T)	
; 29     0x8079 (y)          0x8059 (Y)	
; 30     0x8075 (u)          0x8055 (U)	
; 31     0x8069 (i)          0x8049 (I)	
; 32     0x806f (o)          0x804f (O)	
; 33     0x8070 (p)          0x8050 (P)	
; 34     0x805b (bracketleft)   0x807b (braceleft)	
; 35     0x805d (bracketright)  0x807d (braceright)	
; 36       000d (Return)	
; 37       20e3 (Control_L)	
; 38     0x8061 (a)          0x8041 (A)	
; 39     0x8073 (s)          0x8053 (S)	
; 40     0x8064 (d)          0x8044 (D)	
; 41     0x8066 (f)          0x8046 (F)	
; 42     0x8067 (g)          0x8047 (G)	
; 43     0x8068 (h)          0x8048 (H)	
; 44     0x806a (j)          0x804a (J)	
; 45     0x806b (k)          0x804b (K)	
; 46     0x806c (l)          0x804c (L)	
; 47     0x803b (semicolon)  0x803a (colon)	
; 48     0x8027 (apostrophe) 0x8022 (quotedbl)	
; 49     0x8060 (grave)      0x807e (asciitilde)	
; 50       20e1 (Shift_L)	
; 51     0x805c (backslash)  0x807c (bar)	
; 52     0x807a (z)          0x805a (Z)	
; 53     0x8078 (x)          0x8058 (X)	
; 54     0x8063 (c)          0x8043 (C)	
; 55     0x8076 (v)          0x8056 (V)	
; 56     0x8062 (b)          0x8042 (B)	
; 57     0x806e (n)          0x804e (N)	
; 58     0x806d (m)          0x804d (M)	
; 59     0x802c (comma)      0x803c (less)	
; 60     0x802e (period)     0x803e (greater)	
; 61     0x802f (slash)      0x803f (question)	
; 62       20e2 (Shift_R)	
; 63       00aa (KP_Multiply)       (XF86_ClearGrab)	
; 64       20e9 (Alt_L)	            (Meta_L)	
; 65     0x8020 (space)	
; 66       20e5 (Caps_Lock)	
; 67       00be (F1)	   (XF86_Switch_VT_1)	
; 68       00bf (F2)	   (XF86_Switch_VT_2)	
; 69       00c0 (F3)	   (XF86_Switch_VT_3)	
; 70       00c1 (F4)	   (XF86_Switch_VT_4)	
; 71       00c2 (F5)	   (XF86_Switch_VT_5)	
; 72       00c3 (F6)	   (XF86_Switch_VT_6)	
; 73       00c4 (F7)	   (XF86_Switch_VT_7)	
; 74       00c5 (F8)	   (XF86_Switch_VT_8)	
; 75       00c6 (F9)	   (XF86_Switch_VT_9)	
; 76       00c7 (F10)	   (XF86_Switch_VT_10)	
; 77       007f (Num_Lock) (Pointer_EnableKeys)	
; 78       0014 (Scroll_Lock)	
; 79       0095 (KP_Home)  00b7 (KP_7)	
; 80       0097 (KP_Up)	   00b8 (KP_8)	
; 81       009a (KP_Pgup ) 00b9 (KP_9)	
; 82       00ad (KP_Subtract) 0023 (XF86_Prev_VMode)	
; 83       0096 (KP_Left)  00b4 (KP_4)	
; 84       009d (KP_Begin) 00b5 (KP_5)	
; 85       0098 (KP_Right) 00b6 (KP_6)	
; 86       00ab (KP_Add)   0022 (XF86_Next_VMode)	
; 87       009c (KP_End)   00b1 (KP_1)	
; 88       0099 (KP_Down)  00b2 (KP_2)	
; 89       009b (KP_Pgdn)  00b3 (KP_3)	
; 90       009e (KP_Insert)00b0 (KP_0)	
; 91       009f (KP_Delete)00ae (KP_Decimal)	
; 92     
; 93       007e (Mode_switch)	
; 94       803c (less)          0x803e (greater) 
; 95       00c8 (F11)	 000b   (XF86_Switch_VT_11)	
; 96       00c9 (F12)    000c   (XF86_Switch_VT_12)	
; 97       0050 (Home)	
; 98       0052 (Up)	
; 99       0055 (Pgup )	
;100       0051 (Left)	
;101     
;102       0053 (Right)	
;103       0057 (End)	
;104       0054 (Down)	
;105       0056 (Pgdn)	
;106       0063 (Insert)	
;107       00ff (Delete)	
;108       008d (KP_Enter)	
;109       20e4 (Control_R)	
;110       0013 (Pause)  006b (Break)	
;111       0061 (Print)  0015 (Sys_Req)	
;112       00af (KP_Divide)   (XF86_Ungrab)	
;113       20ea (Alt_R)  20e8 (Meta_R)	
;
;    error = sign flag set
;    success -
;              
; NOTES
;   source file: x_key_translate
;<
; * ----------------------------------------------

  global x_key_translate
x_key_translate:
  movzx	ebx,byte [ecx+key_pkt.key]
  mov	eax,ebx
  shl	ebx,1		;multiply by 2
  add	ebx,eax		;multiply by 3
  add	ebx,key_translate_table - (8 * 3)
  test	[ecx+key_pkt.mask],byte 1 ;shift?
  jz	ascii_no_shift
;we have a shifted ascii char
  mov	al,[ebx+2]	;get char from table
  jmp	short build_flag
ascii_no_shift:
  mov	al,[ebx+1]	;get char from table
build_flag:
  mov	ah,[ecx+key_pkt.mask]	;get flags
  or	ah,[ebx]		;insert table flags
  ret

  [section .data]

;NOTE: this table is built in window_pre and entries below
;      are not used or correct
;
  global key_translate_table
;                unshifted shifted
; table format:  flag,code,code
key_translate_table:
 db 20h,00h,00h	;  8     
 db 40h,1bh,1bh	;  9            (Escape)	
 db 80h,"1","!"	; 10     0x8031 (1)          0x8021 (exclam)	
 db 80h,"2","@"	; 11     0x8032 (2)          0x8040 (at)	
 db 80h,"3","#"	; 12     0x8033 (3)          0x8023 (numbersign)	
 db 80h,"4","$"	; 13     0x8034 (4)          0x8024 (dollar)	
 db 80h,"5","%"	; 14     0x8035 (5)          0x8025 (percent)	
 db 80h,"6","^"	; 15     0x8036 (6)          0x805e (asciicircum)	
 db 80h,"7","&"	; 16     0x8037 (7)          0x8026 (ampersand)	
 db 80h,"8","*"	; 17     0x8038 (8)          0x802a (asterisk)	
 db 80h,"9","*"	; 18     0x8039 (9)          0x8028 (parenleft)	
 db 80h,"0","("	; 19     0x8030 (0)          0x8029 (parenright)	
 db 80h,"-",")"	; 20     0x802d (minus)      0x805f (underscore)	
 db 80h,"=","+"	; 21     0x803d (equal)      0x802b (plus)	
 db 40h,08h,08h	; 22            (BackSpace)         (Terminate_Server)	
 db 40h,09h,09h	; 23            (Tab)               (ISO_Left_Tab)	
 db 80h,"q","Q"	; 24     0x8071 (q)          0x8051 (Q)	
 db 80h,"w","W"	; 25     0x8077 (w)          0x8057 (W)	
 db 80h,"e","E" ; 26     0x8065 (e)          0x8045 (E)	
 db 80h,"r","R"	; 27     0x8072 (r)          0x8052 (R)	
 db 80h,"t","T"	; 28     0x8074 (t)          0x8054 (T)	
 db 80h,"y","Y"	; 29     0x8079 (y)          0x8059 (Y)	
 db 80h,"u","U"	; 30     0x8075 (u)          0x8055 (U)	
 db 80h,"i","I"	; 31     0x8069 (i)          0x8049 (I)	
 db 80h,"o","O"	; 32     0x806f (o)          0x804f (O)	
 db 80h,"p","P"	; 33     0x8070 (p)          0x8050 (P)	
 db 80h,"[","{"	; 34     0x805b (bracketleft)   0x807b (braceleft)	
 db 80h,"]","}"	; 35     0x805d (bracketright)  0x807d (braceright)	
 db 40h,0dh,0dh	; 36            (Return)	
 db 20h," "," "	; 37            (Control_L)	
 db 80h,"a","A"	; 38     0x8061 (a)          0x8041 (A)	
 db 80h,"s","S"	; 39     0x8073 (s)          0x8053 (S)	
 db 80h,"d","D"	; 40     0x8064 (d)          0x8044 (D)	
 db 80h,"f","F"	; 41     0x8066 (f)          0x8046 (F)	
 db 80h,"g","G"	; 42     0x8067 (g)          0x8047 (G)	
 db 80h,"h","H"	; 43     0x8068 (h)          0x8048 (H)	
 db 80h,"j","J"	; 44     0x806a (j)          0x804a (J)	
 db 80h,"k","K"	; 45     0x806b (k)          0x804b (K)	
 db 80h,"l","L"	; 46     0x806c (l)          0x804c (L)	
 db 80h,";",":"	; 47     0x803b (semicolon)  0x803a (colon)	
 db 80h,27h,22h	; 48     0x8027 (apostrophe) 0x8022 (quotedbl)	
 db 80h,"`","~"	; 49     0x8060 (grave)      0x807e (asciitilde)	
 db 20h," "," "	; 50            (Shift_L)	
 db 80h,"\","|"	; 51     0x805c (backslash)  0x807c (bar)	
 db 80h,"z","Z"	; 52     0x807a (z)          0x805a (Z)	
 db 80h,"x","X"	; 53     0x8078 (x)          0x8058 (X)	
 db 80h,"c","C"	; 54     0x8063 (c)          0x8043 (C)	
 db 80h,"v","V"	; 55     0x8076 (v)          0x8056 (V)	
 db 80h,"b","B"	; 56     0x8062 (b)          0x8042 (B)	
 db 80h,"n","N"	; 57     0x806e (n)          0x804e (N)	
 db 80h,"m","M"	; 58     0x806d (m)          0x804d (M)	
 db 80h,",","<"	; 59     0x802c (comma)      0x803c (less)	
 db 80h,".",">"	; 60     0x802e (period)     0x803e (greater)	
 db 80h,"/","?"	; 61     0x802f (slash)      0x803f (question)	
 db 20h,062,000	; 62            (Shift_R)	
 db 00h,063,063	; 63            (KP_Multiply)       (XF86_ClearGrab)	
 db 20h,064,064	; 64            (Alt_L)	        (Meta_L)	
 db 80h," "," "	; 65     0x8020 (space)	
 db 20h,066,000	; 66            (Caps_Lock)	
 db 00h,067,067	; 67            (F1)	   (XF86_Switch_VT_1)	
 db 00h,068,068	; 68            (F2)	   (XF86_Switch_VT_2)	
 db 00h,069,069	; 69            (F3)	   (XF86_Switch_VT_3)	
 db 00h,070,070	; 70            (F4)	   (XF86_Switch_VT_4)	
 db 00h,071,071	; 71            (F5)	   (XF86_Switch_VT_5)	
 db 00h,072,072	; 72            (F6)	   (XF86_Switch_VT_6)	
 db 00h,073,073	; 73            (F7)	   (XF86_Switch_VT_7)	
 db 00h,074,074	; 74            (F8)	   (XF86_Switch_VT_8)	
 db 00h,075,075 ; 75            (F9)	   (XF86_Switch_VT_9)	
 db 00h,076,076	; 76            (F10)	   (XF86_Switch_VT_10)	
 db 00h,077,077	; 77            (Num_Lock) (Pointer_EnableKeys)	
 db 00h,078,078	; 78            (Scroll_Lock)	
 db 00h,079,079	; 79            (KP_Home)       (KP_7)	
 db 00h,080,080	; 80            (KP_Up)	        (KP_8)	
 db 00h,081,081	; 81            (KP_pgup )      (KP_9)	
 db 00h,082,082	; 82            (KP_Subtract)   (XF86_Prev_VMode)	
 db 00h,083,083	; 83            (KP_Left)       (KP_4)	
 db 00h,084,084	; 84            (KP_Begin)      (KP_5)	
 db 00h,085,085	; 85            (KP_Right)      (KP_6)	
 db 00h,086,086	; 86            (KP_Add)        (XF86_Next_VMode)	
 db 00h,087,087	; 87            (KP_End)	(KP_1)	
 db 00h,088,088	; 88            (KP_Down)       (KP_2)	
 db 00h,089,089	; 89            (KP_pgdn)       (KP_3)	
 db 00h,090,090	; 90            (KP_Insert)     (KP_0)	
 db 00h,091,091	; 91            (KP_Delete)     (KP_Decimal)	
 db 00h,092,092	; 92     
 db 00h,093,093	; 93            (Mode_switch)	
 db 00h,094,094	; 94     0x803c (less)          0x803e (greater)          0x807c (bar)          0x80a6 (brokenbar)          0x807c (bar)          0x80a6 (brokenbar)	
 db 00h,095,095	; 95            (F11)           (XF86_Switch_VT_11)	
 db 00h,096,096	; 96            (F12)           (XF86_Switch_VT_12)	
 db 00h,097,097	; 97            (Home)	
 db 00h,098,098	; 98            (Up)	
 db 00h,099,099	; 99            (Prior)	
 db 00h,100,100	;100            (Left)	
 db 20h,101,101	;101     
 db 00h,102,102	;102            (Right)	
 db 00h,103,103	;103            (End)	
 db 00h,104,104	;104            (Down)	
 db 00h,105,105	;105            (Next)	
 db 00h,106,106	;106            (Insert)	
 db 00h,107,107	;107            (Delete)	
 db 00h,108,108	;108            (KP_Enter)	
 db 20h,109,109	;109            (Control_R)	
 db 00h,110,110	;110            (Pause)       (Break)	
 db 00h,111,111	;111            (Print)       (Sys_Req)	
 db 00h,112,112	;112            (KP_Divide)   (XF86_Ungrab)	
 db 20h,113,113	;113            (Alt_R)       (Meta_R)	
 times (255 - 113) db 20h,0,0
  [section .text]

