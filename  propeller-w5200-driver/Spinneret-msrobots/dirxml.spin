'':::::::[ directory as DataTable ]:::::::::::::::::::::::::::::::::::::::::::::::::::::::
{{
''
''AUTHOR:           Michael Sommer (@MSrobots)
''COPYRIGHT:        See LICENCE (MIT)    
''LAST MODIFIED:    10/04/2013
''VERSION:          1.0
''LICENSE:          MIT (see end of file)
''
''
''DESCRIPTION:
''                  outputs  XML showing directory
''                  can output XSD xml schema document describing xml DataSet      
''                  compile and save output as dirxml.binary.
''                  rename to dirxml.psx and save to sd
''                  call in webrowser as dirxml.psx[?p=/path]
''                  call in webrowser as dirxml.psx?x=xsd to get xml schema 
''                  shows xml without parameter
''
''MODIFICATIONS:
''10/04/2013        added spindoc comments
''                  Michael Sommer (MSrobots)
}}
CON
''
''=======[ Global CONstants ... ]=========================================================
  { PSX CMDS }  
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
  LIST_ENTRY_ADDR  = 23

  PSE_CALL         = 91
  PSE_TRANSFER     = 92

''
''=======[ PUBlic Spin Methods]===========================================================
Pub getPasmADDR
return @cmdptr
''=======[ Assembly Cog ]=================================================================
Dat
''-------[ Start ]------------------------------------------------------------------------
                        org     0
                        org     0
                        
cmdptr                  mov     cmdptr,         par     ' adr of cmd mailbox
par1ptr                 mov     par1ptr,        par     ' adr of param1 mailbox
par2ptr                 mov     par2ptr,        par     ' adr of param2 mailbox
bufptr                  add     par1ptr,        #4      ' adr of output buffer (1K)
outptr                  add     par2ptr,        #8      ' adr of current written pos in out-buf
count                   rdlong  bufptr,         par1ptr ' init adress of output buffer

''-------[ Main Program ]-----------------------------------------------------------------
                        
usageflag               mov     usageflag,      zero 

par1                    mov     par1,           #"x"           ' get string adr parameter "x"
cmdout                  mov     cmdout,         #REQ_PARA_STRING
par2                    call    #sendspincmd                   ' result is string adress in par1
rownr                   rdbyte  par2,           par1           
entryptr                cmp     par2,           #"x" wz        ' check if first char "x"
LNDivideBuffer if_nz    jmp     #getpath                       ' if not test next param "p"
LNDivideCounter         add     par1,           #1             '    check second char
LNDivideDividend        rdbyte  par2,           par1           '       (xml or xsd)
LNDivideQuotient        cmp     par2,           #"s" wz        '    check if second char "s"
LNDivideDivsor if_z     mov     usageflag,      #1             '    set flag Schema senden
              
getpath                 mov     par1,           #"p"           ' get string parameter "p"
tmp                     mov     cmdout,         #REQ_PARA_STRING
                        call    #sendspincmd                   ' result is string in par1
                        rdbyte  par2,           par1           ' check if string is null
                        cmp     par2,           zero wz        ' if so
              if_z      mov     par1,           zero           '    mark unused
                        cmp     par1,           zero wz        ' path there ?
              if_nz     mov     cmdout,         #CHANGE_DIRECTORY
              if_nz     call    #sendspincmd                   ' change directory
                        
                         ' now done with parameter
                        
parsdone                mov     par1,           fileext        ' send file extension
                        mov     cmdout,         #SEND_FILE_EXT
                        call    #sendspincmd                   ' set file ext 
                        
                        mov     par2,           zero           ' clear flag nulti-status
                        mov     par1,           minusone       ' size ' send packet size unknown
                        mov     cmdout,         #SEND_SIZE_HEADER
                        call    #sendspincmd                   ' send Header and content type/size

                        cmp     usageflag,      #0 wz          ' XML/XSD?
              if_nz     mov     outptr,         bufptr         ' xsd
              if_nz     movd    cog2hub,        #xmlschema     '       copy XML-Schema
              if_nz     mov     count,          #xmlheader-xmlschema
              if_nz     jmp     #sendusageschemaexit           '       send and done

sendXmlHeader           mov     outptr,         bufptr         ' else copy header
                        movd    cog2hub,        #xmlheader
                        mov     count,          #xmlrow-xmlheader              
                        call    #cog2hub                       ' to Output Hub Buffer
                        call    #sendstringbuf                 ' send header
                        
