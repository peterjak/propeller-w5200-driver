CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000
{
VAR

  long  cog, _cmd, _iobuff
  byte _mosi
  byte _sck       
  byte _cs    
  byte _miso
}

DAT
  cog       long  $0
  _cmd      long  $0
  _iobuff   long  $0
  _mosi     long  $0
  _sck      long  $0
  _cs       long  $0
  _miso     long  $0

  _cnt1      long  $00
  _cnt2      long  $00
  

PUB Cnt1
  return _cnt1

PUB Cnt2
  return _cnt2
  
PUB Init(p_cs, p_sck, p_mosi, p_miso)
  Start(p_cs, p_sck, p_mosi, p_miso)

PUB Start(p_cs, p_sck, p_mosi, p_miso)

  Stop

  'Init Parameters
  _cmd    :=  0
  
  'Pin assignments
  _sck  :=  p_sck 
  _mosi :=  p_mosi
  _miso :=  p_miso  
  _cs   :=  p_cs

  cog := cognew(@startSpi, @_cmd) + 1

PUB Stop
  if Cog
    cogstop(Cog~ -  1)


PUB ReStart
  ifnot(cog)
    cog := cognew(@startSpi, @_cmd) + 1

PUB GetCogId
  return cog-1
      
PUB Write( addr, numberOfBytes, source) 
  
  ReStart
  
  ' Validate
  if (numberOfBytes => 1)
    'wait for the command to complete
    repeat until _cmd == 0
    
    
    _cnt1 := CNT
    _iobuff := source                    
    ' 32 bit instruction
    '     [address(31-16)| Op Code(15)| length(14-0)]
    _cmd := (addr << 16) + ($1 << 15) + numberOfBytes

    'wait for the command to complete
    repeat until _cmd == 0
    
    _cnt2 := CNT
    
    ' return bytes written
    return( numberOfBytes )

  else
    ' catch error
    return 0

PUB Read(addr, numberOfBytes, dest_buffer_ptr) | _index, _data, _spi_word

  ReStart
  ' test for anything to read?
  if (numberOfBytes => 1)

    'wait for the command to complete
    repeat until _cmd == 0
    
    _iobuff := dest_buffer_ptr 
    ' 32 bit instruction
    '     [address(31-16)| Op Code(15)| length(14-0)] 
    _cmd := (addr << 16) + ($0 << 15) + numberOfBytes

    repeat until _cmd == 0
    
    ' return bytes read
    return( numberOfBytes )
  else
    ' catch error
    return 0 
    



DAT
                    org     0
startSpi
                    mov     t1,     par           'Command Read/Write
                    add     t1,     #8            'Point SPI parameters
'--------------------------------------------------------------------------
'Initialize SPI pin masks and counter configurations 
'-------------------------------------------------------------------------- 
                    rdlong  t2,     t1            'Master out slave in
                    mov     cntout, nco           'Save counter output pin
                    add     cntout, t2
                    mov     mosi,   #1
                    shl     mosi,   t2

                    mov     frqb,  zero
                    mov     ctrb,  cntout
                     
                    add     t1,     #4            'Clock
                    rdlong  t2,     t1
                    mov     cntclk, nco           'Save counter clock pin
                    add     cntclk, t2
                    mov     sck,    #1
                    shl     sck,    t2
                     
                    add     t1,     #4            'Chip Select
                    rdlong  t2,     t1
                    mov     cs,     #1
                    shl     cs,     t2
                               
                    add     t1,     #4            'Master in slave out
                    rdlong  t2,     t1

                    mov     miso,   #1
                    shl     miso,   t2

                    mov     spi,    mosi          'SPI bus mask
                    or      spi,    sck
                    or      spi,    cs

                    mov     idata,  zero          'Init
                    mov     odata,  zero 
'--------------------------------------------------------------------------
'Initialize the SPI bus
'--------------------------------------------------------------------------
:initBus            andn    outa,   mosi
                    andn    outa,   sck
                    or      outa,   cs
                    or      dira,   spi           'SPI bus output
                    andn    dira,   miso          'Set master input                
'--------------------------------------------------------------------------
 'Do we have a command to process? 
'--------------------------------------------------------------------------
:getCmd             mov     t1,     par
                    rdlong  cmd,    t1
                    testn   cmd,    zero      wz
              if_z  jmp     #:getCmd              
