  [section .data]
;------------------------------------------------------------------------
help_msg:
 db ' MiniBug key summary',0ah
 db ' ----------------------------------------------',0ah
 db ' g = go              r = reg window  up = code win up',0ah
 db ' s = step (space)    m = memory win  dn = code win down',0ah
 db ' a = add break here  e = stack win   pgup = code pgup',0ah
 db ' c = clear breaks    b = break win   pgdn = code pgdn',0ah
 db ' q = quit                            left = mem win up',0ah
 db '                                     right=mem win down',0ah
 db 0ah
 db 'MiniBug can be started as follows:',0ah
 db '    sbug <file> <Enter>      - loads file for debugging',0ah
 db 0ah
 db 'setting breakpoints:',0ah
 db '  Breakpoints can be set by moving the select highlight',0ah
 db '  then pressing the <a> key.  The arrow keys move selection',0ah
 db 0ah
 db 'scrolling the code window',0ah
 db '  All loaded code and data is scrolled in code window.',0ah
 db '  If code appears as data, then it can be converted to',0ah
 db '  code by toggling a break at location',0ah
 db 0ah
 db 'scrolling the memory window',0ah
 db '  Normally the register window is displayed, to scroll',0ah
 db '  the memory window, first select it with <m>, then',0ah
 db '  use the right and left arrow keys.',0ah
 db 0ah
 db 'testing the target program',0ah
 db '  One instruction can be executed with <s> step command',0ah
 db '  The <g> go command runs program to next breakpoint or',0ah
 db '  till program exits',0ah
 db 0ah
 db 'Action Command descriptions',0ah
 db '---------------------------',0ah
 db 0ah
 db ' g = Go',0ah
 db '     Go (run) application to next breakpoint or exit',0ah
 db 0ah
 db ' s = Step (also space bar)',0ah
 db '     Step (single step) one instruction',0ah
 db 0ah
 db ' a = Add break',0ah
 db '     Toggle breakpoint at select bar location',0ah
 db 0ah
 db ' c = Clear breaks',0ah
 db '     Clear all breakpoints',0ah
 db 0ah
 db ' q = Quit minibug',0ah
 db '     Exit minibug and kill the application',0ah
 db 0ah
 db 'Window Command descriptions',0ah
 db '---------------------------',0ah
 db 0ah
 db ' r = Register window',0ah
 db '     Show register window',0ah
 db 0ah
 db ' m = Memory window',0ah
 db '     Show memory window',0ah
 db 0ah
 db ' e = Stack window',0ah
 db '     Show stack window',0ah
 db 0ah
 db ' b = Break window',0ah
 db '     Show breakpoint window',0ah
 db 0ah
 db 'Viewing Command descriptions',0ah
 db '----------------------------',0ah
 db 0ah
 db ' up = (up arrow) scroll code window up',0ah
 db ' down = (down arrow) scroll code down',0ah
 db ' pgup = (page up) page code window up',0ah
 db ' pgdn = (page dwon) page code down',0ah
 db ' right = (right arrow) scroll memory win up',0ah
 db ' left = (left arrow) scroll memory win down',0ah
help_end:
;------------------------------------------------------------------------
  [section .text]

