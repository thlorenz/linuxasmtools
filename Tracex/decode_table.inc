  [section .data]
;main decode lookup table, format: dd ascii_name_ptr
;                                  dd decode strings
decode_table:
 dd CreateWindow,_CreateWindow ;            1
 dd ChangeWindowAttributes,_ChangeWindowAttributes ;  2
 dd GetWindowAttributes,_GetWindowAttributes ;     3
 dd DestroyWindow,_DestroyWindow ;           4
 dd DestroySubwindows,_DestroySubwindows ;       5
 dd ChangeSaveSet,_ChangeSaveSet ;           6
 dd ReparentWindow,_ReparentWindow ;          7
 dd MapWindow,_MapWindow ;               8
 dd MapSubwindows,_MapSubwindows ;           9
 dd UnmapWindow,_UnmapWindow ;             10
 dd UnmapSubwindows,_UnmapSubwindows ;         11
 dd ConfigureWindow,_ConfigureWindow ;         12
 dd CirculateWindow,_CirculateWindow ;         13
 dd GetGeometry,_GetGeometry ;             14
 dd QueryTree,_QueryTree ;               15
 dd InternAtom,_InternAtom ;              16
 dd GetAtomName,_GetAtomName ;             17
 dd ChangeProperty,_ChangeProperty ;          18
 dd DeleteProperty,_DeleteProperty ;          19
 dd GetProperty,_GetProperty ;             20
 dd ListProperties,_ListProperties ;          21
 dd SetSelectionOwner,_SetSelectionOwner ;       22
 dd GetSelectionOwner,_GetSelectionOwner ;       23
 dd ConvertSelection,_ConvertSelection ;        24
 dd SendEvent,_SendEvent ;               25
 dd GrabPointer,_GrabPointer ;             26
 dd UngrabPointer,_UngrabPointer ;           27
 dd GrabButton,_GrabButton ;              28
 dd UngrabButton,_UngrabButton ;            29
 dd ChangeActivePointerGrab,_ChangeActivePointerGrab ; 30
 dd GrabKeyboard,_GrabKeyboard ;            31
 dd UngrabKeyboard,_UngrabKeyboard ;          32
 dd GrabKey,_GrabKey ;                 33
 dd UngrabKey,_UngrabKey ;               34
 dd AllowEvents,_AllowEvents ;             35
 dd GrabServer,_GrabServer ;              36
 dd UngrabServer,_UngrabServer ;            37
 dd QueryPointer,_QueryPointer ;            38
 dd GetMotionEvents,_GetMotionEvents ;         39
 dd TranslateCoords,_TranslateCoords ;         40
 dd WarpPointer,_WarpPointer ;             41
 dd SetInputFocus,_SetInputFocus ;           42
 dd GetInputFocus,_GetInputFocus ;           43
 dd QueryKeymap,_QueryKeymap ;             44
 dd OpenFont,_OpenFont ;                45
 dd CloseFont,_CloseFont ;               46
 dd QueryFont,_QueryFont ;               47
 dd QueryTextExtents,_QueryTextExtents ;        48
 dd ListFonts,_ListFonts ;               49
 dd ListFontsWithInfo,_ListFontsWithInfo ;       50
 dd SetFontPath,_SetFontPath ;             51
 dd GetFontPath,_GetFontPath ;             52
 dd CreatePixmap,_CreatePixmap ;            53
 dd FreePixmap,_FreePixmap ;              54
 dd CreateGC,_CreateGC ;                55
 dd ChangeGC,_ChangeGC ;                56
 dd CopyGC,_CopyGC ;                  57
 dd SetDashes,_SetDashes ;               58
 dd SetClipRectangles,_SetClipRectangles ;       59
 dd FreeGC,_FreeGC ;                  60
 dd ClearArea,_ClearArea ;               61
 dd CopyArea,_CopyArea ;                62
 dd CopyPlane,_CopyPlane ;               63
 dd PolyPoint,_PolyPoint ;               64
 dd PolyLine,_PolyLine ;                65
 dd PolySegment,_PolySegment ;             66
 dd PolyRectangle,_PolyRectangle ;           67
 dd PolyArc,_PolyArc ;                 68
 dd FillPoly,_FillPoly ;                69
 dd PolyFillRectangle,_PolyFillRectangle ;       70
 dd PolyFillArc,_PolyFillArc ;             71
 dd PutImage,_PutImage ;                72
 dd GetImage,_GetImage ;                73
 dd PolyText8,_PolyText8 ;               74
 dd PolyText16,_PolyText16 ;              75
 dd ImageText8,_ImageText8 ;              76
 dd ImageText16,_ImageText16 ;             77
 dd CreateColormap,_CreateColormap ;          78
 dd FreeColormap,_FreeColormap ;            79
 dd CopyColormapAndFree,_CopyColormapAndFree ;     80
 dd InstallColormap,_InstallColormap ;         81
 dd UninstallColormap,_UninstallColormap ;       82
 dd ListInstalledColormaps,_ListInstalledColormaps ;  83
 dd AllocColor,_AllocColor ;              84
 dd AllocNamedColor,_AllocNamedColor ;         85
 dd AllocColorCells,_AllocColorCells ;         86
 dd AllocColorPlanes,_AllocColorPlanes ;        87
 dd FreeColors,_FreeColors ;              88
 dd StoreColors,_StoreColors ;             89
 dd StoreNamedColor,_StoreNamedColor ;         90
 dd QueryColors,_QueryColors ;             91
 dd LookupColor,_LookupColor ;             92
 dd CreateCursor,_CreateCursor ;            93
 dd CreateGlyphCursor,_CreateGlyphCursor ;       94
 dd FreeCursor,_FreeCursor ;              95
 dd RecolorCursor,_RecolorCursor ;           96
 dd QueryBestSize,_QueryBestSize ;           97
 dd QueryExtension,_QueryExtension ;          98
 dd ListExtensions,_ListExtensions ;          99
 dd ChangeKeyboardMapping,_ChangeKeyboardMapping ;   100
 dd GetKeyboardMapping,_GetKeyboardMapping ;      101
 dd ChangeKeyboardControl,_ChangeKeyboardControl ;   102
 dd GetKeyboardControl,_GetKeyboardControl ;      103
 dd Bell,_Bell ;                    104
 dd ChangePointerControl,_ChangePointerControl ;    105
 dd GetPointerControl,_GetPointerControl ;       106
 dd SetScreenSaver,_SetScreenSaver ;          107
 dd GetScreenSaver,_GetScreenSaver ;          108
 dd ChangeHosts,_ChangeHosts ;             109
 dd ListHosts,_ListHosts ;               110
 dd SetAccessControl,_SetAccessControl ;        111
 dd SetCloseDownMode,_SetCloseDownMode ;        112
 dd KillClient,_KillClient ;              113
 dd RotateProperties,_RotateProperties ;        114
 dd ForceScreenSaver,_ForceScreenSaver ;        115
 dd SetPointerMapping,_SetPointerMapping ;       116
 dd GetPointerMapping,_GetPointerMapping ;       117
 dd SetModifierMapping,_SetModifierMapping ;      118
 dd GetModifierMapping,_GetModifierMapping ;      119
 dd NoOperation,_NoOperation ;             127
 times 43*8 db 0			;expansion area