'--------------------------------------------------------------------------
'Get the IO buffer pointer and unpack the command; op code and length
'--------------------------------------------------------------------------
                    add     t1,     #4            'Buffer pointer       
                    rdlong  pbuff,  t1   
                    mov     op,     cmd           'Grab the opcode bit[15]
                    and     op,     opMask        'Read = 0
                    shr     op,     #15           'Write = 1
                    mov     len,    cmd           'Grab the length [14..0]
                    and     len,    lenMask
'--------------------------------------------------------------------------
' Execute the 32 bit W5200 command
'--------------------------------------------------------------------------
                    andn    outa,   sck           'Clock low
                    mov     frqa,   frqx20        '20 Mhz
:exeCmd             mov     phsb,   cmd           'Load the command
                    andn    outa,   cs            'CS active low 

                    mov     ctra,   cntclk        'Start clocking
                    rol     phsb,   #1            'Bits 31 - 24
                    rol     phsb,   #1            'Bit 31 was ready to go 
                    rol     phsb,   #1            'that's why we have 7 ROLs
                    rol     phsb,   #1            'to start 
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    
                    rol     phsb,   #1            'Bits 23 - 16
                    rol     phsb,   #1             
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    
                    rol     phsb,   #1            'Bits 15 - 8
                    rol     phsb,   #1            
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    
                    rol     phsb,   #1           'Bits 7 - 0
                    rol     phsb,   #1            
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    mov     ctra,   zero          'Stop clocking
                    
'--------------------------------------------------------------------------
' Execute Read or Write
'--------------------------------------------------------------------------
                    cmp     op,     zero      wz   'Jump to read if 0
          if_z      jmp     #:read                 'Otherwise write
                    jmp     #:write
'--------------------------------------------------------------------------
' Read
'--------------------------------------------------------------------------
:read
                    andn    outa,  mosi           'Set mosi low   
                    mov     frqa,  frqx10         '10Mhz
:readNext
                    mov     phsa,  phsx10         'Offset initial clock pulse
                    nop
                    mov     ctra,   cntclk        'Start clocking
                    test    miso,   ina     wc    'Read 
                    rcl     idata,  #1            'Rotate C to LSB
                    test    miso,   ina     wc    
                    rcl     idata,  #1
                    test    miso,   ina     wc    
                    rcl     idata,  #1
                    test    miso,   ina     wc    
                    rcl     idata,  #1
                    test    miso,   ina     wc
                    rcl     idata,  #1
                    test    miso,   ina     wc    
                    rcl     idata,  #1
                    test    miso,   ina     wc    
                    rcl     idata,  #1
                    test    miso,   ina     wc
                    mov     ctra,  zero           'Stop clocking 
                    rcl     idata,  #1

                    and     idata,  #$FF          'trim 
                    wrbyte  idata,  pbuff         'Write byte to HUB 
                    add     pbuff,  #1            'Increment buffer pointer
                    djnz    len,    #:readNext    'Get next byte

                    or      outa,   cs            'Deselect
                    or      outa,   sck           'Set the clock high
                    jmp     #:done 
'--------------------------------------------------------------------------
' Write
'--------------------------------------------------------------------------   
 :write             'nop
                    rdbyte  phsb,   pbuff
                    shl     phsb,   #32-8
                    mov     frqa,   frqx20
                    mov     ctra,   cntclk        'Start clocking
                    
                    rol     phsb,   #1            'Write bits 31 to 23
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1
                    rol     phsb,   #1

                    mov     ctra,   zero          'Stop clocking
                    add     pbuff,  #1            '+1 HUB pointer
                    djnz    len,    #:write       'Process next byte
                    
                    or      outa,   cs            'Deselect
                    or      outa,   sck           'Set the clock high
'--------------------------------------------------------------------------
'Done - return
'--------------------------------------------------------------------------
:done               mov     t1,     par
                    mov     cmd,    #0
                    wrlong  cmd,    t1
                    mov     phsb,   zero 'Clear phsb line
                    jmp     #:getCmd

'
' Initialized data
'
zero                long    $0000_0000
opMask              long    $0000_8000
lenMask             long    $0000_7FFF
frqx20              long    $4000_0000
phsx20              long    $5000_0000
frqx10              long    $2000_0000
phsx10              long    $6000_0000
nco                 long    %00100_000 << 23
'
' Uninitialized data
'
pbuff               res     1
idata               res     1
odata               res     1
cmd                 res     1
op                  res     1 
len                 res     1
'------[SPI Buss ]------------------- 
mosi                res     1 
sck                 res     1 
cs                  res     1 
miso                res     1
spi                 res     1
cntclk              res     1
cntout              res     1
'------[Temp Vars]-------------------
t1                  res     1
t2                  res     1
                    fit
                        
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