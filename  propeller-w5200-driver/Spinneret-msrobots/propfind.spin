'':::::::[ propfind handler ]:::::::::::::::::::::::::::::::::
{{{
AUTHOR: Michael Sommer (@MSrobots)
LAST MODIFIED: 9/1/2013
VERSION 1.0
LICENSE: MIT (see end of file)

DESCRIPTION:
        handles propfind verb of requests
        compile and save output as propfind.binary.
        rename to propfind.pse and save to sd
       
        .pse files are extension modules and not callable in the webbrowser

}}
''=======[ Global CONstants ]=================================================
CON                                                    
  {{ PSX CMDS }}  
  REQ_PARA_STRING  = 1
  REQ_PARA_NUMBER  = 2
  REQ_FILENAME     = 3
  REQ_HEADER_STRING= 4
  REQ_HEADER_NUMBER= 5
  
  SEND_FILE_EXT    = 11
  SEND_SIZE_HEADER = 12
  SEND_DATA        = 13
  SEND_STRING      = 14
  SEND_FLUSH       = 15
  
  CHANGE_DIRECTORY = 21
  LIST_ENTRIES     = 22
  LIST_ENTRY_ADR   = 23

  PSE_CALL         = 91
  PSE_TRANSFER     = 92

''=======[ PUBlic Spin Methods]===============================================
Pub getPasmADR
return @cmdptr
''=======[ Assembly Cog ]=====================================================
Dat
''-------[ Start and Stop ]----------------------------------------------------
                        org     0
                        
cmdptr                  mov     cmdptr,         par     ' adr of cmd mailbox
par1ptr                 mov     par1ptr,        par     ' adr of param1 mailbox
par2ptr                 mov     par2ptr,        par     ' adr of param2 mailbox
par3ptr                 mov     par3ptr,        par     ' adr of param3 mailbox
par4ptr                 mov     par4ptr,        par     ' adr of param4 mailbox
bufptr                  add     par1ptr,        #4      ' adr of output buffer (1K)
outptr                  add     par2ptr,        #8      ' adr of current written pos in out-buf
entryptr                add     par3ptr,        #12     ' adr of directoryEntryCache
                        add     par4ptr,        #16     ' 
count                   rdlong  bufptr,         par1ptr ' init adress of output buffer

                        call    #main                   ' call usermodule

                        wrlong  zero,           cmdptr  ' write exit to cmd mailbox
                        cogid   cmdin                   ' get own cogid
                        cogstop cmdin                   ' and shoot yourself ... done
                        
''-------[ Send Spin Cmds ]---------------------------------------------------                                     
sendspincmd             wrlong  par2,           par2ptr ' write param2 value
                        wrlong  par1,           par1ptr ' write param1 value
                        wrlong  cmdout,         cmdptr  ' write cmd value                        
sendspincmdwait         rdlong  cmdin,          cmdptr
                        cmp     cmdin,          cmdout wz
        if_z            jmp     #sendspincmdwait        ' wait for spin
                        rdlong  par1,           par1ptr ' get answer param1
                        rdlong  par2,           par2ptr ' get answer param2
sendspincmd_ret         ret

''-------[ data constants ]---------------------------------------------------
zero                    long    0
minusone                long    -1
space                   long    32
incDest1                long    1 << 9
fileext                 long
                        byte    "xml",0
c1980                   long    1980
pathptr                 long    $400 - $40      ' last 64 bytes buffer
deptvalue               long    0
Depth1                  long
                        byte    "Dept"
Depth2                  long
                        byte    "h",0,0,0
                        
'c1319                   long    -1'1319
                        
''-------[ Main Program ]-----------------------------------------------------
main                        
                        
                        add     pathptr,        bufptr         ' now pathptr hubadress last 64 bytes output-buf
                        mov     tmp,            pathptr
                        sub     tmp,            #4
                        wrlong  zero,           tmp            ' write a long zero in front of it (null string in hub used later)

                        mov     par1,           Depth1         ' get long Header "Depth:"
                        mov     par2,           Depth2
                        mov     cmdout,         #REQ_HEADER_NUMBER  ' get Header key numeric value
                        call    #sendspincmd                   ' result is long in par1
                        mov     deptvalue,      par1           ' 0 just dir itself, > zero content also
                        cmp     par2,           #0 wz          ' header there at all?
              if_z      add     deptvalue,      #1             ' no - assume depth 1           
                                 
                        mov     cmdout,         #REQ_FILENAME  ' get string Filename
                        call    #sendspincmd                   ' result is string in par1
                        mov     outptr,         pathptr        ' save path at end of buf                
                        call    #strhub2hub                    ' copy path                        
                        wrbyte  zero,           outptr         ' terminate string
                            
                        sub     outptr,         #1             ' check if path ends with "/"
                        cmp     outptr,         pathptr wz     ' but is not just 1 char ("/")
              if_z      jmp     #changerootdir                 ' --> root
              
                        rdbyte  par1,           outptr         ' now 
                        cmp     par1,           #"/" wz                               
              if_z      wrbyte  zero,           outptr         ' delete trailing "/" if there              
                        mov     tmp,            outptr         ' search next /  backwards to find dirname
findpath                sub     tmp,            #1
                        rdbyte  par1,           tmp
                        cmp     par1,           #"/" wz
              if_nz     jmp     #findpath                      
                        add     tmp,            #1             ' now tmp is at 
                        mov     par1,           tmp            ' start name
                        mov     tmp2,           outptr         ' keep copy
                        mov     outptr,         par3ptr        ' target param3 & param4
                        call    #strhub2hub                    ' copy name
                        wrbyte  zero,           outptr         ' terminate string
                        mov     outptr,         tmp2           ' restore copy                 
                        mov     par1,           pathptr                                          
                        mov     cmdout,         #CHANGE_DIRECTORY
                        call    #sendspincmd                   ' change directory
                        rdbyte  par1,           outptr
                        cmp     par1,           #0 wz
              if_nz     add     outptr,         #1             ' was no trailing "/"
                        mov     par1,           #"/"
                        wrbyte  par1,           outptr         'now add one "/" and
                        add     outptr,         #1 
                        wrbyte  zero,           outptr         ' terminate string
                        mov     tmp,            par3ptr        ' flag file/dirName is in param3 & param4                                 
                        jmp     #parsdone
                        
changerootdir           mov     par1,           pathptr                                          
                        mov     cmdout,         #CHANGE_DIRECTORY
                        call    #sendspincmd                   ' change directory to root
                        mov     tmp,            pathptr        ' flag Name is / ... root
parsdone                mov     par1,           fileext        ' send file extension
                        mov     cmdout,         #SEND_FILE_EXT
                        call    #sendspincmd                   ' set file ext 
                        
                        mov     par2,           #1             ' set flag for multi-status
                        mov     par1,           minusone       ' size ' send packet size unknown
                        mov     cmdout,         #SEND_SIZE_HEADER
                        call    #sendspincmd                   ' send Header and content type/size

                        mov     outptr,         bufptr         ' copy xml header
                        movd    cog2hub,        #xmlheader
                        mov     count,          #xmlres-xmlheader              
                        call    #cog2hub                       ' to Output Hub Buffer
                        call    #sendstringbuf                 ' send xml header
                        
startrows               mov     cmdout,         #LIST_ENTRY_ADR
                        call    #sendspincmd                   
                        mov     entryptr,       par1           ' get ptr to direntrycache

                        cmp     tmp,            pathptr wz     ' check flag if root
              if_z      mov     par1,           pathptr        ' display name of entry is root '/'          
              if_nz     mov     par1,           par3ptr        ' display name of entry is par3ptr (param3 and param4 contain dirname)
                        mov     par2,           pathptr        ' link name of entry
                        sub     par2,           #4             ' is empty ... null string in hub
                          
                        call    #sendxmlrow                    ' send row  par1 disp-name par2 link-name

                        cmp     deptvalue,      #0 wz
              if_z      jmp     #sendfooter                    ' done - just root - no content
                        
                        mov     par1,           #"W"
                        mov     cmdout,         #LIST_ENTRIES
                        call    #sendspincmd                   ' list first entry
                         
nextrow                 mov     tmp,            par1           ' get ptr to name
                        rdbyte  tmp,            tmp            ' get first byte
                        cmp     tmp,            zero wz        ' test for empty name
              if_z      jmp     #sendfooter                    ' and done with rows
              
                        cmp     tmp,            #"." wz        ' check for . and .. NO WEBDAV !
              if_z      jmp     #listnextentry                 ' list next entry

                        mov     par2,           par1           ' use name ptr for for link    
                        call    #sendxmlrow                    ' send row  par1 disp-name par2 link-name

listnextentry           mov     par1,           #"N"
                        mov     cmdout,         #LIST_ENTRIES
                        call    #sendspincmd                   ' list next entry                                                                           
                        jmp     #nextrow                       ' and do it again
                       
sendfooter              mov     outptr,         bufptr         
                        movd    cog2hub,        #xmlfooter     ' Transfer footer into hub-buff
                        mov     count,          #xmlfooter_end-xmlfooter       
                        call    #cog2hub                       ' copy footer to Output Hub Buffer
                        call    #sendstringbuf                 ' send footer

                        mov     par2,           #"/"           ' string in par2
                        mov     par1,           par2ptr        ' hubadr par2
                        mov     cmdout,         #CHANGE_DIRECTORY
                        call    #sendspincmd                   ' change directory

main_ret                ret                                    ' done

''-------[ Send xmlrow ]----------------------------------------------------
'
'sends one directory entry - par1 points to display-name par2 points to link-name
'
sendxmlrow              mov     outptr,         bufptr         
                        movd    cog2hub,        #xmlres        ' copy empty xmlres
                        mov     count,          #xmldirend-xmlres              
                        call    #cog2hub                       ' to Output Hub Buffer                                    

                        ' now patch values in Output Hub Buffer
                                      
                        mov     outptr,         bufptr         ' copy filename to display-name
                        add     outptr,         #(@xmlfirstname-@xmlres) ' offset in bytes !
                        call    #strhub2hub

findlastcharname        sub     outptr,         #1             ' find end of name
                        rdbyte  par1,           outptr
                        cmp     par1,           #" " wz        ' still space?
              if_z      jmp     #findlastcharname
                        add     outptr,         #1             ' terminate name with <
                        mov     par1,           #"<"
                        wrbyte  par1,           outptr

                        mov     outptr,         bufptr         ' copy path  to link
                        add     outptr,         #(@xmlfirstlink-@xmlres) ' offset in bytes !                        

'                        mov     cmdin,          outptr         ' tmp storage to check root
                        
                        mov     par1,           pathptr
                        call    #strhub2hub                    ' write path

                        mov     par1,           par2           ' name back   htm - link    linkname
                        call    #strhub2hub                    ' write link name

findlastcharlink        sub     outptr,         #1             ' find end of link
                        rdbyte  par1,           outptr
                        cmp     par1,           #" " wz        ' still space?
              if_z      jmp     #findlastcharlink

                   '    result or= (directoryEntryCache[12] & $10)
                        mov     isdir,          zero 
                        mov     tmp,            entryptr       ' 12 is Directory? 
                        add     tmp,            #12            
                        rdbyte  par1,           tmp
                        and     par1,           #$10
                        cmp     par1,           zero      wz   ' zero if no dir
              
              if_nz     mov     isdir,          #1             ' is a direcory
              if_nz     rdbyte  par1,           outptr         ' check if already '/'
              if_nz     cmp     par1,           #"/" wz        ' yes - done           
              if_nz     add     outptr,         #1             ' no  - add "/"
              if_nz     mov     par1,           #"/"           
              if_nz     wrbyte  par1,           outptr
              
                        add     outptr,         #1             ' terminate link with <
                        mov     par1,           #"<"
                        wrbyte  par1,           outptr

                        mov     outptr,         entryptr
                        add     outptr,         #28            ' get entry size
                        mov     count,          #4
                        mov     par1,           zero
                                                
readlong                rdbyte  tmp,            outptr
                        or      par1,           tmp
                        ror     par1,           #8
                        add     outptr,         #1
                        djnz    count,          #readlong

                        mov     outptr,         #(@xmllastsize-@xmlres) ' offset in bytes !
                        call    #decoutback                    ' output decimal

                        mov     outptr,         entryptr       ' 16 create 
                        add     outptr,         #16            
                        mov     cmdin,          #(@xmlcreated-@xmlres+4) ' offset in bytes !
                        call    #dateout
                        mov     outptr,         entryptr       ' 14 create 
                        add     outptr,         #14            ' get entry time
                        call    #timeout                        
{
                        mov     outptr,         entryptr       ' 24 mod
                        add     outptr,         #24            ' get entry day/month1
                        mov     cmdin,          #(@xmlmodified-@xmlres+4) ' offset in bytes !
                        call    #dateout
                        mov     outptr,         entryptr       ' 22 mod
                        add     outptr,         #22            ' get entry time                        
                        call    #timeout                        
}
                        call    #sendstringbuf                 ' send start of row

                        mov     outptr,         bufptr         
                        cmp     isdir,          #0 wz          ' zero if no dir
              if_nz     movd    cog2hub,        #xmldirend     ' copy end dir res
              if_nz     mov     count,          #xmlfileend-xmldirend              
              if_z      movd    cog2hub,        #xmlfileend    ' copy end file res
              if_z      mov     count,          #xmlfooter-xmlfileend              
                        call    #cog2hub                       ' to Output Hub Buffer
                                                        
                        call    #sendstringbuf                 ' send end of row

sendxmlrow_ret          ret

''-------[ Send String bufptr ]----------------------------------------------------
'
'sends String from Hub Buffer bufptr to the socket/browser
'
sendstringbuf           mov     par1,           bufptr         ' send string from Output hub-buff 
                        mov     cmdout,         #SEND_STRING
                        call    #sendspincmd                   
sendstringbuf_ret       ret
''-------[ Copy Cog to Hub ]----------------------------------------------------
'
'copy count longs from Cog to Hub
'
cog2hub                 wrlong  0-0,            outptr
                        add     cog2hub,        incDest1
                        add     outptr,         #4
                        djnz    count,          #cog2hub
cog2hub_ret             ret

''-------[ Copy Hub to Hub ]----------------------------------------------------
'
'copy strsize bytes from Hub to Hub
'
strhub2hub              rdbyte  tmp,            par1
                        cmp     tmp,            zero wz
              if_z      jmp     #strhub2hub_ret
                        add     par1,           #1
                        wrbyte  tmp,            outptr
                        add     outptr,         #1
                        jmp     #strhub2hub
strhub2hub_ret          ret                                    
''-------[ time out ]----------------------------------------------------
'  return (directoryEntryCache[23] >> 3)    mod hour
'  return (directoryEntryCache[15] >> 3) create hour
'  return (((directoryEntryCache[23] & $7) << 3) | (directoryEntryCache[22] >> 5)) mod minute
'  return (((directoryEntryCache[15] & $7) << 3) | (directoryEntryCache[14] >> 5))  create  minute
'  return ((directoryEntryCache[22] & $1F) << 1)   mod second
'  return (((directoryEntryCache[14] & $1F) << 1) +  (directoryEntryCache[13] / 100)) create second
'  tmp 23 15     mod 23 create 15
 ' par2 22 14

timeout                 rdbyte  par2,           outptr
                        add     outptr,         #1             ' get entry time
                        rdbyte  tmp,            outptr

                        mov     par1,           tmp            
                        shr     par1,           #3
                        mov     outptr,         cmdin          ' offset in bytes !
                        add     outptr,         #9            
                        call    #decoutback                    ' output decimal hour

                        and     tmp,            #7
                        shl     tmp,            #3
                        mov     par1,           par2
                        shr     par1,           #5
                        or      par1,           tmp
                        mov     outptr,         cmdin          ' offset in bytes !
                        add     outptr,         #12
                        call    #decoutback                    ' output decimal  minutes

                        mov     par1,           par2
                        and     par1,           #$1F
                        shl     par1,           #1
                        mov     outptr,         cmdin          ' offset in bytes !
                        add     outptr,         #15
                        call    #decoutback                    ' output decimal  seconds
timeout_ret             ret

''-------[ date out ]----------------------------------------------------
' return ((directoryEntryCache[25] >> 1) + 1_980) mod year
' return ((directoryEntryCache[19] >> 1) + 1_980)  access year
' return ((directoryEntryCache[17] >> 1) + 1_980)   create year
dateout                 rdbyte  par2,           outptr         ' get entry day/month1
                        add     outptr,         #1             
                        rdbyte  tmp,            outptr         ' get entry month2/year

                        mov     par1,           tmp            ' get entry year 
                        shr     par1,           #1
                        add     par1,           c1980          ' write year
                        mov     outptr,         cmdin          ' offset in bytes !
                        call    #decoutback                    ' output decimal

' return (((directoryEntryCache[25] & $1) << 3) | (directoryEntryCache[24] >> 5)) 
' return (((directoryEntryCache[19] & $1) << 3) | (directoryEntryCache[18] >> 5)) access                      
' return (((directoryEntryCache[17] & $1) << 3) | (directoryEntryCache[16] >> 5))  create month
                        and     tmp,            #1
                        shl     tmp,            #3
                        mov     par1,           par2
                        shr     par1,           #5
                        or      par1,           tmp
                        mov     outptr,         cmdin          ' offset in bytes !
                        add     outptr,         #3
                        call    #decoutback                    ' output decimal  month
                        
' return (directoryEntryCache[24] & $1F) mod day
' return (directoryEntryCache[18] & $1F)  access day                        
' return (directoryEntryCache[16] & $1F) create   day
                        mov     par1,           par2
                        and     par1,           #$1F           ' write day par1  
                        mov     outptr,         cmdin          ' offset in bytes !
                        add     outptr,         #6
                        call    #decoutback                    ' output decimal day
dateout_ret             ret
                            
''-------[ decimal out ]----------------------------------------------------
' outputs par1 as decimal. starting at offset outptr with last num decrementing outptr
decoutback              add     outptr,                 bufptr
                        mov     LNDivideDividend,       par1
decoutloop              sub     outptr,                 #1
                        mov     LNDivideDivsor,         #10
                        call    #LNDivide
                        add     LNDivideDividend,       #48
                        wrbyte  LNDivideDividend,       outptr                        
                        mov     LNDivideDividend,       LNDivideQuotient
                        cmp     LNDivideDividend,       #0 wz
              if_nz     jmp     #decoutloop                        
decoutback_ret          ret

''-------[ Unsigned Divide ]----------------------------------------------------
' Just put the thing you want to divide in the dividend and
' the thing you want to divide by in the divisor.
' Then the result will appear in the quotient and
' the remainder will appear in the dividend

LNDivide                mov     LNDivideQuotient,       #0                           ' Setup to divide.
                        mov     LNDivideBuffer,         #0                           '
                        mov     LNDivideCounter,        #32                          '

                        cmp     LNDivideDivsor,         #0 wz                        ' Clear if dividing by zero.
if_z                    mov     LNDivideDividend,       #0                           '
if_z                    jmp     #LNDivide_ret                                        '
                     
LNDivideLoopPre         shr     LNDivideDivsor,         #1 wc, wz                    ' Align divisor MSB and count size.
                        rcr     LNDivideBuffer,         #1                           '
if_nz                   djnz    LNDivideCounter,        #LNDivideLoopPre             '
                                                  
LNDivideLoopPost        cmpsub  LNDivideDividend,       LNDivideBuffer wc            ' Preform division.
                        rcl     LNDivideQuotient,       #1                           '
                        shr     LNDivideBuffer,         #1                           '
                        djnz    LNDivideCounter,        #LNDivideLoopPost            '
                        
LNDivide_ret            ret                                                          ' Return. Remainder in dividend on exit.
''-------[ Data Constants ]--------------------------------------------------
xmlheader               long
                        byte    "<?xml version=",34,"1.0",34," encoding=",34,"UTF-8",34,"?>"
                        byte    "<D:multistatus xmlns:D=",34,"DAV:",34,">",0
                        
xmlres                  long                                                                                                                              
                        byte    "<D:response>"
                        byte    "<D:href>http://192.168.1.117"
xmlfirstlink            byte    " "[76]
                        byte    " /D:href>"                                     ' "<" is set in code
                        byte    "<D:propstat>"
                        byte    "<D:status>HTTP/1.1 200 OK</D:status>"
                        byte    "<D:prop>"
                        byte    "<D:getcontenttype/>"
                        byte    "<D:getlastmodified>"
xmlmodified             byte    "Thu, 01 Aug 2013 01:17:40 GMT"
                        byte    "</D:getlastmodified>"
                        'byte    "<D:lockdiscovery/>"
                        byte    "<D:ishidden>0</D:ishidden>"
                        'byte    "<D:supportedlock >"
                        'byte    "<D:lockentry>"
                        'byte    "<D:lockscope><D:exclusive/></D:lockscope>"
                        'byte    "<D:locktype><D:write/></D:locktype>"
                        'byte    "</D:lockentry>"
                        'byte    "<D:lockentry>"
                        'byte    "<D:lockscope><D:shared/></D:lockscope>"
                        'byte    "<D:locktype><D:write/></D:locktype>"
                        'byte    "</D:lockentry>"
                        'byte    "</D:supportedlock>"
                        byte    "<D:getetag/>"
                        byte    "<D:displayname>"
xmlfirstname            byte    " "[12]
                        byte    " /D:displayname>"                              ' "<" is set in code   
                        'byte    "<D:getcontentlanguage/>"
                        byte    "<D:creationdate>"
xmlcreated              byte    "2013-01-01T00:00:00"
                        byte    "</D:creationdate>"
                        byte    "<D:getcontentlength>"
                        byte    "0"
                        'byte    "0"[10]
xmllastsize             byte    "</D:getcontentlength>",0

                        
xmldirend               long
                        byte    "<D:iscollection>1</D:iscollection>"
                        byte    "<D:resourcetype><D:collection/></D:resourcetype>"
                        byte    "</D:prop>"
                        byte    "</D:propstat>"
                        byte    "</D:response>",0

xmlfileend              long
                        byte    "<D:iscollection>0</D:iscollection>" 
                        byte    "<D:resourcetype/>"
                        byte    "</D:prop>"
                        byte    "</D:propstat>"
                        byte    "</D:response>",0
 
xmlfooter               long                                                                                                                              
                        byte    "</D:multistatus>", 0
xmlfooter_end           long
 
''-------[ Variables ]---------------------------------------------------
cmdin                   res     1
cmdout                  res     1
par1                    res     1
par2                    res     1
isdir                   res     1

tmp                     res     1
tmp2                    res     1

LNDivideBuffer          res     1
LNDivideCounter         res     1
LNDivideDividend        res     1
LNDivideDivsor          res     1
LNDivideQuotient        res     1
                        fit     496

''
''=======[ Documentation ]================================================================
CON                                                   
{{
This .spin file supports PhiPi's great Spin Code Documenter found at
http://www.phipi.com/spin2html/

You can at any time create a .htm Documentation out of the .spin source.

If you change the .spin file you can (re)create the .htm file by uploading your .spin file
to http://www.phipi.com/spin2html/ and then saving the the created .htm page. 
}}

''
''=======[ MIT License ]==================================================================
CON                                                   
{{{
 ______________________________________________________________________________________
|                            TERMS OF USE: MIT License                                 |                                                            
|______________________________________________________________________________________|
|Permission is hereby granted, free of charge, to any person obtaining a copy of this  |
|software and associated documentation files (the "Software"), to deal in the Software |
|without restriction, including without limitation the rights to use, copy, modify,    |
|merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    |
|permit persons to whom the Software is furnished to do so, subject to the following   |
|conditions:                                                                           |
|                                                                                      |
|The above copyright notice and this permission notice shall be included in all copies |
|or substantial portions of the Software.                                              |
|                                                                                      |
|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   |
|INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         |
|PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    |
|HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF  |
|CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE  |
|OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                         |
|______________________________________________________________________________________|
}} 