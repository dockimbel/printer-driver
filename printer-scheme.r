REBOL [
	Name: 		"Printer Scheme"
	Purpose:	"Printing support library for Windows/UNIX"
	Author:		"Nenad Rakocevic"
	Email:		nr@red-lang.org
	File: 		%printer-scheme.r
	Version:	0.9.2
	Date:		29/09/2008
	Needs: 		[library]
	License:	{
		Copyright (c) 2011, Nenad Rakocevic.
		All rights reserved.
		
		Redistribution and use in source and binary forms, with or without
		modification, are permitted provided that the following conditions are met:
		
		    o Redistributions of source code must retain the above copyright notice,
		    this list of conditions and the following disclaimer.
		
		    o Redistributions in binary form must reproduce the above copyright notice,
		    this list of conditions and the following disclaimer in the documentation
		    and/or other materials provided with the distribution.
		
		    o Neither the name of Nenad Rakocevic nor the names of its contributors may
		    be used to endorse or promote products derived from this software without
		    specific prior written permission.
		
		THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
		ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
		WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
		DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
		ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
		(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
		LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
		ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
		(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
		SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
	}
	History: 	{
		o PS wrapper added, GDI wrapper externalized.
		o Fixed 'end-page command. Now working correctly.
	}
]

gdi-printer-ctx: [
	defs: [
		caps [
			TECHNOLOGY		2
			HORZSIZE		4
			VERTSIZE		6
			HORZRES			8
			VERTRES			10
			LOGPIXELSX		88
			LOGPIXELSY	 	90
			BITSPIXEL 		12
			PDEVICESIZE 	26
			CLIPCAPS 		36
			RASTERCAPS		38
			SIZEPALETTE 	104
			NUMRESERVED 	106
			COLORRES 		108
			PHYSICALWIDTH 	110
			PHYSICALHEIGHT 	111
			PHYSICALOFFSETX 112
			PHYSICALOFFSETY 113
			SCALINGFACTORX 	114
			SCALINGFACTORY 	115
			VREFRESH 		116
			DESKTOPHORZRES	118
			DESKTOPVERTRES	117
			BLTALIGNMENT	119
		]
		dt [
			LEFT 			0
			TOP  			0
			CENTER       	1
			RIGHT        	2
			VCENTER      	4
			BOTTOM       	8
			WORDBREAK    	16
			SINGLELINE   	32
			EXPANDTABS  	64
			TABSTOP      	128
			NOCLIP       	256
			EXTERNALLEADING 512
			CALCRECT     	1024
			NOPREFIX     	2048
			INTERNAL     	4096
			EDITCONTROL  	8192
			PATH_ELLIPSIS   16384
			END_ELLIPSIS 	32768
			MODIFYSTRING 	65536
			RTLREADING   	131072
			WORD_ELLIPSIS 	262144
		]
		pen [
			solid	  		0
			dash			1
			dot				2
			dashdot			3
			dashdotdot		4
			null			5
			insideframe		6
			userstyle		7
			alternate		8

			endcap_round	0
			endcap_square	256
			endcap_flat		512

			join-round		0
			join-bevel		4096
			join-miter		8192
		]
		stock [
			white-brush 	0
			lt-gray-brush 	1
			gray-brush 		2
			dk-gray-brush 	3
			black-brush 	4
			null-brush 		5
			hollow-brush 	5
			white-pen		6
			black-pen		7
			null-pen		8
			system-font		13
			default-palette 15
		]
		printer-enum [
			local 	  		2 
			connections 	4
			remote	  		16
		]
		misc [
			DIB_RGB_COLORS	0
			SRCCOPY			13369376 
			DM_OUT_BUFFER 	2
		]
	]

	kernel32:	load/library %kernel32.dll
	gdi32: 		load/library %gdi32.dll
	user32: 	load/library %user32.dll
	winspool: 	load/library %winspool.drv
;	spoolss:	load/library %spoolss.dll

	; === General API ===

	int: :to-integer

	FORMAT_MESSAGE_FROM_SYSTEM:	   int #{00001000}
	FORMAT_MESSAGE_IGNORE_INSERTS: int #{00000200}
	fmt-msg-flags: 
		FORMAT_MESSAGE_FROM_SYSTEM
		or FORMAT_MESSAGE_IGNORE_INSERTS

	GetLastError: make routine! [
		return: [integer!]
	] kernel32 "GetLastError"

	FormatMessage: make routine! [
		dwFlags		 [integer!]
		lpSource	 [integer!]
		dwMessageId  [integer!]
		dwLanguageId [integer!]
		lpBuffer	 [string!]
		nSize		 [integer!]
		Arguments	 [integer!]
		return:		 [integer!]
	] kernel32 "FormatMessageA"

	; === Printer API ===

	_RECT: make struct! struct-rect: [
		left		[integer!]
		top			[integer!]
		right		[integer!]
		bottom		[integer!]
	] none

	DOC_INFO: make struct! struct-doc-info: [
		[save]
		cbSize			[integer!]
		lpszDocName		[string!]
		lpszOutput		[integer!]
		lpszDatatype 	[integer!]
		fwType			[integer!]
	][0 "test" 0 0 0]

	PRINTER_INFO_4: make struct! [
		pPrinterName	[string!]
		pServerName		[string!]
		Attributes		[integer!]
	] none

	TEXTMETRIC: make struct! struct-text-metric: [
		tmHeight			[long]
		tmAscent			[long]
		tmDescent			[long]
		tmInternalLeading	[long]
		tmExternalLeading	[long]
		tmAveCharWidth		[long]
		tmMaxCharWidth		[long]
		tmWeight			[long]
		tmOverhang			[long]
		tmDigitizedAspectX	[long]
		tmDigitizedAspectY	[long] 
		tmFirstChar			[char]
		tmLastChar			[char]
		tmDefaultChar		[char]
		tmBreakChar			[char]
		tmItalic			[char]
		tmUnderlined		[char]
		tmStruckOut			[char]
		tmPitchAndFamily	[char]
		tmCharSet			[char]
	] none

	BITMAPINFOHEADER: make struct! bih: [
		biSize			[long]
		biWidth			[long]
		biHeight		[long]
		biPlanes		[short]
		biBitCount		[short]
		biCompression	[long] 
		biSizeImage		[long] 
		biXPelsPerMeter	[long] 
		biYPelsPerMeter	[long] 
		biClrUsed		[long] 
		biClrImportant	[long] 
	] none

	BITMAPINFO: make struct! struct-bitmap-info: append copy bih [
		bmiColors		[integer!]
	] none

	GetDefaultPrinter: make routine! [
		pszBuffer	[string!]
		pcchBuffer  [struct! [low [integer!] high [integer!]]]
		return: 	[integer!]
	] winspool "GetDefaultPrinterA"

	OpenPrinter: make routine! [
		pPrinterName [string!]
		phPrinter  	[struct! [ptr [integer!]]]
		pDefault  	[integer!]
		return: 	[integer!]
	] winspool "OpenPrinterA"

	EnumPrinters: make routine! [
		Flags 		[integer!]
		Name 		[integer!]
		Level 		[integer!]
		pPrinterEnum [string!]
		cbBuf 		[integer!]
		pcbNeeded	[struct! [n [integer!]]]
		pcReturned  [struct! [n [integer!]]]
		return: 	[integer!]
	] winspool "EnumPrintersA"

	ClosePrinter: make routine! compose/deep [
		hPrinter	[integer!]
		return: 	[integer!]
	] winspool "ClosePrinter"
	
	WritePrinter: make routine! [
		hPrinter	[integer!]
		pBuf		[string!]
		cbBuf		[integer!]
		pcWritter	[struct! [n [integer!]]]
		return:		[integer!]
	] winspool "WritePrinter"
	
	StartDocPrinter: make routine! compose/deep [
		hPrinter	[integer!]
		level		[integer!]
		lpdi		[struct! [(struct-doc-info)]]
		return: 	[integer!]
	] winspool "StartDocPrinterA"
	
	StartPagePrinter: make routine! [
		hPrinter	[integer!]
		return: 	[integer!]
	] winspool "StartPagePrinter"
	
	EndPagePrinter: make routine! [
		hPrinter	[integer!]
		return: 	[integer!]
	] winspool "EndPagePrinter"
	
	EndDocPrinter: make routine! [
		hPrinter	[integer!]
		return: 	[integer!]
	] winspool "EndDocPrinter"

	StartDoc: make routine! compose/deep [
		hdc			[integer!]
		lpdi		[struct! [(struct-doc-info)]]
		return: 	[integer!]
	] gdi32 "StartDocA"

	StartPage: make routine! [
		hdc			[integer!]
		return: 	[integer!]
	] gdi32 "StartPage"

	EndPage: make routine! [
		hdc			[integer!]
		return: 	[integer!]
	] gdi32 "EndPage"

	EndDoc: make routine! [
		hdc			[integer!]
		return: 	[integer!]
	] gdi32 "EndDoc"

	CreateDC: make routine! [
		lpszDriver	[string!]
		lpszDevice	[string!]
		lpszOutput	[integer!]
		lpInitData	[integer!]
		return: 	[integer!]
	] gdi32 "CreateDCA"

	DeleteDC: make routine! [
		hdc			[integer!]
		return: 	[integer!]
	] gdi32 "DeleteDC"

	TextOut: make routine! [
	  hdc			[integer!]
	  nXStart		[integer!]
	  nYStart		[integer!]
	  lpString		[string!]
	  cbString		[integer!]
	  return: 		[integer!]
	] gdi32 "TextOutA"

	DrawText: make routine! compose/deep [
		hdc			[integer!]
		lpString	[string!]
		nCount		[integer!]
		lpRect		[struct!  [(struct-rect)]] 
		uFormat		[integer!]
		return: 	[integer!]
	] user32 "DrawTextA"

	SetTextColor: make routine! [
		hdc			[integer!]
		crColor		[integer!]
		return: 	[integer!]
	] gdi32 "SetTextColor"

	MoveToEx: make routine! [
		hdc			[integer!]
		X			[integer!]
		Y			[integer!]
		lpPoint		[integer!]
		return: 	[integer!]
	] gdi32 "MoveToEx"

	LineTo: make routine! [
		hdc			[integer!]
		nXEnd		[integer!]
		nYEnd		[integer!]
		return: 	[integer!]
	] gdi32 "LineTo"

	Arc: make routine! [
		hdc			[integer!]
		nLeftRect	[integer!]
		nTopRect	[integer!]
		nRightRect	[integer!]
		nBottomRect	[integer!]
		nXRadial1	[integer!]
		nYRadial1	[integer!]
		nXRadial2	[integer!]
		nYRadial2	[integer!]
		return: 	[integer!]
	] gdi32 "Arc" 

	Pie: make routine! third :Arc gdi32 "Pie" 

	Rectangle: make routine! [
		hdc			[integer!]
		nLeftRect	[integer!]
		nTopRect	[integer!]
		nRightRect	[integer!]
		nBottomRect	[integer!]
		return: 	[integer!]
	] gdi32 "Rectangle"

	CreatePen: make routine! [
		fnPenStyle	[integer!]
		nWidth		[integer!]
		crColor		[integer!]
		return: 	[integer!]
	] gdi32 "CreatePen"

	CreateSolidBrush: make routine! [
		crColor 	[integer!]
		return: 	[integer!]
	] gdi32 "CreateSolidBrush"

	GetDCBrushColor: make routine! [
		hdc			[integer!]
		return: 	[integer!]
	] gdi32 "GetDCBrushColor"

	GetDCPenColor: make routine! [
		hdc			[integer!]
		return: 	[integer!]
	] gdi32 "GetDCPenColor"

	GetTextColor: make routine! [
		hdc			[integer!]
		return: 	[integer!]
	] gdi32 "GetTextColor"

	GetStockObject: make routine! [
		fnObject	[integer!]
		return: 	[integer!]
	] gdi32 "GetStockObject"

	SelectObject: make routine! [
		hdc			[integer!]
		hgdiobj		[integer!]
		return: 	[integer!]
	] gdi32 "SelectObject"

	DeleteObject: make routine! [
		hgdiobj		[integer!]
		return: 	[integer!]
	] gdi32 "DeleteObject"

	StretchDIBits: make routine! compose/deep [
		hdc			[integer!]
		XDest		[integer!]
		YDest		[integer!]
		nDestWidth	[integer!]
		nDestHeight	[integer!]
		XSrc		[integer!]
		YSrc		[integer!]
		nSrcWidth	[integer!]
		nSrcHeight	[integer!]
		lpBits		[string!]
		lpBitsInfo	[struct! [(struct-bitmap-info)]]
		iUsage		[integer!]
		dwRop		[long]
		return: 	[integer!]
	] gdi32 "StretchDIBits"

	CreateFont: make routine! [
		nHeight				[integer!]
		nWidth				[integer!]
		nEscapement			[integer!]
		nOrientation		[integer!]
		fnWeight			[integer!]
		fdwItalic			[integer!]
		fdwUnderline		[integer!]
		fdwStrikeOut		[integer!]
		fdwCharSet			[integer!]
		fdwOutputPrecision	[integer!]
		fdwClipPrecision	[integer!]
		fdwQuality			[integer!]
		fdwPitchAndFamily	[integer!]
		lpszFace			[string!]
		return: 			[integer!]
	] gdi32 "CreateFontA"

	GetTextMetrics: make routine! compose/deep [
		hdc			[integer!]
		lptm		[struct! [(struct-text-metric)]]
		return: 	[integer!]
	] gdi32 "GetTextMetricsA"

	GetDeviceCaps: make routine! [
		hdc		[integer!]
		nIndex	[integer!]
		return: [integer!]
	] gdi32 "GetDeviceCaps"

	; === Helper functions ====

	locals: none

	rect: make struct! _RECT none

	make-null-string!: func [len [integer!]][
		head insert/dup make string! len null len
	]

	get-error-msg: has [out][
		out: make-null-string! 256
		FormatMessage fmt-msg-flags 0 GetLastError 0 out 256 0
		trim/tail out
	]

	try*: func [body [block!] /quiet /local res][
		if all [zero? res: do body not quiet][
			print reduce [mold first body "failed :" get-error-msg]
		]
		res
	]

	to-xdpi: func [v [integer!]][
		to integer! v * locals/caps/LOGPIXELSX / 25.4 * locals/scale/x / 100
	]
	to-ydpi: func [v [integer!]][
		to integer! v * locals/caps/LOGPIXELSY / 25.4 * locals/scale/y / 100
	]

	to-pt-dpi: func [v][
		negate to integer! v * locals/caps/LOGPIXELSY / 72 * locals/scale/y / 100
	]

	to-bgr: func [c [tuple! word!]][
		if word? c [c: get c]	
		(c/3 * 65536) + (c/2 * 256) + c/1
	]

	to-tuple: func [bgr [integer!]][
		to tuple! reduce [
			255 and bgr
			255 and shift bgr 8
			255 and shift bgr 16
		]
	]

	update-obj: func [type [word!] /local obj][
		obj: locals/:type			
		if obj/dirty? [
			if obj/handle [try* [DeleteObject obj/handle]]
			obj/handle: switch type [
				pen	  [CreatePen obj/style to-pt-dpi obj/width to-bgr obj/color]
				brush [CreateSolidBrush to-bgr obj/color]
			]
			SelectObject locals/hDC obj/handle
			obj/dirty?: no
		]
	]

	reset-obj: func [type [word!] /local obj][
		obj: locals/:type
		if obj/handle [		
			SelectObject locals/hDC GetStockObject select defs/stock pick [null-pen null-brush] type = 'pen
			try* [DeleteObject obj/handle]
		]
		obj/handle: none
		obj/dirty?: no
	]

	enum: list: has [out buf flags needed ret cmd pi4 len buf*][
		out: 	make block! 4
		buf: 	make-null-string! 1024
		needed: make struct! [n [integer!]] none
		ret: 	make struct! needed none
		flags: 	defs/printer-enum/local or defs/printer-enum/connections

		try* cmd: [EnumPrinters flags 0 4 buf 1024 needed ret]

		pi4: make struct! PRINTER_INFO_4 none
		len: length? buf*: third pi4
		if 1024 < (ret/n * len) [
			buf: make string! ret/n * len
			try* cmd
		]
		loop ret/n [
			change/part buf* buf at buf len
			ret: second pi4
			repend out ret/1
			append/only out next ret
			poke ret 3 pick [remote local] zero? ret/3 and 64
			buf: at buf len + 1
		]
		buf: none
		new-line/skip out on 2
	]

	init: func [raw? /with prn-name /local len buf size out][
		either prn-name [
			locals/name: prn-name
		][
			size: make struct! [low [integer!] high [integer!]] reduce [128 0]
			try* [GetDefaultPrinter locals/name size]
			clear find locals/name null
		]
		if raw? [
			reset-defaults
			out: make struct! [n [integer!]] none
			try* [OpenPrinter locals/name out 0]
			locals/hPrinter: out/n
			exit
		]
		
		locals/hDC: try* [CreateDC "WINSPOOL" locals/name 0 0]
		; caps => object with rebol-style names
		locals/caps: reduce [
			'LOGPIXELSX 		GetDeviceCaps locals/hDC defs/caps/LOGPIXELSX
			'LOGPIXELSY 		GetDeviceCaps locals/hDC defs/caps/LOGPIXELSY
			'PHYSICALWIDTH		GetDeviceCaps locals/hDC defs/caps/PHYSICALWIDTH
			'PHYSICALHEIGHT		GetDeviceCaps locals/hDC defs/caps/PHYSICALHEIGHT
			'PHYSICALOFFSETX	GetDeviceCaps locals/hDC defs/caps/PHYSICALOFFSETX
			'PHYSICALOFFSETY	GetDeviceCaps locals/hDC defs/caps/PHYSICALOFFSETY
			'HORZRES			GetDeviceCaps locals/hDC defs/caps/HORZRES
			'VERTRES			GetDeviceCaps locals/hDC defs/caps/VERTRES
		]
		if locals/auto-fit?/x = 1 [
			locals/scale/x: to integer! 100 * locals/caps/HORZRES / locals/caps/PHYSICALWIDTH + .5
		]
		if locals/auto-fit?/y = 1 [
			locals/scale/y: to integer! 100 * locals/caps/VERTRES / locals/caps/PHYSICALHEIGHT + .5
		]
		reset-defaults
	]
	
	emit-raw: func [msg [binary!] /local sent][
		sent: make struct! [n [integer!]] none
		try* [WritePrinter locals/hPrinter as-string msg length? msg sent] 
	]
	
	reset-defaults: does [
		clear locals/font-cache
		locals/cur-font: face/font
		locals/pen: copy [
			handle  #[none]
			style	0
			width	1
			color	0.0.0
			color2	0.0.0
			dirty?	#[false]
		]
		locals/brush: copy [
			handle  #[none]
			color	255.255.255
			dirty?	#[false]
		]
		locals/session: [
			started? [#[false] #[false]]
			pages 	 0
			doc-name "no-name"
			raw		 #[false]
		]
		clear locals/pages
		locals/pen/color:   to-tuple GetDCPenColor locals/hDC
		locals/brush/color: to-tuple GetDCBrushColor locals/hDC
		SelectObject locals/hDC GetStockObject defs/stock/null-brush
	]

	draw-image: func [
		img  [image! word!]
		pos  [pair! none!]
		size [pair! none!]
		/local
			data out len pad pad-sz
	][
		if word? img [img: get img]

		;-- RGB->GRB conversion
		data: img
		forall data [change/only data reverse/part data/1 2 2]
		data: img/rgb

		;-- padding each scanline (4 bytes aligned)
		len: 3 * img/size/x
		pad: all [
			not zero? pad-sz: len // 4
			head insert/dup copy #{} null 4 - pad-sz
		]
		out: make string! img/size/y * pad-sz + length? data 
		repeat y img/size/y [
			insert/part tail out at data (y - 1) * len len
			if pad [insert tail out pad]
		]

		BITMAPINFO/biSize: length? third BITMAPINFOHEADER
		BITMAPINFO/biWidth: img/size/x
		BITMAPINFO/biHeight: negate img/size/y
		BITMAPINFO/biPlanes: 1
		BITMAPINFO/biBitCount: 24
; Todo: convert img/size (px) to log.units
		try* [
			StretchDIBits
				locals/hDC
				to-xdpi pos/x
				to-ydpi	pos/y
				to-xdpi to integer! img/size/x * locals/scale/x / 400 ; hacked conversion
				to-ydpi to integer! img/size/y * locals/scale/y / 400 ; hacked conversion
				0 0 img/size/x img/size/y
				out
				BITMAPINFO
				defs/misc/DIB_RGB_COLORS
				defs/misc/SRCCOPY 
		]
	]

	draw-text: func [txt [string!] pos [pair!]][
		try* [TextOut locals/hDC to-xdpi pos/1 to-ydpi pos/2 txt length? txt]
	]

	draw-text-box: func [txt [string!] pos [pair!] sz [pair!] opts [block! none!] /local v][
		rect/left:	 to-xdpi pos/x
		rect/top:	 to-ydpi pos/y
		rect/right:  to-xdpi pos/x + sz/x
		rect/bottom: to-ydpi pos/y + sz/y				
		v: defs/dt/NOPREFIX or defs/dt/EXPANDTABS
		if not all [opts find opts 'no-wrap][v: v or defs/dt/WORDBREAK]
		v: v or any [select defs/dt locals/cur-font/align 0]
		v: v or any [
			either locals/cur-font/valign = 'center [defs/dt/VCENTER][
				select defs/dt locals/cur-font/valign
			]
			0
		]
		try* [DrawText locals/hDC txt -1 rect v]
	]

	draw-line: func [pos [pair!] pos2 [pair!]][
		update-obj 'pen
		try* [MoveToEx locals/hDC to-xdpi pos/x  to-ydpi pos/y 0]
		try* [LineTo   locals/hDC to-xdpi pos2/x to-ydpi pos2/y]
	]
	
	draw-box: func [pos [pair!] pos2 [pair!]][
		update-obj 'pen
		update-obj 'brush			
		try* [Rectangle locals/hDC to-xdpi pos/x to-ydpi pos/y to-xdpi pos2/x to-ydpi pos2/y]
	]

	draw-arc: func [center [pair!] radius [pair!] beg [decimal!] len [decimal!] closed [logic!] /local cmd][
		update-obj 'pen			
		update-obj 'brush
		;beg: beg - 180
		cmd: [
			? 
			locals/hDC
			to-xdpi center/x - radius/x
			to-ydpi center/y - radius/y
			to-xdpi center/x + radius/x
			to-ydpi center/y + radius/y
			to-xdpi to integer! center/x + (radius/x * cosine beg)
			to-ydpi to integer! center/y - (radius/y * sine beg)
			to-xdpi to integer! center/x + (radius/x * cosine beg + len)
			to-ydpi to integer! center/y - (radius/y * sine beg + len)
		]
		poke cmd 1 pick [Pie Arc] to logic! closed
		try* cmd
	]

	set-font: func [obj [word! object!] /local v fnt][
		if any-word? obj [obj: get obj]
		if not fnt: select locals/font-cache obj [
			v: obj/style
			fnt: try* [
				CreateFont
					to-pt-dpi obj/size
					0 0 0
					either any [v = 'bold all [series? v find v 'bold]][700][400]
					either any [v = 'italic all [series? v find v 'italic]][-1][0]
					either any [v = 'underline all [series? v find v 'underline]][-1][0]
					0 0	0 0	0 0
					obj/name
			]	
			repend locals/font-cache [obj fnt]
		]
		try* [SelectObject locals/hDC fnt]
		if locals/cur-font/color <> obj/color [SetTextColor locals/hDC to-bgr obj/color]
		locals/cur-font: obj
	]

	set-pen: func [c1 [tuple! word!] c2 [tuple! none!]][
		locals/pen/color: c1
		if c2 [locals/pen/color2: c2]
		locals/pen/dirty?: yes
	]

	set-fill: func [c1 [tuple! word!]][
		either c1 = 'none [
			printer/reset-obj 'brush
		][
			locals/brush/color: c1
			locals/brush/dirty?: yes
		]
	]

	set-line-width: func [size [integer!]][
		locals/pen/width: size
		locals/pen/dirty?: yes
	]

	get-font-metrics: has [fnt][
		try* [GetTextMetrics locals/hDC TEXTMETRIC]
		TEXTMETRIC
	]

	get-drawable-size: func [/mm /local caps][
		caps: locals/caps
		as-pair 
			either mm [caps/HORZRES * 254 / caps/LOGPIXELSX / 10][caps/HORZRES]
			either mm [caps/VERTRES * 254 / caps/LOGPIXELSY / 10][caps/VERTRES]
	]

	start-doc: func [raw? [logic!] /title name][
		if title [DOC_INFO/lpszDocName: name]
		DOC_INFO/cbSize: length? third DOC_INFO
		
		either raw? [
			try* [StartDocPrinter locals/hPrinter 1 DOC_INFO]
		][
			try* [StartDoc locals/hDC DOC_INFO]
			locals/cur-font: face/font
		]
	]
	start-page: func [raw? [logic!]][
		either raw? [
			try* [StartPagePrinter locals/hPrinter]
		][
			try* [StartPage locals/hDC]
		]
	]
	
	end-page: func [raw? [logic!]][
		either raw? [
			try* [EndPagePrinter locals/hPrinter]
		][
			try* [EndPage locals/hDC]
		]
	]
	
	end-doc: func [raw? [logic!]][
		either raw? [
			try* [EndDocPrinter locals/hPrinter]
		][
			try* [EndDoc locals/hDC]
		]
	]
			
	make-locals: does [
		context [
			hDC: 		none
			hPrinter: 	none
			name: 		make-null-string! 128
			caps: 		none			; printer metrics
			scale: 		100x100			; scaling X and Y factors
			auto-fit?: 	1x1				; auto-scaling in X and Y to fit in drawable area (0x0 disables it)
			font-cache: make hash! 8
			cur-font: 	face/font
			pen: copy [
				handle  #[none]
				style	0
				width	1
				color	0.0.0
				color2	0.0.0
				dirty?	#[false]
			]
			brush: copy [
				handle  #[none]
				color	255.255.255
				dirty?	#[false]
			]
			session: [
				started? [#[false] #[false]]
				pages 	 0
				doc-name "no-name"
				raw 	 #[false]
			]
			pages: make block! 1
		]
	]

	close: func [pl][
		either pl/session/raw [
			try* [ClosePrinter locals/hPrinter]
		][
			SelectObject locals/hDC 0	;-- release last selected handle
			foreach [obj hfnt] locals/font-cache [try* [DeleteObject hfnt]]
			if locals/pen/handle   [try* [DeleteObject locals/pen/handle]]
			if locals/brush/handle [try* [DeleteObject locals/brush/handle]]
			clear locals/font-cache
			try* [DeleteDC locals/hDC]
		]
	]
]

