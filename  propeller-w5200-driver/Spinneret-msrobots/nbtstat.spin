'':::::::[ NetBios Status Query ]::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
{{
''
''AUTHOR:           Michael Sommer (@MSrobots)
''COPYRIGHT:        See LICENCE (MIT)    
''LAST MODIFIED:    10/19/2013
''VERSION:          1.0       
''LICENSE:          MIT (see end of file)
''
''
''DESCRIPTION:
''                  simple NetBios Status Query Form
''                  compile and save output as nbtstat.binary.
''                  rename to nbtstat.psx and save to sd
''                  call in webrowser as nbtstat.psx
''
''MODIFICATIONS:
''10/21/2013        created        
''10/24/2013        added comments
''                  Michael Sommer (MSrobots)
}}
CON
''                                                                                       
''=======[ Global CONstants ]=============================================================


  { PSX/PSE CMDS }    
    
  REQ_PARA_STRING   = 1  ' get Hubaddress of GET parameter (as string)
  REQ_PARA_NUMBER   = 2  ' get Value of GET parameter (as long)
  REQ_FILENAME      = 3  ' get Hubaddress of Request  
  REQ_HEADER_STRING = 4  ' get Hubaddress of HEADER parameter (as string)
  REQ_HEADER_NUMBER = 5  ' get Value of HEADER parameter (as long)
  REQ_POST_STRING   = 6  ' get Hubaddress of POST parameter (as string)
  REQ_POST_NUMBER   = 7  ' get Value of POST parameter (as long)
  
  SEND_FILE_EXT     = 11 ' set FileExtension and content-type for response
  SEND_SIZE_HEADER  = 12 ' send size and HEADER of response to socket (buffered)
  SEND_DATA         = 13 ' send number of bytes to socket (buffered)
  SEND_STRING       = 14 ' send string to socket (buffered)
  SEND_FLUSH        = 15 ' flush buffer to wiznet
  SEND_FILE_CONTENT = 16 ' send content of file to socket (buffered)       
  
  CHANGE_DIRECTORY  = 21 ' change to Directory on SD
  LIST_ENTRIES      = 22 ' list Entries (first/next)
  LIST_ENTRY_ADDR   = 23 ' get Hubaddress of Directory cache Entry (FAT Dir Entry)       
  CREATE_DIRECTORY  = 24 ' create new Directory       
  DELETE_ENTRY      = 25 ' delete File or Directory             
  FILE_WRITE_BLOCK  = 26 ' open file, read block, close file       
  FILE_READ_BLOCK   = 27 ' open file, write block, close file       

  QUERY_DNS         = 41 ' resolves name to ip with DNS
  QUERY_NETBIOS     = 42 ' send NetBios Query
  CHECK_NETBIOS     = 43 ' poll next answer
  
  PSE_CALL          = 91 ' call submodul in new COG and return
  PSE_TRANSFER      = 92 ' call submodul in same COG (DasyChain)

''
''=======[ PUBlic Spin Methods]===========================================================
Pub getPasmADDR
return @cmdin
''
''=======[ Assembly Cog ]=================================================================
Dat
''-------[ Start and Stop ]---------------------------------------------------------------
                        org     0
                        
cmdin                   add     par1ptr,        par            
cmdout                  add     par2ptr,        par            
                        add     par3ptr,        par            
bufptr                  rdlong  bufptr,         par1ptr        ' bufptr - adr of output buffer (1K)

                        call    #main                          ' call usermodule

                        wrlong  zero,           par            ' write exit to cmd mailbox
                        cogid   cmdin                          ' get own cogid
                        cogstop cmdin                          ' and shoot yourself ... done
                        
''-------[ Data IP list ]-----------------------------------------------------------------
ipcount                 long    0
iplist                  long    0,0,0,0,0,0,0,0,0,0

''-------[ Main Program ]-----------------------------------------------------------------
main                    add     postptr,        bufptr         ' now postptr hubadress last 64 bytes outputbuffer
                        mov     rowptr,         bufptr
                        
                        mov     par1,           #"p"           ' get string parameter "p"
                        mov     cmdout,         #REQ_POST_STRING
                        call    #sendspincmd                   ' result is string in par1

                        mov     outptr,         postptr        ' save post content of textbox "p" at end of outputbuffer                
                        call    #strhub2hub                    ' copy p
                        
                        wrbyte  zero,           outptr         ' terminate string
                        
                         ' now done with parameter

                        movd    saveip,         #iplist
                        movs    readip,         #iplist
                        
                        mov     par1,           fileext        ' send file extension
                        mov     cmdout,         #SEND_FILE_EXT
                        call    #sendspincmd                   ' set file ext 

                        mov     par2,           zero           ' clear flag nulti-status 
                        mov     par1,           minusone       ' size ' send packet size unknown
                        mov     cmdout,         #SEND_SIZE_HEADER
                        call    #sendspincmd                   ' send Header and content type/size

                        
                        mov     par1,           postptr        ' send string postptr aka textbox "p"
                        mov     par2,           #0             ' no IP, Name Query
                        mov     cmdout,         #QUERY_NETBIOS
                        call    #sendspincmd                   ' now we have the hub address of the response (ip ist first long) in par1
                        

