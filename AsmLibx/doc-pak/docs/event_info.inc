;-------------- event_info.inc -----------------------------


struc XAnyEvent
.type		resd	1 ;
.serial		resd	1 ; # of last request processed by server
.send_event	resd	1 ; true if this came from a SendEvent request
.display	resd	1 ; Display the event was read from
.window		resd	1 ; window on which event was requested in event mask
endstruc

struc XKeyEvent
.type		resd	1; of event
.serial		resd	1; # of last request processed by server
.send_event	resd	1; true if this came from a SendEvent request
.display	resd	1; Display the event was read from
.window		resd	1;         "event" window it is reported relative to
.root		resd	1;         root window that the event occurred on
.subwindow	resd	1; child window
.time		resd	1; milliseconds
.x		resd	1
.y		resd	1; pointer x, y coordinates in event window
.x_root 	resd	1
.y_root		resd	1; coordinates relative to root
.state		resd	1; key or button mask
.keycode	resd	1; detail
.same_screen	resd	1; same screen flag
endstruc

struc XButtonEvent
.type		resd	1; of event
.serial		resd	1; # of last request processed by server
.send_event	resd	1; true if this came from a SendEvent request
.display	resd	1; Display the event was read from
.window		resd	1;         "event" window it is reported relative to
.root		resd	1;         root window that the event occurred on
.subwindow	resd	1; child window
.time		resd	1; milliseconds
.x		resd	1
.y		resd	1; pointer x, y coordinates in event window
.x_root		resd	1
.y_root		resd	1; coordinates relative to root
.state		resd	1; key or button mask
.button		resd	1; detail
.same_screen	resd	1; same screen flag
endstruc

;Event Types
EventError	equ  0
EventCmdOK	equ  1
KeyPress	 equ 2 
KeyRelease	 equ 3
ButtonPress	 equ 4
ButtonRelease	 equ 5
MotionNotify	 equ 6
EnterNotify	 equ 7
LeaveNotify	 equ 8
FocusIn		 equ 9
FocusOut	 equ 10
KeymapNotify	 equ 11
Expose		 equ 12
GraphicsExpose	 equ 13
NoExpose	 equ 14
VisibilityNotify equ 15
CreateNotify	 equ 16
DestroyNotify	 equ 17
UnmapNotify	 equ 18
MapNotify	 equ 19
MapRequest	 equ 20
ReparentNotify	 equ 21
ConfigureNotify	 equ 22
ConfigureRequest equ 23
GravityNotify	 equ 24
ResizeRequest	 equ 25
CirculateNotify	 equ 26
CirculateRequest equ 27
PropertyNotify	 equ 28
SelectionClear	 equ 29
SelectionRequest equ 30
SelectionNotify	 equ 31
ColormapNotify	 equ 32
ClientMessage	 equ 33
MappingNotify	 equ 34
LASTEvent	 equ 35

;Event Masks for XSelectInput
%define NoEventMask			 0
%define KeyPressMask			 (1 << 0)  
%define KeyReleaseMask			 (1 << 1)  
%define ButtonPressMask			 (1 << 2)  
%define ButtonReleaseMask		 (1 << 3)  
%define EnterWindowMask			 (1 << 4)  
%define LeaveWindowMask			 (1 << 5)  
%define PointerMotionMask		 (1 << 6)  
%define PointerMotionHintMask		 (1 << 7)  
%define Button1MotionMask		 (1 << 8)  
%define Button2MotionMask		 (1 << 9)  
%define Button3MotionMask		 (1 << 10) 
%define Button4MotionMask		 (1 << 11) 
%define Button5MotionMask		 (1 << 12) 
%define ButtonMotionMask		 (1 << 13) 
%define KeymapStateMask			 (1 << 14)
%define ExposureMask			 (1 << 15) 
%define VisibilityChangeMask		 (1 << 16) 
%define StructureNotifyMask		 (1 << 17) 
%define ResizeRedirectMask		 (1 << 18) 
%define SubstructureNotifyMask		 (1 << 19) 
%define SubstructureRedirectMask	 (1 << 20) 
%define FocusChangeMask			 (1 << 21) 
%define PropertyChangeMask		 (1 << 22) 
%define ColormapChangeMask		 (1 << 23) 
%define OwnerGrabButtonMask		 (1 << 24) 


;key definitions
XK_Home   equ              0xFF50
XK_Left   equ              0xFF51  ; Move left, left arrow 
XK_Up     equ              0xFF52  ; Move up, up arrow 
XK_Right  equ              0xFF53  ; Move right, right arrow 
XK_Down   equ              0xFF54  ; Move down, down arrow 
XK_Prior  equ              0xFF55  ; Prior, previous 
XK_Page_Up equ             0xFF55
XK_Next    equ             0xFF56  ; Next 
XK_Page_Down equ           0xFF56
XK_End       equ           0xFF57  ; EOL 
XK_Begin     equ           0xFF58  ; BOL 
; Keypad Functions, keypad numbers cleverly chosen to map to ascii 

