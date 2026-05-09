%macro  _eoi	0
	mov	al, 0x20
	out	0x20, al
%endmacro

%macro	_brk	0
	xchg	bx, bx
%endmacro