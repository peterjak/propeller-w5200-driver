'':::::::[ Sntp ]:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
{{
''******************************************************************
''* SNTP Simple Network Time Protocol                       v2.01  *
''* Author: Beau Schwabe                                           *
''*                                                                *
''* Recognition: Benjamin Yaroch, A.G.Schmidt                      *
''*                                                                *
''* Copyright (c) 2011 Parallax                                    *
''* See end of file for terms of use.                              *
''******************************************************************
''
''
''Revision History:
''v1      04-07-2011              - File created
''
''v1.01   09-08-2011              - Minor code update to correct days in Month rendering
''                                - and replace bytefill with bytemove for the 'ref-id' string                               
''
''v2      01-29-2013              - Fixed an illusive bug that caused problems around the first of the year
''
''v2.01   02-02-2013              - Logic order error with previous bug fix
''
''        08-31-2013              - corrected day of week - MSrobots
''        09-26-2013              - REMOVED unused methods - MSrobots
''        10/04/2013              - added minimal spindoc comments - MSrobots  
''        
''                           1                   2                   3
''       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9  0  1
''      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
''      |LI | VN  |Mode |    Stratum    |     Poll      |   Precision    |
''      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
''      |                          Root  Delay                           |
''      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
''      |                       Root  Dispersion                         |
''      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
''      |                     Reference Identifier                       |
''      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
''      |                                                                |
''      |                    Reference Timestamp (64)                    |
''      |                                                                |
''      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
''      |                                                                |
''      |                    Originate Timestamp (64)                    |
''      |                                                                |
''      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
''      |                                                                |
''      |                     Receive Timestamp (64)                     |
''      |                                                                |
''      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
''      |                                                                |
''      |                     Transmit Timestamp (64)                    |
''      |                                                                |
''      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
''      |                 Key Identifier (optional) (32)                 |
''      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
''      |                                                                |
''      |                                                                |
''      |                 Message Digest (optional) (128)                |
''      |                                                                |
''      |                                                                |
''      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
''
}}
''
''=======[ PUBlic Spin Methods]===========================================================
PUB CreateUDPtimeheader(BufferAddress)
  '---------------------------------------------------------------------
  '                       UDP Packet - 44 Bytes
  '---------------------------------------------------------------------
    byte[BufferAddress][0] := %11_100_011    'leap,version, and mode
    byte[BufferAddress][1] := 0              'stratum
    byte[BufferAddress][2] := 0              'Poll   
    byte[BufferAddress][3] := %10010100      'precision
    
    byte[BufferAddress][4] := 0              'rootdelay
    byte[BufferAddress][5] := 0              'rootdelay   
    byte[BufferAddress][6] := 0              'rootdispersion
    byte[BufferAddress][7] := 0              'rootdispersion

    bytemove(BufferAddress+8,string("LOCL"),4) 'ref-id ; four-character ASCII string

    bytefill(BufferAddress+12,0,32)           '(ref, originate, receive, transmit) time
    
PUB  GetTransmitTimestamp(Offset,BufferAddress,Long1,Long2)|Temp1
     Temp1 := byte[BufferAddress][48]<<24+byte[BufferAddress][49]<<16
     Temp1 += byte[BufferAddress][50]<<8 +byte[BufferAddress][51]
     long[Long1]:=Temp1
     Temp1 := byte[BufferAddress][52]<<24+byte[BufferAddress][53]<<16
     Temp1 += byte[BufferAddress][54]<<8 +byte[BufferAddress][55]
     long[Long2]:=Temp1     
     'This is the time at which the reply departed the
     'server for the client, in 64-bit timestamp format.
     HumanTime(Offset,Long1)
     
PUB HumanTime(Offset,TimeStampAddress)|i,Seconds,Days,Years,LYrs,DW,DD,HH,MM,SS,Month,Date,Year
    Seconds := long[TimeStampAddress] + Offset * 3600  
                           
   'Days   := ((Seconds >>= 7)/675) + 1 '<- Days since Jan 1, 1900 ... divide by 86,400 and add 1

    i       := Seconds          ' need Seconds unchanged
    Days    := ((i >>= 7)/675)  '<- Days since Mo Jan 1, 1900 ... divide by 86,400 
    DW      := ((Days+1) // 7) + 1 ' add 1 for Mo, add 1 since rtcEngine wants 1 - 7 for So - Sa
    
    Years   := Days / 365       ' first approx.
    LYrs    := years / 4        
    Years   := (Days-LYrs) / 365 ' second approx.
    LYrs    := Years / 4            '<- Leap years since 1900
    Days    -= LYrs             '<- Leap year Days correction
   

    Days -= (Years * 365)       '   number of years since 1900.

    
    
    Year := Years + 1900        '<- Current Year                   

    Days++                      '   for 1 as first day not 0
    repeat
      repeat i from 1 to 12     '<- Calculate number of days 
        Month := 30             '   in each month.  Stop if
         if i&1 <> (i&8)>>3     '   Month has been reached
           Month += 1
        if i == 2
           Month := 28 
        if Days =< Month        '<- When done, Days will contain
           quit                 '   the number of days so far this 
        if Days > Month         '   month.  In other words, the Date.
           Days -= Month

    until Days =< Month
    Month := i                  '<- Current Month               
    Date  := Days               '<- Current Date


    'SS := long[TimeStampAddress] + Offset * 3600
    SS := Seconds -(((Years*365)*675)<<7) '<- seconds this year
         
    MM := SS / 60                        '<- minutes this year
    SS := SS - (MM * 60)                 '<- current seconds

    HH := MM / 60                        '<- hours this year
    MM := MM - (HH * 60)                 '<- current minutes

    DD := HH / 24                        '<- days this year
    HH := HH - (DD * 24)                 '<- current hour

    'DD -= LYrs                          '<- Leap year Days correction
                                         '   for THIS year

    long[TimeStampAddress][2] := Month<<24+Date<<16+Year
    long[TimeStampAddress][3] := DW<<24+HH<<16+MM<<8+SS                                     

'    DD is redundant but I included it for completion...
'    If you subtract the number of days so far this year from
'    DD and add one, you should get today's date.  This is calculated
'    from another angle above from Days

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