;ascii function name table
CreateWindow: db "CreateWindow",0 ;            1
ChangeWindowAttributes: db "ChangeWindowAttributes",0 ;  2
GetWindowAttributes: db "GetWindowAttributes",0 ;     3
DestroyWindow: db "DestroyWindow",0 ;           4
DestroySubwindows: db "DestroySubwindows",0 ;       5
ChangeSaveSet: db "ChangeSaveSet",0 ;           6
ReparentWindow: db "ReparentWindow",0 ;          7
MapWindow: db "MapWindow",0 ;               8
MapSubwindows: db "MapSubwindows",0 ;           9
UnmapWindow: db "UnmapWindow",0 ;             10
UnmapSubwindows: db "UnmapSubwindows",0 ;         11
ConfigureWindow: db "ConfigureWindow",0 ;         12
CirculateWindow: db "CirculateWindow",0 ;         13
GetGeometry: db "GetGeometry",0 ;             14
QueryTree: db "QueryTree",0 ;               15
InternAtom: db "InternAtom",0 ;              16
GetAtomName: db "GetAtomName",0 ;             17
ChangeProperty: db "ChangeProperty",0 ;          18
DeleteProperty: db "DeleteProperty",0 ;          19
GetProperty: db "GetProperty",0 ;             20
ListProperties: db "ListProperties",0 ;          21
SetSelectionOwner: db "SetSelectionOwner",0 ;       22
GetSelectionOwner: db "GetSelectionOwner",0 ;       23
ConvertSelection: db "ConvertSelection",0 ;        24
SendEvent: db "SendEvent",0 ;               25
GrabPointer: db "GrabPointer",0 ;             26
UngrabPointer: db "UngrabPointer",0 ;           27
GrabButton: db "GrabButton",0 ;              28
UngrabButton: db "UngrabButton",0 ;            29
ChangeActivePointerGrab: db "ChangeActivePointerGrab",0 ; 30
GrabKeyboard: db "GrabKeyboard",0 ;            31
UngrabKeyboard: db "UngrabKeyboard",0 ;          32
GrabKey: db "GrabKey",0 ;                 33
UngrabKey: db "UngrabKey",0 ;               34
AllowEvents: db "AllowEvents",0 ;             35
GrabServer: db "GrabServer",0 ;              36
UngrabServer: db "UngrabServer",0 ;            37
QueryPointer: db "QueryPointer",0 ;            38
GetMotionEvents: db "GetMotionEvents",0 ;         39
TranslateCoords: db "TranslateCoords",0 ;         40
WarpPointer: db "WarpPointer",0 ;             41
SetInputFocus: db "SetInputFocus",0 ;           42
GetInputFocus: db "GetInputFocus",0 ;           43
QueryKeymap: db "QueryKeymap",0 ;             44
OpenFont: db "OpenFont",0 ;                45
CloseFont: db "CloseFont",0 ;               46
QueryFont: db "QueryFont",0 ;               47
QueryTextExtents: db "QueryTextExtents",0 ;        48
ListFonts: db "ListFonts",0 ;               49
ListFontsWithInfo: db "ListFontsWithInfo",0 ;       50
SetFontPath: db "SetFontPath",0 ;             51
GetFontPath: db "GetFontPath",0 ;             52
CreatePixmap: db "CreatePixmap",0 ;            53
FreePixmap: db "FreePixmap",0 ;              54
CreateGC: db "CreateGC",0 ;                55
ChangeGC: db "ChangeGC",0 ;                56
CopyGC: db "CopyGC",0 ;                  57
SetDashes: db "SetDashes",0 ;               58
SetClipRectangles: db "SetClipRectangles",0 ;       59
FreeGC: db "FreeGC",0 ;                  60
ClearArea: db "ClearArea",0 ;               61
CopyArea: db "CopyArea",0 ;                62
CopyPlane: db "CopyPlane",0 ;               63
PolyPoint: db "PolyPoint",0 ;               64
PolyLine: db "PolyLine",0 ;                65
PolySegment: db "PolySegment",0 ;             66
PolyRectangle: db "PolyRectangle",0 ;           67
PolyArc: db "PolyArc",0 ;                 68
FillPoly: db "FillPoly",0 ;                69
PolyFillRectangle: db "PolyFillRectangle",0 ;       70
PolyFillArc: db "PolyFillArc",0 ;             71
PutImage: db "PutImage",0 ;                72
GetImage: db "GetImage",0 ;                73
PolyText8: db "PolyText8",0 ;               74
PolyText16: db "PolyText16",0 ;              75
ImageText8: db "ImageText8",0 ;              76
ImageText16: db "ImageText16",0 ;             77
CreateColormap: db "CreateColormap",0 ;          78
FreeColormap: db "FreeColormap",0 ;            79
CopyColormapAndFree: db "CopyColormapAndFree",0 ;     80
InstallColormap: db "InstallColormap",0 ;         81
UninstallColormap: db "UninstallColormap",0 ;       82
ListInstalledColormaps: db "ListInstalledColormaps",0 ;  83
AllocColor: db "AllocColor",0 ;              84
AllocNamedColor: db "AllocNamedColor",0 ;         85
AllocColorCells: db "AllocColorCells",0 ;         86
AllocColorPlanes: db "AllocColorPlanes",0 ;        87
FreeColors: db "FreeColors",0 ;              88
StoreColors: db "StoreColors",0 ;             89
StoreNamedColor: db "StoreNamedColor",0 ;         90
QueryColors: db "QueryColors",0 ;             91
LookupColor: db "LookupColor",0 ;             92
CreateCursor: db "CreateCursor",0 ;            93
CreateGlyphCursor: db "CreateGlyphCursor",0 ;       94
FreeCursor: db "FreeCursor",0 ;              95
RecolorCursor: db "RecolorCursor",0 ;           96
QueryBestSize: db "QueryBestSize",0 ;           97
QueryExtension: db "QueryExtension",0 ;          98
ListExtensions: db "ListExtensions",0 ;          99
ChangeKeyboardMapping: db "ChangeKeyboardMapping",0 ;   100
GetKeyboardMapping: db "GetKeyboardMapping",0 ;      101
ChangeKeyboardControl: db "ChangeKeyboardControl",0 ;   102
GetKeyboardControl: db "GetKeyboardControl",0 ;      103
Bell: db "Bell",0 ;                    104
ChangePointerControl: db "ChangePointerControl",0 ;    105
GetPointerControl: db "GetPointerControl",0 ;       106
SetScreenSaver: db "SetScreenSaver",0 ;          107
GetScreenSaver: db "GetScreenSaver",0 ;          108
ChangeHosts: db "ChangeHosts",0 ;             109
ListHosts: db "ListHosts",0 ;               110
SetAccessControl: db "SetAccessControl",0 ;        111
SetCloseDownMode: db "SetCloseDownMode",0 ;        112
KillClient: db "KillClient",0 ;              113
RotateProperties: db "RotateProperties",0 ;        114
ForceScreenSaver: db "ForceScreenSaver",0 ;        115
SetPointerMapping: db "SetPointerMapping",0 ;       116
GetPointerMapping: db "GetPointerMapping",0 ;       117
SetModifierMapping: db "SetModifierMapping",0 ;      118
GetModifierMapping: db "GetModifierMapping",0 ;      119
NoOperation: db "NoOperation",0 ;             127
name_expansion:
  times 200 db 0
