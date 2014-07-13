REBOL [
	Author: "Nenad Rakocevic/Softinnov"
	Title: "Printer scheme test page"
	Date: 08/09/2008
]

do %../printer-scheme.r

logo-red:  	load read-thru http://static.red-lang.org/red-logo.png
logo-r:   	load read-thru http://www.rebol.com/graphics/reb-logo.gif
logo-win: 	load read-thru http://www.cheyenne-server.org/img/logo-win32.gif
logo-linux: load read-thru http://www.cheyenne-server.org/img/logo-linux.gif
logo-osx: 	load read-thru http://www.cheyenne-server.org/img/logo-osx.gif
logo-dl:	load read-thru http://www.rebol.com/graphics/download276.png

f-normal: make face/font [name: "Arial" size: 10 align: 'left valign: 'top]
f-bold:	  make f-normal  [style: 'bold]
f-line:	  make f-normal  [style: 'underline]
f-italic: make f-normal  [style: 'italic]
f-all:	  make f-normal  [style: [bold italic underline]]
f-right:  make f-normal  [align: 'right]
f-center: make f-normal  [align: 'center]
f-head:   make f-normal  [style: 'bold size: 24 align: 'center]
f-h1: 	  make f-normal	 [style: 'bold size: 11]
f-ired:	  make f-normal  [style: 'italic color: red]
f-blue:	  make face/font [size: 16 style: 'bold color: blue name: "Comic Sans MS"]
f-red:	  make f-blue 	 [color: red name: "Helvetica"]
f-gold:	  make f-blue 	 [color: gold / 1.2 name: "Courier New"]
f-green:  make f-blue 	 [color: green / 1.2 name: "Times New Roman"]

demo-doc: [
	image logo-red 11x10
	image logo-r 165x10
	pen black
	font f-head
	text-box "Printer scheme test page" 10x10 190x15
	line-width 2
	line 10x25 200x25
	
	line-width 1
	font f-h1	
	text "Text support" 10x40
	line 10x45 200x45
	font f-normal
	text "This is normal text" 15x48
	font f-right
	text-box "This is right-aligned text" 15x52 50x4
	pen red
	box 15x52 65x56
	font f-center
	text-box "This is centered text" 15x56 50x4
	box 15x56 65x60
	
	font f-bold	  text "This is bold style" 		90x46
	font f-line   text "This is underline style" 	90x50
	font f-italic text "This is italic style" 		90x54
	font f-all 	  text "This is all styles" 		90x58
	
	font f-normal
	text-box
		"This is a demonstration of the automatic wrapping capability of the TEXT-BOX command using a long line of text."
		15x65 30x30
	box 15x65 45x95
	
	font f-center
	text-box
		"This is a demonstration of the automatic wrapping capability of the TEXT-BOX command using a long line of text."
		60x65 30x30
	box 60x65 90x95
	
	font f-right
	text-box
		"This is a demonstration of the automatic wrapping capability of the TEXT-BOX command using a long line of text."
		105x65 30x30
	box 105x65 135x95
	
	font f-ired
	text "Red rectangles are just drawn to show text bounding boxes" 15x100
	
	font f-blue  text "Comic sans ms" 	150x50
	font f-red   text "Helvetica" 		150x60
	font f-gold  text "Courier New" 	150x70
	font f-green text "Times new roman" 150x80
	
	pen black
	font f-h1	
	text "Drawing support" 10x110
	line 10x115 200x115
	font f-normal
	
	line-width 1 line 10x130 20x120
	line-width 2 line 15x130 25x120
	line-width 3 line 20x130 30x120
	line-width 4 line 25x130 35x120
	
	line-width 1 box 40x120 50x130
	line-width 2 box 55x120 65x130
	line-width 3 box 70x120 80x130
	line-width 4 box 85x120 95x130
	
	fill-pen black
	line-width 1
	box 100x120 110x130
	fill-pen red
	box 115x120 125x130
		
	fill-pen none
	line-width 1 arc 20x145 10x10 180 90
	line-width 2 arc 30x145 10x10 180 90
	line-width 3 arc 40x145 10x10 180 90
	line-width 4 arc 50x145 10x10 180 90

	fill-pen none
	line-width 1 arc 60x145 10x10 180 30 closed
	line-width 2 arc 75x145 10x10 180 60 closed
	line-width 3 arc 90x145 10x10 180 90 closed
	
	line-width 1
	fill-pen black
	arc 105x145 10x10 180 30 closed
	arc 120x145 10x10 180 60 closed
	fill-pen red
	arc 135x145 10x10 180 90 closed
	fill-pen orange
	arc 170x130 10x10 30 330 closed
	line-width 2
	fill-pen white
	arc 175x125 2x2 180 360 closed
	
	pen black
	line-width 1
	font f-h1
	text "Image support" 10x150
	line 10x155 200x155
	font f-normal
	image logo-win 15x165
	image logo-linux 30x165
	image logo-osx 45x165
	image logo-dl 70x165
]

;-- Write to the virtual Bullzip Printer producing a PDF file
;write/custom printer:// demo-doc [printer "Bullzip PDF Printer" doc-name "test-page"]

;write/custom printer:// demo-doc [printer "Canon PS-IPU Color Laser Copier" doc-name "test-page"]

target: switch system/version/4 [
	2 ["CUPS_PDF"]
	4 ["PDF"]
]
;write/custom printer:// demo-doc reduce ['printer target 'doc-name "test-page"]

;-- Write to the default printer
write printer:// demo-doc

quit

;--- View preview (not perfect yet, but better than nothing
spec: demo-doc
forall spec [if pair? spec/1 [change spec spec/1 * 2.6]]
spec: head spec
view layout compose/deep [
	size 636x900
	origin 0x0
	backcolor white
	box 636x900 effect [draw [(spec)]]
]

quit

;-- Testing of step-by-step port mode
p: open/custom printer:// [printer "Bullzip PDF Printer" doc-name "test-page"]
insert p 'start-doc
insert p 'start-page
insert p demo-doc
insert p 'end-page
insert p 'end-doc
close p