nextip                  rdlong  tmp,            par1
                        cmp     tmp,            #0 wz
              if_z      jmp     #ipready
                        cmp     ipcount,        #10 wz
              if_z      jmp     #ipready
                        
saveip                  mov     0-0,            tmp            ' now the ip in iplist
                        add     saveip,         incDest1
                        add     ipcount,        #1
                        mov     cmdout,         #CHECK_NETBIOS ' no params
                        call    #sendspincmd                   ' now we have the hub address of the ip in par1
                        jmp     #nextip
ipready
              
readip                  mov     resptr,         0-0            ' now the ip in resptr
                        add     readip,         #1
                        wrlong  resptr,         par3ptr        ' and now the ip in hub param3

                        mov     outptr,         bufptr         ' copy htm
                        movd    cog2hub,        #htm
                        mov     count,          #htm_end-htm              
                        call    #cog2hub                       ' to Output Hub Buffer

                        mov     par1,           par3ptr         ' and now the ip in hub param3 
                        mov     tmp,            #"."           ' output ip at address par1 to outputbuffer
                        mov     outptr,         #(@ip_end-@htm) ' starting from the end. 
                        add     outptr,         bufptr         ' outptr now hub adress of pos in outputbuffer
                        mov     par2,           par1           
                        add     par2,           #3             ' par2 now address of last byte ip
                        rdbyte  par1,           par2           ' read 4.byte of ip             
                        call    #decoutback                    ' output decimal
                        sub     outptr,         #1
                        wrbyte  tmp,            outptr         ' put dot
                        sub     par2,           #1
                        rdbyte  par1,           par2           ' read 3.byte of ip             
                        call    #decoutback                    ' output decimal
                        sub     outptr,         #1
                        wrbyte  tmp,            outptr         ' put dot                         
                        sub     par2,           #1
                        rdbyte  par1,           par2           ' read 2.byte of ip             
                        call    #decoutback                    ' output decimal
                        sub     outptr,         #1
                        wrbyte  tmp,            outptr         ' put dot 
                        sub     par2,           #1
                        rdbyte  par1,           par2           ' read 1.byte of ip             
                        call    #decoutback                    ' output decimal

                        cmp     resptr,         #0 wz          ' is IP zero (null)
        if_nz           jmp     #nbstatquery                   ' no so do it
                                                                 
                        mov     htmptr,         #(@IP_end-@htm)' else
                        add     htmptr,         #(@CNT_zero-@IP_end) '
                        add     htmptr,         bufptr
                        wrbyte  zero,           htmptr         ' terminate htm table with zero
                        call    #sendstringbuf 
                        jmp     #sendfooter                    ' then done

                        
nbstatquery             mov     par1,           postptr        ' send string postptr aka textbox "p"
                        mov     par2,           par3ptr        ' Addr of param3 ... resolved IP in hub so now Status Query
                        mov     cmdout,         #QUERY_NETBIOS
                        call    #sendspincmd                   ' now we have the hub address of the response in par1

                        
                        mov     resptr,         par1           
                        add     resptr,         #56+8          ' resptr  now address of number entrys

                        rdbyte  numentrys,      resptr         ' read number entrys
                        add     resptr,         #1             ' now adr first enrty
                        mov     htmptr,         #(@IP_end-@htm) '  
                        add     htmptr,         bufptr         
                        
                        mov     par1,           numentrys      'output num entrys if first row
                        mov     outptr,         htmptr         ' outptr now hub adress of pos in outputbuffer
                        add     outptr,         #(@CNT_end-@IP_end) ' starting from the end. 
                        call    #decoutback                    ' output decimal

                        add     htmptr,         #(@TDrow-@IP_end) ' start first row 

                        
