  [section .data]

reply_table:
  dd EventError,_EventError	;0
  dd EventCmdOK,_EventCmdOK           ;1
 dd  KeyPress, _KeyPress ;                2
 dd  KeyRelease, _KeyRelease ;              3
 dd  ButtonPress, _ButtonPress ;             4
 dd  ButtonRelease, _ButtonRelease ;           5
 dd  MotionNotify, _MotionNotify ;            6
 dd  EnterNotify, _EnterNotify ;             7
 dd  LeaveNotify, _LeaveNotify ;             8
 dd  FocusIn, _FocusIn ;                 9
 dd  FocusOut, _FocusOut ;                10
 dd  KeymapNotify, _KeymapNotify ;            11
 dd  Expose, _Expose ;                  12
 dd  GraphicsExpose, _GraphicsExpose ;          13
 dd  NoExpose, _NoExpose ;                14
 dd  VisibilityNotify, _VisibilityNotify ;        15
 dd  CreateNotify, _CreateNotify ;            16
 dd  DestroyNotify, _DestroyNotify ;           17
 dd  UnmapNotify, _UnmapNotify ;             18
 dd  MapNotify, _MapNotify ;               19
 dd  MapRequest, _MapRequest ;              20
 dd  ReparentNotify, _ReparentNotify ;          21
 dd  ConfigureNotify, _ConfigureNotify ;         22
 dd  ConfigureRequest, _ConfigureRequest ;        23
 dd  GravityNotify, _GravityNotify ;           24
 dd  ResizeRequest, _ResizeRequest ;           25
 dd  CirculateNotify, _CirculateNotify ;         26
 dd  CirculateRequest, _CirculateRequest ;        27
 dd  PropertyNotify, _PropertyNotify ;          28
 dd  SelectionClear, _SelectionClear ;          29
 dd  SelectionRequest, _SelectionRequest ;        30
 dd  SelectionNotify, _SelectionNotify ;         31
 dd  ColormapNotify, _ColormapNotify ;          32
 dd  ClientMessage, _ClientMessage ;           33
 dd  MappingNotify, _MappingNotify ;           34
 dd  LASTEvent, _LASTEvent ;               35      /* must be bigger than any event # */
 dd  unknown,_unknown      ;               36

;event names
EventError db "-EventError",0 	;0
EventCmdOK db "-Event",0            ;1		;reply to event
KeyPress db "-KeyPress",0 ;                2
KeyRelease db "-KeyRelease",0 ;              3
ButtonPress db "-ButtonPress",0 ;             4
ButtonRelease db "-ButtonRelease",0 ;           5
MotionNotify db "-MotionNotify",0 ;            6
EnterNotify db "-EnterNotify",0 ;             7
LeaveNotify db "-LeaveNotify",0 ;             8
FocusIn db "-FocusIn",0 ;                 9
FocusOut db "-FocusOut",0 ;                10
KeymapNotify db "-KeymapNotify",0 ;            11
Expose db "-Expose",0 ;                  12
GraphicsExpose db "-GraphicsExpose",0 ;          13
NoExpose db "-NoExpose",0 ;                14
VisibilityNotify db "-VisibilityNotify",0 ;        15
CreateNotify db "-CreateNotify",0 ;            16
DestroyNotify db "-DestroyNotify",0 ;           17
UnmapNotify db "-UnmapNotify",0 ;             18
MapNotify db "-MapNotify",0 ;               19
MapRequest db "-MapRequest",0 ;              20
ReparentNotify db "-ReparentNotify",0 ;          21
ConfigureNotify db "-ConfigureNotify",0 ;         22
ConfigureRequest db "-ConfigureRequest",0 ;        23
GravityNotify db "-GravityNotify",0 ;           24
ResizeRequest db "-ResizeRequest",0 ;           25
CirculateNotify db "-CirculateNotify",0 ;         26
CirculateRequest db "-CirculateRequest",0 ;        27
PropertyNotify db "-PropertyNotify",0 ;          28
SelectionClear db "-SelectionClear",0 ;          29
SelectionRequest db "-SelectionRequest",0 ;        30
SelectionNotify db "-SelectionNotify",0 ;         31
ColormapNotify db "-ColormapNotify",0 ;          32
ClientMessage db "-ClientMessage",0 ;           33
MappingNotify db "-MappingNotify",0 ;           34
LASTEvent db "-LASTEvent",0 ;               35      /* must be bigger than any event # */
unknown db "-unknown event",0 ;               36

;event handling
_EventError db 0,0 	;0
_EventCmdOK db 0,0            ;1
_KeyPress db 0,0 ;                2
_KeyRelease db 0,0 ;              3
_ButtonPress db 0,0 ;             4
_ButtonRelease db 0,0 ;           5
_MotionNotify db 0,0 ;            6
_EnterNotify db 0,0 ;             7
_LeaveNotify db 0,0 ;             8
_FocusIn db 0,0 ;                 9
_FocusOut db 0,0 ;                10
_KeymapNotify db 0,0 ;            11
_Expose db 0,0 ;                  12
_GraphicsExpose db 0,0 ;          13
_NoExpose db 0,0 ;                14
_VisibilityNotify db 0,0 ;        15
_CreateNotify db 0,0 ;            16
_DestroyNotify db 0,0 ;           17
_UnmapNotify db 0,0 ;             18
_MapNotify db 0,0 ;               19
_MapRequest db 0,0 ;              20
_ReparentNotify db 0,0 ;          21
_ConfigureNotify db 0,0 ;         22
_ConfigureRequest db 0,0 ;        23
_GravityNotify db 0,0 ;           24
_ResizeRequest db 0,0 ;           25
_CirculateNotify db 0,0 ;         26
_CirculateRequest db 0,0 ;        27
_PropertyNotify db 0,0 ;          28
_SelectionClear db 0,0 ;          29
_SelectionRequest db 0,0 ;        30
_SelectionNotify db 0,0 ;         31
_ColormapNotify db 0,0 ;          32
_ClientMessage db 0,0 ;           33
_MappingNotify db 0,0 ;           34
_LASTEvent db 0,0 ;               35      /* must be bigger than any event # */
_unknown  db 0,0  ;               36
