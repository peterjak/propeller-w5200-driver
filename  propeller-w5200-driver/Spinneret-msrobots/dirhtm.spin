'':::::::[ directory as DataTable ]:::::::::::::::::::::::::::::::::
{{{
AUTHOR: Michael Sommer (@MSrobots)
LAST MODIFIED: 9/1/2013
VERSION 1.0
LICENSE: MIT (see end of file)

DESCRIPTION:
        outputs html page showing directory
        compile and save output as dirhtm.binary.
        rename to dirhtm.psx and save to sd
        call in webrowser as dirhtm.psx[?p=/path] 
        shows root dir without parameter
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
bufptr                  add     par1ptr,        #4      ' adr of output buffer (1K)
outptr                  add     par2ptr,        #8      ' adr of current written pos in out-buf
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
                        byte    "htm",0
c1980                   long    1980
pathptr                 long    $400 - $40      ' last 64 bytes buffer
                        
''-------[ Main Program ]-----------------------------------------------------
main                        
                        mov     usageflag,      zero
                        add     pathptr,        bufptr         ' now pathptr hubadress last 64 bytes buf

getpath                 mov     par1,           #"p"           ' get string parameter "p"
                        mov     cmdout,         #REQ_PARA_STRING
                        call    #sendspincmd                   ' result is string in par1
                        rdbyte  par2,           par1           ' check if string is null
                        cmp     par2,           zero wz        ' if so
              if_z      mov     par1,           zero           '    mark unused
                        cmp     par1,           zero wz        ' path there ?
              if_z      mov     par1,           #"/"           ' if not write "/" 
              if_z      wrlong  par1,           pathptr        '
              if_z      jmp     #parsdone

                        mov     tmp,            par1           ' save ptr
                        mov     cmdout,         #CHANGE_DIRECTORY
                        call    #sendspincmd                   ' change directory
                        
                        'par1 contains err or directory?

                        mov     outptr,         pathptr        ' save path at end of buf                
                        mov     par1,           tmp            ' param back  path 
                        call    #strhub2hub                    ' copy path
                        
                        mov     par1,           outptr         ' check if path ends with "/"
                        sub     par1,           #1
                        rdbyte  par1,           par1
                        cmp     par1,           #"/" wz                               
              if_nz     mov     par1,           #"/"           ' if not 
              if_nz     wrbyte  par1,           outptr         '        add "/"
              if_nz     add     outptr,         #1
                        mov     par1,           zero
                        wrbyte  par1,           outptr         ' terminate string
                        
                         ' now done with parameter
                        
parsdone                mov     par1,           fileext        ' send file extension
                        mov     cmdout,         #SEND_FILE_EXT
                        call    #sendspincmd                   ' set file ext 

                        mov     par2,           zero           ' clear flag nulti-status 
                        mov     par1,           minusone       ' size ' send packet size unknown
                        mov     cmdout,         #SEND_SIZE_HEADER
                        call    #sendspincmd                   ' send Header and content type/size

                        mov     outptr,         bufptr         ' copy header
                        movd    cog2hub,        #htmheader
                        mov     count,          #htmfirstrow-htmheader              
                        call    #cog2hub                       ' to Output Hub Buffer
                        call    #sendstringbuf                 ' send header
                       
tableheader             mov     outptr,         bufptr         ' copy htm table column header
                        movd    cog2hub,        #htmfirstrow   
                        mov     count,          #htmrow-htmfirstrow
                        call    #cog2hub                       ' to Output Hub Buffer
                        call    #sendstringbuf                 ' send table column header
                        
startrows               mov     rownr,          zero
              
                        mov     cmdout,         #LIST_ENTRY_ADR
                        call    #sendspincmd                   
                        mov     entryptr,       par1           ' get ptr to direntrycache
                        
                        mov     par1,           #"W"
                        mov     cmdout,         #LIST_ENTRIES
                        call    #sendspincmd                   ' list first entry
                         
nextrow                 mov     tmp,            par1           ' get ptr to name
                        rdbyte  par1,           par1           ' get first byte
                        cmp     par1,           zero wz        ' test for empty name
              if_z      jmp     #sendfooter                    ' and done with rows

                        mov     outptr,         bufptr         
                        movd    cog2hub,        #htmrow        ' copy empty row
                        mov     count,          #htmfooter-htmrow              
                        call    #cog2hub                       ' to Output Hub Buffer                                    

                        ' now patch values in Output Hub Buffer

                    '    result or= (directoryEntryCache[12] & $10) 
                        mov     outptr,         entryptr       ' 12 is Directory? 
                        add     outptr,         #12            
                        rdbyte  par1,           outptr
                        and     par1,           #$10
                        cmp     par1,           zero      wz     ' zero if no dir
              if_nz     jmp     #writename
                                   
                        mov     outptr,         bufptr         ' if no dir set dir = "0" 
                        add     outptr,         #(@htmdir-@htmrow) ' offset in bytes !
                        mov     par1,           #"0"
                        wrbyte  par1,           outptr         ' write "0" ... no dir
                        
                        mov     outptr,         bufptr         ' if no dir clear linkbuffer
                        add     outptr,         #(@htmfirstlink-@htmrow) ' offset in bytes !
                        mov     par1,           space
                        mov     count,          #15            ' first 15 byte contain link to self
clearnext               wrbyte  par1,           outptr
                        add     outptr,         #1
                        djnz    count,          #clearnext
                                      
writename               mov     par2,           tmp            ' save for link      
                        mov     par1,           tmp                  
                        mov     outptr,         bufptr         ' copy filename to name
                        add     outptr,         #(@htmfirstname-@htmrow) ' offset in bytes !
                        call    #strhub2hub

                        mov     outptr,         bufptr         ' copy path
                        add     outptr,         #(@htmfirstlink-@htmrow) ' offset in bytes !
                        
                        rdbyte  par1,           outptr         ' check first byte
                        cmp     par1,           space wz       ' if space no dir
              if_nz     add     outptr,         #14            ' directory call dirhtm.psm with path

                        mov     cmdin,          outptr         ' tmp storage to check root
                        
                        mov     par1,           pathptr
                        call    #strhub2hub                    ' write path
                      
                        rdbyte  par1,           par2
                        cmp     par1,           #"." wz        ' check for . and .. NO NAMe !
              if_nz     jmp     #linkname                      ' else write link name
              
                        sub     outptr,         #1             ' remove last "/" of path
                        wrbyte  space,          outptr         
                        mov     par1,           par2           ' check for ..
                        add     par1,           #1    
                        rdbyte  par1,           par1
                        cmp     par1,           #"." wz        ' check for .. NO NAMe !
              if_nz     jmp     #getsize                       ' else done go getsize
              
searchparent            sub     outptr,         #1             ' search next /
                        rdbyte  par1,           outptr
                        cmp     par1,           #"/" wz
              if_nz     wrbyte  space,          outptr
              if_nz     jmp     #searchparent

                        cmp     outptr,         cmdin wz, wc   ' tmp storage ... adr parameter
              if_a      wrbyte  space,          outptr                      
                        jmp     #getsize                       ' no link

linkname                mov     par1,           par2           ' name back   htm - link 
                        call    #strhub2hub                    ' write link name
                                                
getsize                 mov     outptr,         entryptr
                        add     outptr,         #28            ' get entry size
                        mov     count,          #4
                        mov     par1,           zero
                                                
readlong                rdbyte  tmp,            outptr
                        or      par1,           tmp
                        ror     par1,           #8
                        add     outptr,         #1
                        djnz    count,          #readlong

                        mov     outptr,         #(@htmlastsize-@htmrow) ' offset in bytes !
                        call    #decoutback                    ' output decimal

                        mov     outptr,         entryptr       ' 16 create 
                        add     outptr,         #16            
                        mov     cmdin,          #(@htmcreated-@htmrow+4) ' offset in bytes !
                        call    #dateout
                        mov     outptr,         entryptr       ' 14 create 
                        add     outptr,         #14            ' get entry time
                        call    #timeout                        

                        mov     outptr,         entryptr       ' 24 mod
                        add     outptr,         #24            ' get entry day/month1
                        mov     cmdin,          #(@htmmodified-@htmrow+4) ' offset in bytes !
                        call    #dateout
                        mov     outptr,         entryptr       ' 22 mod
                        add     outptr,         #22            ' get entry time                        
                        call    #timeout                        
                         
                        mov     outptr,         entryptr       ' 18 acessed just date
                        add     outptr,         #18            ' get entry day/month1
                        mov     cmdin,          #(@htmacessed-@htmrow+4) ' offset in bytes !
                        call    #dateout
                       
                        add     rownr,          #1
                        mov     outptr,         #(@htmlastrownr-@htmrow) ' offset in bytes !
                        mov     par1,           rownr
                        call    #decoutback                    ' output decimal write rownr  

                        call    #sendstringbuf                 ' send row

                        mov     par1,           #"N"
                        mov     cmdout,         #LIST_ENTRIES
                        call    #sendspincmd                   ' list next entry                                                                           
                        jmp     #nextrow                       ' and do it again
                       
sendfooter              mov     outptr,         bufptr         
                        movd    cog2hub,        #htmfooter        ' Transfer footer into hub-buff
                        mov     count,          #htmfooter_end-htmfooter       
sendusageschemaexit     call    #cog2hub                       ' copy footer to Output Hub Buffer
                        call    #sendstringbuf                 ' send footer

                        mov     par2,           #"/"           ' string in par2
                        mov     par1,           par2ptr        ' hubadr par2
                        mov     cmdout,         #CHANGE_DIRECTORY
                        call    #sendspincmd                   ' change directory

main_ret                ret                                    ' done

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
htmheader               long
                        byte    "<html>", 13, 10,"<head>", 13, 10,"<title>Directory</title>",13,10 
                        byte    "<style type=",34,"text/css",34,">"
                        byte    "table {border-collapse: collapse; border: 1px solid black;} "
                        byte    "table td, table th {border: 1px solid black; } "
                        byte    "</style>",13,10 
                        byte    "</head>", 13, 10
                        byte    "<body>", 13, 10,"<table cellpadding=",34,"5px",34,">", 13, 10, 0

htmfirstrow             long
                        byte    "<tr><th>NR</th><th>NAME</th><th>SIZE</th><th>DIR</th><th>CREATE</th><th>MODIFY</th><th>ACCESS</th></tr>",13,10,0
htmrow                  long
                        byte    "<tr>"
                        byte    "<td align=",34,"right",34,">"
                        byte    " "[10] 
htmlastrownr            byte    "</td>"
                        byte    "<td><a href=",34
htmfirstlink            byte    "/dirhtm.psx?p="
                        byte    " "[76] ,34,">"                               
htmfirstname            byte    " "[12]
                        byte    "</a></td>"
                        byte    "<td align=",34,"right",34,">"
                        byte    " "[10]
htmlastsize             byte    "</td>"
                        byte    "<td align=",34,"right",34,">"
htmdir                  byte    "1"
                        byte    "</td>" 
                        byte    "<td>" 
htmcreated              byte    "0000-00-00 00:00:00"
                        byte    "</td>" 
                        byte    "<td>" 
htmmodified             byte    "0000-00-00 00:00:00"
                        byte    "</td>" 
                        byte    "<td>" 
htmacessed              byte    "0000-00-00 00:00:00"
                        byte    "</td>" 
                        byte    "</tr>", 13, 10, 0

htmfooter               long                                                                                                                              
                        byte    "</table></body></html>", 13, 10, 0
htmfooter_end           long
                        
''-------[ Variables ]---------------------------------------------------
cmdin                   res     1
cmdout                  res     1
par1                    res     1
par2                    res     1
usageflag               res     1

rownr                   res     1
tmp                     res     1
entryptr                res     1

LNDivideBuffer          res     1
LNDivideCounter         res     1
LNDivideDividend        res     1
LNDivideDivsor          res     1
LNDivideQuotient        res     1
                        fit     496
                        
CON
{{
 ______________________________________________________________________________________________________________________________
|                                                   TERMS OF USE: MIT License                                                  |                                                            
|______________________________________________________________________________________________________________________________|
|Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    |     
|files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    |
|modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software|
|is furnished to do so, subject to the following conditions:                                                                   |
|                                                                                                                              |
|The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.|
|                                                                                                                              |
|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          |
|WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         |
|COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   |
|ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         |
 ------------------------------------------------------------------------------------------------------------------------------ 
}}