startrows               mov     rownr,          #0
          
                        mov     cmdout,         #LIST_ENTRY_ADDR
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
                        movd    cog2hub,        #xmlrow        ' copy empty row
                        mov     count,          #xmlfooter-xmlrow              
                        call    #cog2hub                       ' to Output Hub Buffer                                    

                        ' now patch values in Output Hub Buffer

                    '    result or= (directoryEntryCache[12] & $10) 
                        mov     outptr,         entryptr       ' 12 is Directory? 
                        add     outptr,         #12            
                        rdbyte  par1,           outptr
                        and     par1,           #$10
                        cmp     par1,           zero      wz     ' zero if no dir
              if_z      mov     outptr,         bufptr         ' if no dir set dir = "0" 
              if_z      add     outptr,         #(@xmldir-@xmlrow) ' offset in bytes !
              if_z      mov     par1,           #"0"
              if_z      wrbyte  par1,           outptr         ' write "0" ... no dir
                       
writename               mov     par1,           tmp            ' get file name in par1            
                        mov     outptr,         bufptr         ' copy filename
                        add     outptr,         #(@xmlfirstname-@xmlrow) ' offset in bytes !
                        call    #strhub2hub
                        

'  bytemove(@result, @directoryEntryCache[28], 4)
'  if(result < 0)
'    result := posx                                               
                        mov     outptr,         entryptr
                        add     outptr,         #28            ' get entry size
                        mov     count,          #4
                        mov     par1,           zero
                                                
readlong                rdbyte  tmp,            outptr
                        or      par1,           tmp
                        ror     par1,           #8
                        add     outptr,         #1
                        djnz    count,          #readlong

                        mov     outptr,         #(@xmllastsize-@xmlrow) ' offset in bytes !
                        call    #decoutback                    ' output decimal ' write size

                        mov     outptr,         entryptr       ' 16 create 
                        add     outptr,         #16            
                        mov     cmdin,          #(@xmlcreated-@xmlrow+4) ' offset in bytes !
                        call    #dateout
                        mov     outptr,         entryptr       ' 14 create 
                        add     outptr,         #14            ' get entry time
                        call    #timeout                        

                        mov     outptr,         entryptr       ' 24 mod
                        add     outptr,         #24            ' get entry day/month1
                        mov     cmdin,          #(@xmlmodified-@xmlrow+4) ' offset in bytes !
                        call    #dateout
                        mov     outptr,         entryptr       ' 22 mod
                        add     outptr,         #22            ' get entry time                        
                        call    #timeout                        
                         
                        mov     outptr,         entryptr       ' 18 acessed just date
                        add     outptr,         #18            ' get entry day/month1
                        mov     cmdin,          #(@xmlacessed-@xmlrow+4) ' offset in bytes !
                        call    #dateout
                                                                                                     
                        add     rownr,          #1
                        mov     outptr,         #(@xmllastrownr-@xmlrow) ' offset in bytes !
                        mov     par1,           rownr          ' write rownr 
                        call    #decoutback                    ' output decimal  rownr
                       
                        call    #sendstringbuf                 ' send row

                        mov     par1,           #"N"
                        mov     cmdout,         #LIST_ENTRIES
                        call    #sendspincmd                   ' list next entry                                                                          
                        jmp     #nextrow                       ' and do it again
                       
sendfooter              mov     outptr,         bufptr         
                        movd    cog2hub,        #xmlfooter        ' Transfer footer into hub-buff
                        mov     count,          #xmlfooter_end-xmlfooter       
sendusageschemaexit     call    #cog2hub                       ' copy footer to Output Hub Buffer
                        call    #sendstringbuf                 ' send footer

                        mov     par2,           #"/"           ' string in par2
                        mov     par1,           par2ptr        ' hubadr par2
                        mov     cmdout,         #CHANGE_DIRECTORY
                        call    #sendspincmd                   ' change directory

main_end                                                       ' done

''-------[ Stop ]-------------------------------------------------------------------------

                        wrlong  zero,           cmdptr  ' write exit to cmd mailbox
                        cogid   cmdin                   ' get own cogid
                        cogstop cmdin                   ' and shoot yourself ... done
                        
''-------[ Send Spin Cmds ]---------------------------------------------------------------
{{
''sendspincmd:          call spin cog with command and wait for response
}}                     
sendspincmd             wrlong  par2,           par2ptr ' write param2 value
                        wrlong  par1,           par1ptr ' write param1 value
                        wrlong  cmdout,         cmdptr  ' write cmd value                        
sendspincmdwait         rdlong  cmdin,          cmdptr
                        cmp     cmdin,          cmdout wz
        if_z            jmp     #sendspincmdwait        ' wait for spin
                        rdlong  par1,           par1ptr ' get answer param1
                        rdlong  par2,           par2ptr ' get answer param2
sendspincmd_ret         ret

''-------[ data constants ]---------------------------------------------------------------
zero                    long    0
minusone                long    -1
space                   long    32
incDest1                long    1 << 9
fileext                 long
                        byte    "xml",0
c1980                   long    1980
                        

''-------[ Send String bufptr ]-----------------------------------------------------------
{{
''sendstringbuf:        sends String from Hub Buffer bufptr to the socket/browser
}}
sendstringbuf           mov     par1,           bufptr         ' send string from Output hub-buff 
                        mov     cmdout,         #SEND_STRING
                        call    #sendspincmd                   
