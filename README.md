printer-driver
==============

Printer driver for REBOL, supports Windows and UNIX (through CUPS), so it runs fine both on Linux and MacOS X too.

Requirements
------------

You need REBOL/View and /Library component in order to use this driver.

How to use it?
--------------

If you have cloned locally this repository, enter the repo and just do it!

    do %printer-scheme.r
	
Alternatively, you can also install it from network when needed:

    do http://raw.github.com/dockimbel/printer-driver/master/printer-scheme.r

The driver installs a new printer:// scheme. Usage is then pretty simple:

    write printer:// <document>
or

    write/custom printer:// <document> [<options>]
    
    <options> are:
        printer "<name>"	: use a specific printer instead of default one
        doc-name "<title>"  : give a title to the document
        
It is also possible to list all the printers available using:

    printer/enum
    
for example, from the console:

    >> probe printer/enum
    [
        "Samsung ML-1670 Series" [none local]
        "Microsoft XPS Document Writer" [none local]
        "Microsoft Office Document Image Writer" [none local]
        "Lexmark 3500-4500 Series" [none local]
        "Fax" [none local]
        "EcoFax" [none local]
        "Bullzip PDF Printer" [none local]
    ]
    
Note: it would be nicer if we would use `get-modes` on the port to retrieve that instead of tapping directly into the global `printer` context. It's just a few more lines of code, any taker? :-)

The additional block after each string is for storing some flags. `local` or `remote` flags are used to indicate if the printer is locally connected or on a remote computer. You can then use one of the string name reported here as argument to `printer` option described above. Please `copy` this blocks and strings if you need to modify them (it's just an internal data structure exposed).

In order to print multiple pages, or to stream pages to printer one by one, it is possible to manually operate the printer port:

    p: open printer://
	insert p 'start-doc		; declare a new document to print
	
	insert p 'start-page	; open a new page
	insert p page1			; print content of the page 1
	insert p 'end-page		; close page
	
	insert p 'start-page	; open a new page
	insert p page2			; print content of the page 2
	insert p 'end-page		; close page

	insert p 'end-doc		; flush all to printer and close document to print
    close p					; close printer port
    
In case you want to hack something in the driver, you can start by looking at the platform-specific `locals` object!, especially `caps` and `scale` properties:

    p: open printer://
    probe p/locals
    close p

How to create a document to print?
----------------------------------

The format used for describing documents by the printer scheme is the [DRAW](http://www.rebol.com/docs/draw.html) dialect, or rather a subset of it. The following DRAW commands are accepted:

    text
    line
    line-width
    box
    arc
    font
    pen
    fill-pen
    image
   
An addition has been made to the dialect for specifying a custom area of multiple lines of text: 

    text-box <text> <position> <size>
    
    <text>     : string! value, text to print, wrapping on newline markers
    <position> : pair! value, position of left top corner of the text area
    <size>     : pair! value
    
Note: I can't remember why I haven't used the more common `area` word instead of `text-box`...

Simple Example
--------------

    write printer:// [
    	pen blue
    	text 100x100 "Hello World!"
    ]


A complete example can be found in the tests/ folder.

License
-------

[BSD](http://www.opensource.org/licenses/bsd-3-clause) license.


Enjoy!