name_expansion_ptr: dd name_expansion ;moved by query_extension reply
next_name_ptr:	dd 0		;set to end by query_extension call
                                ;only set if query in process
query_extension_seq: dd 0	;always set to sequence# of current pkt

_CreateWindow: db 0,0	;            1
_ChangeWindowAttributes: db 0,0	;  2
_GetWindowAttributes: db 0,0	;     3
_DestroyWindow: db 0,0	;           4
_DestroySubwindows: db 0,0	;       5
_ChangeSaveSet: db 0,0	;           6
_ReparentWindow: db 0,0	;          7
_MapWindow: db 0,0	;               8
_MapSubwindows: db 0,0	;           9
_UnmapWindow: db 0,0	;             10
_UnmapSubwindows: db 0,0	;         11
_ConfigureWindow: db 0,0	;         12
_CirculateWindow: db 0,0	;         13
_GetGeometry: db 0,0	;             14
_QueryTree: db 0,0	;               15
_InternAtom: db 0,0	;              16
_GetAtomName: db 0,0	;             17
_ChangeProperty: db 0,0	;          18
_DeleteProperty: db 0,0	;          19
_GetProperty: db 0,0	;             20
_ListProperties: db 0,0	;          21
_SetSelectionOwner: db 0,0	;       22
_GetSelectionOwner: db 0,0	;       23
_ConvertSelection: db 0,0	;        24
_SendEvent: db 0,0	;               25
_GrabPointer: db 0,0	;             26
_UngrabPointer: db 0,0	;           27
_GrabButton: db 0,0	;              28
_UngrabButton: db 0,0	;            29
_ChangeActivePointerGrab: db 0,0	; 30
_GrabKeyboard: db 0,0	;            31
_UngrabKeyboard: db 0,0	;          32
_GrabKey: db 0,0	;                 33
_UngrabKey: db 0,0	;               34
_AllowEvents: db 0,0	;             35
_GrabServer: db 0,0	;              36
_UngrabServer: db 0,0	;            37
_QueryPointer: db 0,0	;            38
_GetMotionEvents: db 0,0	;         39
_TranslateCoords: db 0,0	;         40
_WarpPointer: db 0,0	;             41
_SetInputFocus: db 0,0	;           42
_GetInputFocus: db 0,0	;           43
_QueryKeymap: db 0,0	;             44
_OpenFont: db 0,0	;                45
_CloseFont: db 0,0	;               46
_QueryFont: db 0,0	;               47
_QueryTextExtents: db 0,0	;        48
_ListFonts: db 0,0	;               49
_ListFontsWithInfo: db 0,0	;       50
_SetFontPath: db 0,0	;             51
_GetFontPath: db 0,0	;             52
_CreatePixmap: db 0,0	;            53
_FreePixmap: db 0,0	;              54
_CreateGC: db 0,0	;                55
_ChangeGC: db 0,0	;                56
_CopyGC: db 0,0	;                  57
_SetDashes: db 0,0	;               58
_SetClipRectangles: db 0,0	;       59
_FreeGC: db 0,0	;                  60
_ClearArea: db 0,0	;               61
_CopyArea: db 0,0	;                62
_CopyPlane: db 0,0	;               63
_PolyPoint: db 0,0	;               64
_PolyLine: db 0,0	;                65
_PolySegment: db 0,0	;             66
_PolyRectangle: db 0,0	;           67
_PolyArc: db 0,0	;                 68
_FillPoly: db 0,0	;                69
_PolyFillRectangle: db 0,0	;       70
_PolyFillArc: db 0,0	;             71
_PutImage: db 0,0	;                72
_GetImage: db 0,0	;                73
_PolyText8: db 0,0	;               74
_PolyText16: db 0,0	;              75
_ImageText8: db 0,0	;              76
_ImageText16: db 0,0	;             77
_CreateColormap: db 0,0	;          78
_FreeColormap: db 0,0	;            79
_CopyColormapAndFree: db 0,0	;     80
_InstallColormap: db 0,0	;         81
_UninstallColormap: db 0,0	;       82
_ListInstalledColormaps: db 0,0	;  83
_AllocColor: db 0,0	;              84
_AllocNamedColor: db 0,0	;         85
_AllocColorCells: db 0,0	;         86
_AllocColorPlanes: db 0,0	;        87
_FreeColors: db 0,0	;              88
_StoreColors: db 0,0	;             89
_StoreNamedColor: db 0,0	;         90
_QueryColors: db 0,0	;             91
_LookupColor: db 0,0	;             92
_CreateCursor: db 0,0	;            93
_CreateGlyphCursor: db 0,0	;       94
_FreeCursor: db 0,0	;              95
_RecolorCursor: db 0,0	;           96
_QueryBestSize: db 0,0	;           97
_QueryExtension: db 0,0	;          98
_ListExtensions: db 0,0	;          99
_ChangeKeyboardMapping: db 0,0	;   100
_GetKeyboardMapping: db 0,0	;      101
_ChangeKeyboardControl: db 0,0	;   102
_GetKeyboardControl: db 0,0	;      103
_Bell: db 0,0	;                    104
_ChangePointerControl: db 0,0	;    105
_GetPointerControl: db 0,0	;       106
_SetScreenSaver: db 0,0	;          107
_GetScreenSaver: db 0,0	;          108
_ChangeHosts: db 0,0	;             109
_ListHosts: db 0,0	;               110
_SetAccessControl: db 0,0	;        111
_SetCloseDownMode: db 0,0	;        112
_KillClient: db 0,0	;              113
_RotateProperties: db 0,0	;        114
_ForceScreenSaver: db 0,0	;        115
_SetPointerMapping: db 0,0	;       116
_GetPointerMapping: db 0,0	;       117
_SetModifierMapping: db 0,0	;      118
_GetModifierMapping: db 0,0	;      119
_NoOperation: db 0,0	;             127

  [section .text]