sendstringbuf_ret       ret
''-------[ Copy Cog to Hub ]--------------------------------------------------------------
{{
''cog2hub:              copy count longs from Cog to Hub
}}
cog2hub                 wrlong  0-0,            outptr
                        add     cog2hub,        incDest1
                        add     outptr,         #4
                        djnz    count,          #cog2hub
cog2hub_ret             ret

''-------[ Copy Hub to Hub ]--------------------------------------------------------------
{{
''strhub2hub:           copy strsize bytes from Hub to Hub
}}
strhub2hub              rdbyte  tmp,            par1
                        cmp     tmp,            zero wz
              if_z      jmp     #strhub2hub_ret
                        add     par1,           #1
                        wrbyte  tmp,            outptr
                        add     outptr,         #1
                        jmp     #strhub2hub
strhub2hub_ret          ret
''-------[ time out ]---------------------------------------------------------------------
{{
''timeout:              Decodes FAT time value to string
}}
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

''-------[ date out ]---------------------------------------------------------------------
{{
''dateout:              Decodes FAT date value to string
}}
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
                            
''-------[ decimal out ]------------------------------------------------------------------
{{
''decoutback:           outputs par1 as decimal. starting at offset outptr with last 
''                      digit, decrementing outptr
}}
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

''-------[ Unsigned Divide ]--------------------------------------------------------------
{{
''LNDivide:             Just put the thing you want to divide in the dividend
''                      and the thing you want to divide by in the divisor.
''                      Then the result will appear in the quotient and
''                      the remainder will appear in the dividend.
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
''-------[ Data Constants ]---------------------------------------------------------------
xmlschema               long
                        byte    "<?xml version=",34,"1.0",34,"?>",13,10,"<xs:schema id=",34
                        byte    "ds"                        
                        byte    34," xmlns=",34,34," xmlns:xs=",34,"http://www.w3.org/2001/XMLSchema",34," xmlns:msdata=",34,"urn:schemas-microsoft-com:xml-msdata",34,"><xs:element name=",34                        
                        byte    "ds"                        
                        byte    34," msdata:IsDataSet=",34,"true",34, " msdata:UseCurrentLocale=",34,"true",34,"><xs:complexType><xs:choice minOccurs=",34,"0",34," maxOccurs=",34,"unbounded",34,"><xs:element name=",34                       
                        byte   "dt"
                        byte    34,"><xs:complexType><xs:sequence>"
                        byte    "<xs:element name=",34,"nr",34," type=",34,"xs:integer",34," minOccurs=",34,"0",34," />"
                        byte    "<xs:element name=",34,"name",34," type=",34,"xs:string",34," minOccurs=",34,"0",34," />"
                        byte    "<xs:element name=",34,"size",34," type=",34,"xs:integer",34," minOccurs=",34,"0",34," />"
                        byte    "<xs:element name=",34,"dir",34," type=",34,"xs:integer",34," minOccurs=",34,"0",34," />"
                        byte    "<xs:element name=",34,"create",34," type=",34,"xs:dateTime",34," minOccurs=",34,"0",34," />"
                        byte    "<xs:element name=",34,"modify",34," type=",34,"xs:dateTime",34," minOccurs=",34,"0",34," />"
                        byte    "<xs:element name=",34,"access",34," type=",34,"xs:dateTime",34," minOccurs=",34,"0",34," />"
                        byte    "</xs:sequence></xs:complexType></xs:element></xs:choice></xs:complexType></xs:element></xs:schema>"
                        byte    0

xmlheader               long
                        byte    "<?xml version=",34,"1.0",34,"?>",13,10,"<ds>", 0

xmlrow                  long
                        byte    "<dt>"
                        byte    "<nr>"
                        byte    " "[10] 
xmllastrownr            byte    "</nr>"
                        byte    "<name>"
xmlfirstname            byte    " "[12]    
                        byte    "</name>"
                        byte    "<size>"
                        byte    " "[10] 
xmllastsize             byte    "</size>"
                        byte    "<dir>"
xmldir                  byte    "1"
                        byte    "</dir>" 
                        byte    "<create>"
xmlcreated              byte    "0000-00-00T00:00:00"
                        byte    "</create>"
                        byte    "<modify>"
xmlmodified             byte    "0000-00-00T00:00:00"
                        byte    "</modify>"
                        byte    "<access>"
xmlacessed              byte    "0000-00-00T00:00:00"
                        byte    "</access>"
                        byte    "</dt>", 0

xmlfooter               long                                                                                                                              
                        byte    "</ds>", 0
xmlfooter_end           long
                        
''-------[ Variables ]--------------------------------------------------------------------
cmdin                   res     1



                        ' res 1                    ' still 1 long free !
                        fit     496

''
''=======[ MIT License ]==================================================================
CON                                                     'MIT License
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