nextentry                        
                        mov     outptr,         htmptr         ' points to start Name in htm
                        mov     par1,           resptr         ' points to start name in response
                        mov     par2,           #15
                        call    #cnthub2hub

                        add     resptr,         #15            ' points to suffix

                        rdbyte  par1,           resptr         ' get suffix
                        mov     par2,           #2             ' 8 digits
                        add     outptr,         #9+2           ' end next column
                        call    #hextoutback                   ' and output hex
                        add     resptr,         #1             ' points to suffix

                        rdbyte  par1,           resptr         ' get suffix
                        mov     par2,           #2             ' 8 digits
                        add     outptr,         #9+4           ' end next column
                        call    #hextoutback                   ' and output hex

                        add     resptr,         #2
                        add     htmptr,         #(@TDrow_end-@CNT_end) ' move to next row 
                        djnz    numentrys,      #nextentry
                        
                        sub     htmptr,         #(@TDrow-@CNT_zero) ' end last row
                        wrbyte  zero,           htmptr         ' terminate htm table with zero 
                                                               ' 
                        mov     par1,           rowptr         ' now send outputbuffer         
                        mov     cmdout,         #SEND_STRING
                        call    #sendspincmd                   
                        mov     rowptr,         bufptr
                        add     rowptr,         #(@htm2-@htm)
                        djnz    ipcount,        #ipready       'next ip
                        

sendfooter              mov     outptr,         bufptr         ' copy htm footer
                        movd    cog2hub,        #htmfooter
                        mov     count,          #htmfooter_end-htmfooter              
                        call    #cog2hub                       ' to Output Hub Buffer
                        call    #sendstringbuf                 ' now send outputbuffer
                        
main_ret                ret                                    ' done

''-------[ Send Spin Cmds ]---------------------------------------------------------------
{{
''sendspincmd:          call spin cog with command and wait for response
}}                     
sendspincmd             wrlong  par2,           par2ptr        ' write param2 value
                        wrlong  par1,           par1ptr        ' write param1 value
                        wrlong  cmdout,         par            ' write cmd value                        
sendspincmdwait         rdlong  cmdin,          par
                        cmp     cmdin,          cmdout wz
        if_z            jmp     #sendspincmdwait               ' wait for spin
                        rdlong  par1,           par1ptr        ' get answer param1
                        rdlong  par2,           par2ptr        ' get answer param2
sendspincmd_ret         ret

''-------[ Send String bufptr ]-----------------------------------------------------------
{{
''
''sendstringbuf:        sends String from Hub Buffer bufptr to the socket/browser (buffered)
''
''PARMS:              - none   
''  
''RETURNS:            - none
''
}}
sendstringbuf           mov     par1,           bufptr         ' send string from outputbuffer 
                        mov     cmdout,         #SEND_STRING
                        call    #sendspincmd                   
sendstringbuf_ret       ret
''-------[ Copy Cog to Hub ]--------------------------------------------------------------
{{
''
''cog2hub:              copy count longs from Cog to Hub
''
''PARMS:
''  cog2hub           - use "movd cog2hub, #COGlabel" to set source address in cog
''  count             - number of longs to copy
''  outptr            - hubaddress destination
''  
''RETURNS:            - none - outptr get incremented accordingly (by 4 each long)
''
}}
cog2hub                 wrlong  0-0,            outptr
                        add     cog2hub,        incDest1
                        add     outptr,         #4
                        djnz    count,          #cog2hub
cog2hub_ret             ret

''-------[ Copy Hub to Hub ]--------------------------------------------------------------
{{
''
''strhub2hub:           copy string size bytes from Hub to Hub. zero will not be copied
''
''PARMS:
''  par1              - hubaddress source
''  outptr            - hubaddress destination
''
''  
''RETURNS:            - none - par1 and outptr get incremented each byte written
''
}}
strhub2hub              rdbyte  tmp,            par1
                        cmp     tmp,            zero wz
              if_z      jmp     #strhub2hub_ret
                        add     par1,           #1
                        wrbyte  tmp,            outptr
                        add     outptr,         #1
                        jmp     #strhub2hub
strhub2hub_ret          ret                                    

{{
''
''cnthub2hub:           copy par2 bytes from Hub to Hub
''
''PARMS:
''  par1              - hubaddress source
''  par2              - number of bytes
''  outptr            - hubaddress destination
''
''RETURNS:            - none - par1 and outptr get incremented each byte
''
}}
cnthub2hub              rdbyte  tmp,            par1
                        add     par1,           #1
                        wrbyte  tmp,            outptr
                        add     outptr,         #1
                        djnz    par2,           #cnthub2hub
cnthub2hub_ret          ret                                    

''-------[ hex out ]-----------------------------------------------------------------------
{{
''
''hextoutback:          outputs par1 as hex. starting at HUBADDRESS outptr with last         
''                      digit, decrementing outptr. so we will output right justified. 
''PARMS:
''  par1              - value to output hex
''  par2              - num digits (8)
''  outptr            - hubaddress after last (rightmost) digit. decremented before write of each digit
''  
''RETURNS:            - none - par1 changed, outptr at pos of first (leftmost) digit
''
}}
                        