;====================================================================================

ps-printer-ctx: [

	context [
		; -- %addr.r library inlined (author: Romano Paolo Tenca)
		; -- original version: http://www.rebol.org/cgi-bin/cgiwrap/rebol/view-script.r?script=addr.r

		mode: get-modes system:// 'endian
		set 'addr-to-int func [b [binary!] /endian lmode [word!]][
			to integer! either 'little = any [lmode mode][head reverse copy b][b]
		]
		set '& func [b [binary! string! struct!]][
			third make struct! [s [string!]] reduce [either struct? b [third b][b]]
		]
		set 'cast* func [pointer [binary!] type [block!] /local spec n][
			spec: copy/deep [inner [struct! []]]
			n: 1
			if all [integer? type/1 block? type/2][n: type/1 type: type/2]
			loop n [
				either integer? type/1 [
					foreach [size type] type [
						insert/dup tail spec/2/2 reduce ['. reduce [type]] size
					]
				][insert spec/2/2 type]
			]
			spec: make struct! spec none
			change third spec pointer
			spec/inner
		]
	]

	libcups: load/library switch system/version/4 [
		2 [%/usr/lib/libcups.2.dylib]
		4 [%/usr/lib/libcups.so.2]
	]

	cups_option_s: make struct! struct-option-s: [
		name	[string!]
		value	[string!]
	] none

	cups_dest_s: make struct! struct-dest-s: [
		name			[string!]
		instance		[string!]
		is_default		[integer!]
		num_options 	[integer!]
		cups_option_s	[integer!]
	] none

	ppd_size_s: make struct! struct-size-s: [
		marked		[int]
		name1		[decimal!]	; hack : 8 bytes placeholder
		name2		[decimal!]	; hack : 8 bytes placeholder
		name3		[decimal!]	; hack : 8 bytes placeholder
		name4		[decimal!]	; hack : 8 bytes placeholder
		name5		[decimal!]	; hack : 8 bytes placeholder
		name6		[char]		; hack : 1 byte  placeholder
		width		[float]
		length		[float]
		left		[float]
		bottom		[float]
		right		[float]
		top			[float]
	] none

	cupsGetDefault: make routine! [
		return: 	[char*]
	] libcups "cupsGetDefault"

	cupsGetDests: make routine! compose/deep [
		dests		[struct! [dest [char*]]]
		return:		[integer!]
	] libcups "cupsGetDests"

	cupsFreeDests: make routine! [
		num_dests	[integer!]
		dests		[integer!]
	] libcups "cupsFreeDests"

	cupsPrintFile: make routine! [
		name		[string!]
		filename	[string!]
		title		[string!]
		num_options [integer!]
		options		[integer!]
		return: 	[integer!]
	] libcups "cupsPrintFile"

	cupsGetPPD: make routine! [
		name		[string!]
		return:		[string!]
	] libcups "cupsGetPPD"

	ppdOpenFile: make routine! [
		filename	[string!]
		return:		[integer!]
	] libcups "ppdOpenFile"

	ppdPageSize: make routine! compose/deep [
		ppd			[integer!]
		name		[string!]
		return:		[struct! [(struct-size-s)]]
	] libcups "ppdPageSize"

	ppdClose: make routine! [
		ppd			[integer!]
	] libcups "ppdClose"

	header: {%!PS-Adobe-2.0
%%Creator: REBOL Printer scheme
%%Pages: (atend)
%%EndComments
%%BeginSetup
mark
/ISOLatin1Encoding
8#000 1 8#054 {StandardEncoding exch get} for
/minus
8#056 1 8#217 {StandardEncoding exch get} for
/dotlessi
8#301 1 8#317 {StandardEncoding exch get} for
/space /exclamdown /cent /sterling /currency /yen /brokenbar /section
/dieresis /copyright /ordfeminine /guillemotleft /logicalnot /hyphen
/registered /macron /degree /plusminus /twosuperior /threesuperior /acute
/mu /paragraph /periodcentered /cedilla /onesuperior /ordmasculine
/guillemotright /onequarter /onehalf /threequarters /questiondown /Agrave
/Aacute /Acircumflex /Atilde /Adieresis /Aring /AE /Ccedilla /Egrave /Eacute
/Ecircumflex /Edieresis /Igrave /Iacute /Icircumflex /Idieresis /Eth /Ntilde
/Ograve /Oacute /Ocircumflex /Otilde /Odieresis /multiply /Oslash /Ugrave
/Uacute /Ucircumflex /Udieresis /Yacute /Thorn /germandbls /agrave /aacute
/acircumflex /atilde /adieresis /aring /ae /ccedilla /egrave /eacute
/ecircumflex /edieresis /igrave /iacute /icircumflex /idieresis /eth /ntilde
/ograve /oacute /ocircumflex /otilde /odieresis /divide /oslash /ugrave
/uacute /ucircumflex /udieresis /yacute /thorn /ydieresis
/ISOLatin1Encoding where not {256 array astore def} if
cleartomark

/makeISOEncoded
{ findfont /curfont exch def
  /newfont curfont maxlength dict def
  /ISOLatin1 (-ISOLatin1) def
  /curfontname curfont /FontName get dup length string cvs def
  /newfontname curfontname length ISOLatin1 length add string
 dup 0                  curfontname putinterval
 dup curfontname length ISOLatin1   putinterval
  def
  curfont
  { exch dup /FID ne
{ dup /Encoding eq
  { exch pop ISOLatin1Encoding exch }
  if
  dup /FontName eq
  { exch pop newfontname exch }
  if
  exch newfont 3 1 roll put
}
{ pop pop }
ifelse
  }
  forall
  newfontname newfont definefont
} def
/Arial makeISOEncoded pop
/Arial-Bold makeISOEncoded pop
/Arial-Italic makeISOEncoded pop
/Arial-BoldItalic makeISOEncoded pop
/Times-Roman makeISOEncoded pop
/Times-Bold makeISOEncoded pop
/Times-Italic makeISOEncoded pop
/Times-BoldItalic makeISOEncoded pop
/Helvetica makeISOEncoded pop
/Helvetica-Bold makeISOEncoded pop
/Helvetica-Oblique makeISOEncoded pop
/Helvetica-BoldOblique makeISOEncoded pop
/Courier makeISOEncoded pop
/Courier-Bold makeISOEncoded pop
/Courier-Oblique makeISOEncoded pop
/Courier-BoldOblique makeISOEncoded pop

/ushow % linethick lineposition (string) ushow -
{ % underlines text
        % call this (ushow) instead of show when placing text
        % and the text will be underlined.
        % pass line thickness and offset with string
        % ie 0.1 -0.8 (Text) ushow
        % draws a line 0.1 thick and 0.8 below (-0.8) text position
        % ie. 10 10 moveto 0.1 -0.8 (Text) ushow
        gsave
        exch 0 exch rmoveto
        dup stringwidth rlineto
        exch setlinewidth stroke
        grestore
        show
} bind def

/ms {moveto show} bind def

/BX	{ /bx exch def } def
/BY	{ /by exch def } def
/SX	{ /sx exch def } def
/SY	{ /sy exch def } def
/LG	{ /lg exch def } def % linespacing
4 LG 

/left 	{/align 0 def} def
/right 	{/align 1 def} def
/center {/align 2 def} def
left

/aright  {stringwidth pop sx exch sub 0 rmoveto} def
/acenter {stringwidth pop sx exch sub 2 div 0 rmoveto} def

/lineprint {
	bx by y sub moveto
	str lc pc getinterval dup 
	align 1 eq {aright} if
	align 2 eq {acenter} if
	show
	align 0 eq {pop} if
	/y y lg add def
	/lc pc lc add 1 add def
} def

/parashow {
	/str exch def	%-- save argument string
	/c  0 def		%-- cursor index
	/lc 0 def		%-- last line-break index
	/y  0 def		%-- Y coordinate of current line of text
	/pc 0 def		%-- last white-space index
	/ex false def
	{
		{
			/c c 1 add def
			%-- Tail of string reached ?
			str length lc c add eq {
				%-- Last line break ?
				str lc c getinterval stringwidth pop sx ge {
					lineprint /c c pc sub 1 sub def
				} if
				/pc c def
				%-- Show last line
				lineprint
				/ex true def
				exit
			} if
			%-- White space at index lc + c ?
			str lc c add get 32 eq {exit} if
		} loop
		ex {exit} if
		str lc c getinterval stringwidth pop sx ge
		{lineprint /c 0 def} if
		/pc c def
	} loop
} def

%%EndSetup
/DeviceRGB setcolorspace
matrix currentmatrix
/originmat exch def
/umatrix {originmat matrix concatmatrix setmatrix} def
[2.83465 0 0 2.83465 5.05 11.4173] umatrix
%5 1.4173 translate
/Arial-ISOLatin1 3.5 selectfont
1 setlinecap
1 setlinejoin
}

	locals: none
	out: make string! 10'000
	
	to-y-ps: func [y [number!]][297 - y]
	
	update-obj: func [type [word!] /local obj][
		obj: locals/:type			
		if obj/dirty? [
			switch type [
				pen [set-color obj/color]
			]
			obj/dirty?: no
		]
	]

	reset-obj: func [type [word!] /local obj][
		obj: locals/:type
		obj/handle: none
		obj/dirty?: no
	]
	
	set-color: func [c [tuple! word!]][
		if word? c [c: get c]
		repend out [
			mold c/1 / 255 #" " mold c/2 / 255 #" " mold c/3 / 255 " setcolor^/"
		]
	]
	
	move-to: func [pos [pair!]][
		repend out [pos/x #" " pos/y " moveto^/"]
	]
	
	draw-text: func [txt [string!] pos [pair!]][
		insert tail out "gsave newpath^/"
		pos/y: (to-y-ps pos/y) - 3
		repend out [#"(" txt ") " pos/x #" " pos/y " ms^/grestore^/"]
	]
	
	draw-text-box: func [txt [string!] pos [pair!] sz [pair!]][
		insert tail out "gsave newpath^/"
		insert tail out mold locals/cur-font/align
		insert tail out newline
		pos/y: (to-y-ps pos/y) - 3
		move-to pos
		repend out [
			sz/x " SX " sz/y " SY " pos/x " BX " pos/y " BY^/"
			#"(" txt ") parashow^/grestore^/"
		]
	]
	
	draw-line: func [pos [pair!] pos2 [pair!]][
		insert tail out "gsave newpath^/"
		pos/y: to-y-ps pos/y 
		pos2/y: to-y-ps pos2/y 
		move-to pos
		repend out [
			pos2/x #" " pos2/y " lineto^/"
			"stroke^/grestore^/"
		]
	]
	
	draw-arc: func [pos [pair!] rad [pair!] c1 [decimal!] c2 [decimal!] opts /local arc fill?][
		insert tail out "gsave newpath^/"
		pos/y: to-y-ps pos/y
		c2: c1 + c2
		if rad/x <> rad/y [				
			if zero? rad/y [rad/y: 1]
			repend out [							; !! Not working !!
				1 #" " rad/x / rad/y " scale^/"
			]
		]
		arc: [
			pos/x #" " pos/y #" " rad/x #" " c1 #" " c2 " arc^/"
			pick ["fill^/" "stroke^/"] fill?
		]
		update-obj 'pen
		either not opts [
			fill?: no
			repend out arc					;-- draw arc
		][
			if fill?: locals/fill/active? [set-color locals/fill/color]
			move-to pos
			repend out arc					;-- fill pie
			if all [fill? locals/pen/color <> locals/fill/color][
				set-color locals/pen/color
				move-to pos
				fill?: no
				repend out arc				;-- draw pie edges
			]
			move-to pos
			repend out [					;-- close pie
				pos/x + (rad/x * cosine c2) 
				#" "
				pos/y + (rad/y * sine c2)
				" lineto^/stroke^/"
			]
		]
		insert tail out "grestore^/"
	]
	
	draw-box: func [pos [pair!] pos2 [pair!] /local box fill?][
		pos/y: to-y-ps pos/y 
		pos2/y: to-y-ps pos2/y 
		pos2: pos2 - pos
		insert tail out "gsave newpath^/"
		update-obj 'pen
		
		if fill?: locals/fill/active? [set-color locals/fill/color] ; needs to be optimized (calling set-color more lazily)
		move-to pos
		repend out box: [
			pos2/x
			" 0 rlineto^/0 "
			pos2/y
			" rlineto^/"
			negate pos2/x
			" 0 rlineto^/closepath^/"
			pick ["fill^/" "stroke^/"] fill?
			"grestore^/"
		]
		if locals/pen/color <> locals/fill/color [
			insert tail out "gsave newpath^/"
			set-color locals/pen/color
			move-to pos
			fill?: no
			repend out box
		]
	]
	
	draw-image: func [img [image! word!] pos [pair! none!] pos2 [pair! none!]][
		if word? img [img: get img]
		pos/y: to-y-ps pos/y
		repend out [
			"gsave newpath^/"
			pos/x #" " pos/y " translate^/"
			img/size/x / 4 #" " img/size/x / 4 " scale^/"
		 	"<<^/^-/ImageType 1^/"
		 	"^-/Width " img/size/x " /Height " img/size/y
			"^/^-/BitsPerComponent 8^/"
			"^-/Decode [0 1 0 1 0 1]^/"
			"^-/ImageMatrix ["
				img/size/x " 0 0 "
				negate img/size/x " 0 0"
			"]^/^-/DataSource currentfile /ASCIIHexDecode filter^/"
			">>^/image^/^/"
		]
		trim img: enbase/base img/rgb 16
		until [
			insert/part tail out img 80
			insert tail out #"^/"
			tail? img: skip img 80
		]
		insert tail out ">^/^/"
		insert tail out "grestore^/"
		img: none
	]
	
	set-font: func [obj [object! word!] /local fnt name v m?][
		if any-word? obj [obj: get obj]
		if not find locals/font-cache obj [append locals/font-cache obj]
		fnt: locals/cur-font
		if any [
			obj/name <> fnt/name
			obj/size <> fnt/size
			obj/style <> fnt/style
		][
			name: obj/name
			if name = "Arial" [name: "Helvetica"]
			repend out [
				slash
				uppercase/part lowercase replace/all name #" " #"-" 1
				#"-"
			]
			v: obj/style
			if any [v = 'bold all [series? v find v 'bold]][
				append out "Bold"
				m?: yes
			]
			if any [v = 'italic all [series? v find v 'italic]][
				append out pick ["Oblique" "Italic"] to logic! find [
					"Helvetica" "Courier"
				] name
				m?: yes
			]
			;if any [v = 'underline all [series? v find v 'underline]][]
			either m? [insert tail out #"-"][
				if find name "times" [insert tail out "Times-Roman-"]
			]
			repend out ["ISOLatin1 " 3.5 * obj/size / 10 " selectfont^/"]
		]
		set-color obj/color
		locals/cur-font: obj
	]
	
	set-pen: func [c1 [tuple! word!] c2 [tuple! none!]][
		locals/pen/color: c1
		locals/pen/dirty?: yes
	]
	
	set-fill: func [c1 [tuple! word!]][
		locals/fill/color: c1
		locals/fill/dirty?: yes
		locals/fill/active?: c1 <> 'none
	]
	
	set-line-width: func [sz [integer!]][
		insert tail out sz / 4
		insert tail out " setlinewidth^/" 
	]
	
	enum: has [out dests n new][
		dests: make struct! [dest [char*]] none
		n: cupsGetDests dests
		out: second cast* third dests compose/deep [(n) [(struct-dest-s)]]
		cupsFreeDests n addr-to-int third dests
		new: make block! n
		foreach [a1 a2 a3 a4 a5] out [repend new [a1 reduce [a2 a3 a4 a5]]]
		new-line/skip new on 2
	]

	init: func [raw? /with prn-name /local ppd p][
		all [
			not with
			none? prn-name: cupsGetDefault
			make error! "no default printer"
		]
		locals/name: prn-name
		
		ppd: ppdOpenFile cupsGetPPD prn-name
		p: locals/caps: ppdPageSize ppd "A4"		; Paper size hardcoded for now
		ppdClose ppd
		
		locals/scale/x: to integer! 100 * (p/right - p/left) / p/width + .5
		locals/scale/y: to integer! 100 * (p/top - p/bottom) / p/length + .5
	]
	
	reset-defaults: does [
		clear out
		clear locals/font-cache
		locals/cur-font: face/font
		locals/pen: copy* [
			style	0
			width	1
			color	0.0.0
			color2	0.0.0
			dirty?	#[false]
		]
		locals/fill: copy* [
			active? #[false]
			color	255.255.255
			dirty?	#[false]
		]
		locals/session: [
			started? [#[false] #[false]]
			pages 	0
			doc-name "no-name"
			raw		#[false]
		]
		clear locals/pages
	]
	
	start-doc:	func [/title name][
		if title [locals/session/doc-name: name]
		clear out
		insert tail out header
		repend out [locals/scale/x / 100 " " locals/scale/y / 100 " scale^/"]
	]
	start-page: has [len][
		repend out ["%%Page: " len: length? locals/pages " " len newline]
	]
	end-page: does [
		append out "showpage^/"
	]
	end-doc: has [file][
		file: %/tmp/prn-scheme-tmp.ps
		write file out
		cupsPrintFile locals/name form file locals/session/doc-name 0 0
		delete file
	]
	
	close: does []
	
	make-locals: does [
		context [
			name: none
			;out: none 		; make out buffer local to the port used!!!
			caps: none					; printer metrics
			scale: 100x100				; scaling X and Y factors
			auto-fit?: 1x1				; auto-scaling in X and Y to fit in drawable area (0x0 disables it)
			font-cache: make hash! 16
			cur-font: face/font
			pen: copy* [
				style	0
				width	1
				color	0.0.0
				color2	0.0.0
				dirty?	#[false]
			]
			fill: copy* [
				active? #[false]
				color	255.255.255
				dirty?	#[false]
			]
			session: [
				started? [#[false] #[false]]
				pages 	 0
				doc-name "no-name"
				raw		 #[false]
			]
			pages: make block! 1
		]
	]
]

;====================================================================================

make root-protocol [
	scheme: 'printer

	sw: system/words
	
	open*: 	 	get in sw 'open
	copy*: 	 	get in sw 'copy
	insert*: 	get in sw 'insert
	close*:  	get in sw 'close
	get-modes*: get in sw 'get-modes
	query*:		get in sw 'query
	
	net-log: 	get in net-utils 'net-log

	open-proto: none
	port-flags: system/standard/port-flags/pass-thru
	
	set 'printer context either system/version/4 = 3 [
		ps-printer-ctx: none
		gdi-printer-ctx		
	][
		gdi-printer-ctx: none
		ps-printer-ctx
	]
	
	emit: func [spec [block!] /local pos pos2 txt obj sz opts c1 c2 rad ret][
		ret: parse spec [
			some [
				'text 
					set txt		string!
					set pos		pair! 
					(printer/draw-text txt pos)

				| 'text-box 
					set txt		string!
					set pos		pair!
					set sz		pair!
					opt [set opts block!]
					(printer/draw-text-box txt pos sz opts opts: none)

				| 'line 
					set pos 	pair!
					set pos2 	pair! 
					(printer/draw-line pos pos2)

				| 'box 
					set pos 	pair!
					set pos2 	pair! 
					(printer/draw-box pos pos2)

				| 'arc
					set	pos 	pair!
					set rad 	pair!
					set c1		[decimal! | integer!]
					set c2 		[decimal! | integer!]
					['closed (opts: yes) | none]
					(printer/draw-arc pos rad to decimal! c1 to decimal! c2 to-logic opts opts: none)

				| 'font 
					set obj [word! | object!] 
					(printer/set-font obj)

				| 'pen 
					set c1 [tuple! | word!]
					[set c2 tuple! | none]
					(printer/set-pen c1 c2 c2: none)

				| 'fill-pen
					set c1 [tuple! | word!]
					(printer/set-fill c1)

				| 'line-width
					set sz integer!
					(printer/set-line-width sz)

				| 'image 
					set obj [image! | word!]
					opt [set pos  [pair!]]
					opt [set pos2 [pair!]]
					(printer/draw-image obj pos pos2 pos: pos2: none)

				| skip
			]
		]
		ret
	]

	emit-page: func [spec [block!]][
		printer/start-page
		emit spec
		printer/end-page
		;-- View preview in a window, not very accurate, but works
		;forall spec [if pair? spec/1 [change spec spec/1 * 2.5]]
		;spec: head spec
		;view/new layout compose/deep [
		;	size 800x1000
		;	origin 0x0
		;	backcolor white
		;	box 800x1000 effect [draw [(spec)]]
		;]
	]

	emit-doc: func [spec [block!]][
		printer/start-doc
		printer/emit-page spec
		printer/end-doc
	]
	
	;------- External API -------

	init: func [port spec][		
		if url? spec [net-utils/url-parser/parse-url port spec]
		port/url: spec
		port/locals: printer/make-locals
		port
	]

	open: func [port /local svc psc name raw?][
		printer/locals: port/locals
		port/state/flags: port/state/flags or port-flags

		psc: port/state/custom
		raw?: port/host = "raw"
		
		either all [psc	name: select port/state/custom 'printer][
			printer/init/with raw? name
		][
			printer/init raw?
		]
		if raw? [port/locals/session/raw: yes]
		
		if all [psc name: select psc 'doc-name][
			port/locals/session/doc-name: name
		]
		;port/state/tail: 1 ;-- hack to enable 'remove calls
		port
	]
	
	insert: func  [port spec [word! block!] /local pl direct? raw?][
		pl: printer/locals: port/locals
		raw?: pl/session/raw
		
		if any [
			spec = 'start-doc
			not pl/session/started?/1 
		][
			direct?: yes
			printer/start-doc/title raw? pl/session/doc-name
			pl/session/started?/1: yes
		]
		if any [
			spec = 'start-page
			not pl/session/started?/2 
		][
			printer/start-page raw?
			pl/session/started?/2: yes
			repend/only pl/pages make block! 32
		]
		if block? spec [
			if raw? [make error! "Expected binary value in RAW mode"]
			append last pl/pages spec
			emit spec
		]
		if binary? spec [
			unless raw? [make error! "Expected block value in normal mode"]
			printer/emit-raw spec
		]
		if any [direct?	spec = 'end-page][
			printer/end-page raw?
			pl/session/started?/2: no
		]
		if any [direct? spec = 'end-doc][
			printer/end-doc raw?
			pl/session/started?/1: no
			printer/reset-defaults
		]
		port
	]
	
	query: copy: func [port][
		printer/enum
	]
		
	close: func [port /local pl][
		printer/close printer/locals: port/locals
		port/state/flags: 0
	]
	
	get-modes: func [port spec /local direct?][
		printer/locals: port/locals
		;-- To be done
		if direct? [close port]
	]
	
	set-modes: func [port spec /local swc more? direct?][
		printer/locals: port/locals
		;-- To be done
		if direct? [close port]
	]
		
	net-utils/net-install printer self none
]

text-box: 'text 	;-- hack for backward compatibility with Draw dialect
					;-- TEXT-BOX needs to be emulated in Draw

protect 'printer	;-- printer's low-level functions are exposed through 'printer object
					;-- in case someone want to create a different input dialect