XK_KP_Space equ            0xFF80  ; space 
XK_KP_Tab   equ            0xFF89
XK_KP_Enter equ            0xFF8D  ; enter 
XK_KP_F1    equ            0xFF91  ; PF1, KP_A, ... 
XK_KP_F2    equ            0xFF92
XK_KP_F3    equ            0xFF93
XK_KP_F4    equ            0xFF94
XK_KP_Home  equ            0xFF95
XK_KP_Left  equ            0xFF96
XK_KP_Up    equ            0xFF97
XK_KP_Right  equ           0xFF98
XK_KP_Down   equ           0xFF99
XK_KP_Prior  equ           0xFF9A
XK_KP_Page_Up equ          0xFF9A
XK_KP_Next    equ          0xFF9B
XK_KP_Page_Down equ        0xFF9B
XK_KP_End       equ        0xFF9C
XK_KP_Begin   equ          0xFF9D
XK_KP_Insert  equ          0xFF9E
XK_KP_Delete  equ          0xFF9F
XK_KP_Equal   equ          0xFFBD  ; equals 
XK_KP_Multiply equ         0xFFAA
XK_KP_Add      equ         0xFFAB
XK_KP_Separator equ        0xFFAC  ; separator, often comma 
XK_KP_Subtract  equ        0xFFAD
XK_KP_Decimal   equ        0xFFAE
XK_KP_Divide    equ        0xFFAF

XK_KP_0        equ         0xFFB0
XK_KP_1        equ         0xFFB1
XK_KP_2        equ         0xFFB2
XK_KP_3        equ         0xFFB3
XK_KP_4        equ         0xFFB4
XK_KP_5        equ         0xFFB5
XK_KP_6        equ          0xFFB6
XK_KP_7        equ         0xFFB7
XK_KP_8        equ         0xFFB8
XK_KP_9        equ         0xFFB9
;XK_LATIN1
XK_space               equ 0x020
XK_exclam              equ 0x021
XK_quotedbl            equ 0x022
XK_numbersign          equ 0x023
XK_dollar              equ 0x024
XK_percent             equ 0x025
XK_ampersand           equ 0x026
XK_apostrophe          equ 0x027
XK_quoteright          equ 0x027    ; deprecated 
XK_parenleft           equ 0x028
XK_parenright          equ 0x029
XK_asterisk            equ 0x02a
XK_plus                equ 0x02b
XK_comma               equ 0x02c
XK_minus               equ 0x02d
XK_period              equ 0x02e
XK_slash               equ 0x02f
XK_0                   equ 0x030
XK_1                   equ 0x031
XK_2                   equ 0x032
XK_3                   equ 0x033
XK_4                   equ 0x034
XK_5                   equ 0x035
XK_6                   equ 0x036
XK_7                   equ 0x037
XK_8                   equ 0x038
XK_9                   equ 0x039
XK_colon               equ 0x03a
XK_semicolon           equ 0x03b
XK_less                equ 0x03c
XK_equal               equ 0x03d
XK_greater             equ 0x03e
XK_question            equ 0x03f
XK_at                  equ 0x040
XK_A                   equ 0x041
XK_B                   equ 0x042
XK_C                   equ 0x043
XK_D                   equ 0x044
XK_E                   equ 0x045
XK_F                   equ 0x046
XK_G                   equ 0x047
XK_H                   equ 0x048
XK_I                   equ 0x049
XK_J                   equ 0x04a
XK_K                   equ 0x04b
XK_L                   equ 0x04c
XK_M                   equ 0x04d
XK_N                   equ 0x04e
XK_O                   equ 0x04f
XK_P                   equ 0x050
XK_Q                   equ 0x051
XK_R                   equ 0x052
XK_S                   equ 0x053
XK_T                   equ 0x054
XK_U                   equ 0x055
XK_V                   equ 0x056
XK_W                   equ 0x057
XK_X                   equ 0x058
XK_Y                   equ 0x059
XK_Z                   equ 0x05a
XK_bracketleft         equ 0x05b
XK_backslash           equ 0x05c
XK_bracketright        equ 0x05d
XK_asciicircum         equ 0x05e
XK_underscore          equ 0x05f
XK_grave               equ 0x060
XK_quoteleft           equ 0x060    ; deprecated 
XK_a                   equ 0x061
XK_b                   equ 0x062
XK_c                   equ 0x063
XK_d                   equ 0x064
XK_e                   equ 0x065
XK_f                   equ 0x066
XK_g                   equ 0x067
XK_h                   equ 0x068
XK_i                   equ 0x069
XK_j                   equ 0x06a
XK_k                   equ 0x06b
XK_l                   equ 0x06c
XK_m                   equ 0x06d
XK_n                   equ 0x06e
XK_o                   equ 0x06f
XK_p                   equ 0x070
XK_q                   equ 0x071
XK_r                   equ 0x072
XK_s                   equ 0x073
XK_t                   equ 0x074
XK_u                   equ 0x075
XK_v                   equ 0x076
XK_w                   equ 0x077
XK_x                   equ 0x078
XK_y                   equ 0x079
XK_z                   equ 0x07a
XK_braceleft           equ 0x07b
XK_bar                 equ 0x07c
XK_braceright          equ 0x07d
XK_asciitilde          equ 0x07e