hextoutback             sub     outptr,         #1
                        mov     tmp,            par1
                        shr     par1,           #4

                        and     tmp,            #$F
                        cmp     tmp,            #10 wc
        if_c            add     tmp,            #"0"
        if_nc           add     tmp,            #"A"-10
                        wrbyte  tmp,            outptr
                        
                        

                        djnz    par2,           #hextoutback
hextoutback_ret         ret

''-------[ decimal out ]------------------------------------------------------------------
{{
''
''decoutback:           outputs par1 as decimal. starting at HUBADDRESS outptr with last 
''                      digit, decrementing outptr. so we will output right justified.
''PARMS:
''  par1              - value to output decimal
''  outptr            - hubaddress after last (rightmost) digit. decremented before write of each digit
''  
''RETURNS:            - none - par1 unchanged, outptr at pos of first (leftmost) digit
''
}}
decoutback              
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

''-------[ Unsigned Divide ]--------------------------------------------------------------
{{
''
''LNDivide:             Just put the thing you want to divide in the dividend
''                      and the thing you want to divide by in the divisor.
''                      Then the result will appear in the quotient and
''                      the remainder will appear in the dividend.
''PARMS:
''  LNDivideDividend  - value to divide
''  LNDivideDivsor    - value to divide by
''  
''RETURNS:
''  LNDivideQuotient  - value of the result of division
''  LNDivideDividend  - value of the remainder
''
}}
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
''-------[ Data ]-------------------------------------------------------------------------
par1ptr                 long    4                              ' hubaddress of param1
par2ptr                 long    8                              ' hubaddress of param2
par3ptr                 long    12                             ' hubaddress of param3
zero                    long    0
minusone                long    -1
space                   long    32
incDest1                long    1 << 9
fileext                 long
                        byte    "htm",0
postptr                 long    $400 - $10                     ' addr of last 16 bytes buffer

htm                     long
                        byte    "<html><head><title>Test NetBios Status Query</title>"                             
                        byte    "<style type=",34,"text/css",34,">"
                        byte    "table {border-collapse: collapse; border: 1px solid black; cellpadding: 5px;} "
                        byte    "table td, table th {border: 1px solid black; } "
                        byte    "</style></head>", 13, 10
                        byte    "<body><form action=",34,"nbtstat.psx",34," method=",34,"post",34,">"
                        byte    "<table>", 13, 10, "<tr><th colspan=",34,"3",34,">Test NetBios Status Query</th></tr>",13,10
                        byte    "<tr><td>NAME</td><td><input type=",34,"text",34," name=",34,"p",34," /></td>"
                        byte    "<td><input type=",34,"submit",34," name=",34,"submit",34," value=",34,"Submit",34," /></td></tr>",13,10

                        
htm2                    byte    "<tr><td colspan=",34,"2",34,">"
                        byte    " "[15]
IP_end                  byte    "</td><td>"
                        byte    " "[5]
CNT_end                 byte    "</td></tr>",13,10
CNT_zero                byte    "<tr><td>"
TDrow                   byte    " "[15],"</td><td>  </td><td>  "
TDrow_end               byte    "</td></tr>",13,10
                        byte    "<tr><td>"
                        byte    " "[15],"</td><td>  </td><td>  "
                        byte    "</td></tr>",13,10
                        byte    "<tr><td>"
                        byte    " "[15],"</td><td>  </td><td>  "
                        byte    "</td></tr>",13,10
                        byte    "<tr><td>"
                        byte    " "[15],"</td><td>  </td><td>  "
                        byte    "</td></tr>",13,10
                        byte    "<tr><td>"
                        byte    " "[15],"</td><td>  </td><td>  "
                        byte    "</td></tr>",13,10
                        byte    "<tr><td>"
                        byte    " "[15],"</td><td>  </td><td>  "
                        byte    "</td></tr>",13,10
                        byte    "<tr><td>"
                        byte    " "[15],"</td><td>  </td><td>  "
                        byte    "</td></tr>",13,10
                        byte    "<tr><td>"
                        byte    " "[15],"</td><td>  </td><td>  "
                        byte    "</td></tr>",13,10
                        byte    0
htm_end                 long
                        
htmfooter               long
                        byte    "</table></form></body></html>", 13, 10, 0
htmfooter_end           long

                        
''-------[ Variables ]--------------------------------------------------------------------
count                   res     1                              
outptr                  res     1                              ' outptr - adr of current written pos in out-buf
par1                    res     1
par2                    res     1
tmp                     res     1
rowptr                  res     1
resptr                  res     1
htmptr                  res     1
numentrys               res     1
LNDivideBuffer          res     1
LNDivideCounter         res     1
LNDivideDividend        res     1
LNDivideDivsor          res     1
LNDivideQuotient        res     1
                        fit     496
''
''=======[ Documentation ]================================================================
CON                                                     
{{{
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