XK_nobreakspace        equ 0x0a0
XK_exclamdown          equ 0x0a1
XK_cent                equ 0x0a2
XK_sterling            equ 0x0a3
XK_currency            equ 0x0a4
XK_yen                 equ 0x0a5
XK_brokenbar           equ 0x0a6
XK_section             equ 0x0a7
XK_diaeresis           equ 0x0a8
XK_copyright           equ 0x0a9
XK_ordfeminine         equ 0x0aa
XK_guillemotleft       equ 0x0ab    ; left angle quotation mark 
XK_notsign             equ 0x0ac
XK_hyphen              equ 0x0ad
XK_registered          equ 0x0ae
XK_macron              equ 0x0af
XK_degree              equ 0x0b0
XK_plusminus           equ 0x0b1
XK_twosuperior         equ 0x0b2
XK_threesuperior       equ 0x0b3
XK_acute               equ 0x0b4
XK_mu                  equ 0x0b5
XK_paragraph           equ 0x0b6
XK_periodcentered      equ 0x0b7
XK_cedilla             equ 0x0b8
XK_onesuperior         equ 0x0b9
XK_masculine           equ 0x0ba
XK_guillemotright      equ 0x0bb    ; right angle quotation mark 
XK_onequarter          equ 0x0bc
XK_onehalf             equ 0x0bd
XK_threequarters       equ 0x0be
XK_questiondown        equ 0x0bf
XK_Agrave              equ 0x0c0
XK_Aacute              equ 0x0c1
XK_Acircumflex         equ 0x0c2
XK_Atilde              equ 0x0c3
XK_Adiaeresis          equ 0x0c4
XK_Aring               equ 0x0c5
XK_AE                  equ 0x0c6
XK_Ccedilla            equ 0x0c7
XK_Egrave              equ 0x0c8
XK_Eacute              equ 0x0c9
XK_Ecircumflex         equ 0x0ca
XK_Ediaeresis          equ 0x0cb
XK_Igrave              equ 0x0cc
XK_Iacute              equ 0x0cd
XK_Icircumflex         equ 0x0ce
XK_Idiaeresis          equ 0x0cf
XK_ETH                 equ 0x0d0
XK_Eth                 equ 0x0d0    ; deprecated 
XK_Ntilde              equ 0x0d1
XK_Ograve              equ 0x0d2
XK_Oacute              equ 0x0d3
XK_Ocircumflex         equ 0x0d4
XK_Otilde              equ 0x0d5
XK_Odiaeresis          equ 0x0d6
XK_multiply            equ 0x0d7
XK_Ooblique            equ 0x0d8
XK_Oslash              equ XK_Ooblique
XK_Ugrave              equ 0x0d9
XK_Uacute              equ 0x0da
XK_Ucircumflex         equ 0x0db
XK_Udiaeresis          equ 0x0dc
XK_Yacute              equ 0x0dd
XK_THORN               equ 0x0de
XK_Thorn               equ 0x0de    ; deprecated 
XK_ssharp              equ 0x0df
XK_agrave              equ 0x0e0
XK_aacute              equ 0x0e1
XK_acircumflex         equ 0x0e2
XK_atilde              equ 0x0e3
XK_adiaeresis          equ 0x0e4
XK_aring               equ 0x0e5
XK_ae                  equ 0x0e6
XK_ccedilla            equ 0x0e7
XK_egrave              equ 0x0e8
XK_eacute              equ 0x0e9
XK_ecircumflex         equ 0x0ea
XK_ediaeresis          equ 0x0eb
XK_igrave              equ 0x0ec
XK_iacute              equ 0x0ed
XK_icircumflex         equ 0x0ee
XK_idiaeresis          equ 0x0ef
XK_eth                 equ 0x0f0
XK_ntilde              equ 0x0f1
XK_ograve              equ 0x0f2
XK_oacute              equ 0x0f3
XK_ocircumflex         equ 0x0f4
XK_otilde              equ 0x0f5
XK_odiaeresis          equ 0x0f6
XK_division            equ 0x0f7
XK_oslash              equ 0x0f8
XK_ooblique            equ XK_oslash
XK_ugrave              equ 0x0f9
XK_uacute              equ 0x0fa
XK_ucircumflex         equ 0x0fb
XK_udiaeresis          equ 0x0fc
XK_yacute              equ 0x0fd
XK_thorn               equ 0x0fe
XK_ydiaeresis          equ 0x0ff

