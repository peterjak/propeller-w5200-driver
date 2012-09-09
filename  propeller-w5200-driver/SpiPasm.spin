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
  _mosi     byte  $0
  _sck      byte  $0
  _cs       byte  $0
  _miso     byte  $0

PUB Init(p_cs, p_sck, p_mosi, p_miso)
  Start(p_cs, p_sck, p_mosi, p_miso)

PUB Start(p_cs, p_sck, p_mosi, p_miso)

  'Init Parameters
  _cmd    :=  0
  
  'Pin assignments
  _sck  :=  p_sck 
  _mosi :=  p_mosi
  _miso :=  p_miso  
  _cs   :=  p_cs

  Cog := cognew(@startSpi, @_cmd) + 1

PUB Stop

  if Cog
    cogstop(Cog~ -  1)

    
PUB Write( addr, numberOfBytes, source) 

  
  ' Validate
  if (numberOfBytes => 1)
    'wait for the command to complete
    repeat until _cmd == 0
    
    _iobuff := source                    
    ' 32 bit instruction
    '     [address(31-16)| Op Code(15)| length(14-0)]
    _cmd := (addr << 16) + ($1 << 15) + numberOfBytes

    'wait for the command to complete
    repeat until _cmd == 0

    ' return bytes written
    return( numberOfBytes )

  else
    ' catch error
    return 0

PUB Read(addr, numberOfBytes, dest_buffer_ptr) | _index, _data, _spi_word

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
                    add     t1,     #8            'Point to SPI pins parameters       
                     
                    'Get SPI pin masks
                    rdbyte  t2,     t1            'Master out slave in
                    mov     mosi,   #1
                    shl     mosi,   t2
                     
                    add     t1,     #1            'Clock
                    rdbyte  t2,     t1
                    mov     sck,    #1
                    shl     sck,    t2
                     
                    add     t1,     #1            'Chip Select
                    rdbyte  t2,     t1
                    mov     cs,     #1
                    shl     cs,     t2
                               
                    add     t1,     #1            'Master in slave out
                    rdbyte  t2,     t1
                    mov     miso,   #1
                    shl     miso,   t2

                    mov     spi,    mosi          'SPI bus mask
                    or      spi,    sck
                    or      spi,    cs
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
:exeCmd             andn    outa,   cs            'CS active low 
                    mov     bits,   #32           'Number of bit to process                
:cmdBit
                    rol     cmd,    #1            'Rotate MSB to LSB
                    andn    outa,   sck           'Clock low
                    test    cmd,    #1       wc   'AND #1 and set C flag for odd parity
                    muxc    outa,   mosi          'send high or low depending on C flag
                    test    miso,   ina      wc   'C is set if odd parity after the AND
                    rcl     idata,  #1            'rotate carry right (MSB) into axdata 1 time

                    or      outa,   sck           'Clock high
                    djnz    bits,   #:cmdBit      'decrement value and jump to address if not 0.

'--------------------------------------------------------------------------
' Execute Read or Write
'--------------------------------------------------------------------------
                    cmp     op,     zero      wz   'Jump tp read if 0
          if_z      jmp     #:read                 'Otherwise write
                    jmp     #:write

'--------------------------------------------------------------------------
' Read
'--------------------------------------------------------------------------                    jmp     #:write                   
:read
                    mov     idata,  zero
                    mov     odata,  zero
                    test    odata,  #1      wc    'Set mosi low
                    muxc    outa,   mosi

                    'Bit 0
:readNext           andn    outa,   sck           'Clock low
                    test    miso,   ina     wc    'Read 
                    or      outa,   sck           'Clock high 
                    rcl     idata,  #1            'Rotate C to LSB
                    'Bit 1          
                    andn    outa,   sck
                    test    miso,   ina     wc    
                    or      outa,   sck            
                    rcl     idata,  #1
                    'Bit 2          
                    andn    outa,   sck
                    test    miso,   ina     wc    
                    or      outa,   sck            
                    rcl     idata,  #1
                    'Bit 3         
                    andn    outa,   sck
                    test    miso,   ina     wc    
                    or      outa,   sck            
                    rcl     idata,  #1
                    'Bit 4         
                    andn    outa,   sck
                    test    miso,   ina     wc    
                    or      outa,   sck            
                    rcl     idata,  #1
                    'Bit 5          
                    andn    outa,   sck
                    test    miso,   ina     wc    
                    or      outa,   sck            
                    rcl     idata,  #1
                    'Bit 6          
                    andn    outa,   sck
                    test    miso,   ina     wc    
                    or      outa,   sck            
                    rcl     idata,  #1
                    'Bit 7          
                    andn    outa,   sck
                    test    miso,   ina     wc    
                    or      outa,   sck            
                    rcl     idata,  #1
        
                    and     idata,  #$FF          'trim 
                    wrbyte  idata,  pbuff         'Write byte to HUB 
                    add     pbuff,  #1            'Increment buffer pointer
                    djnz    len,    #:readNext    'Get next byte

                    or      outa,   cs            'Deselect
                    jmp     #:done 

'--------------------------------------------------------------------------
'Write
'--------------------------------------------------------------------------
:write
                    rdbyte  odata,  pbuff         'Init params
                    mov     idata,  zero
                    rol     odata,  #32-8         'Frame the bit in MSB

                    'Bit 0
                    rol     odata,  #1      wc    'Rotate MSB to LSB
                    andn    outa,   sck           'Clock low
                    muxc    outa,   mosi          'Send the bit
                    or      outa,   sck           'Clock high

                    'Bit 1
                    rol     odata,  #1      wc       
                    andn    outa,   sck           'clock low  
                    muxc    outa,   mosi          
                    or      outa,   sck           'clock high

                    'Bit 2
                    rol     odata,  #1      wc       
                    andn    outa,   sck           'clock low  
                    muxc    outa,   mosi          
                    or      outa,   sck           'clock high
                    
                    'Bit 3
                    rol     odata,  #1      wc       
                    andn    outa,   sck           'clock low  
                    muxc    outa,   mosi          
                    or      outa,   sck           'clock high
                    
                    'Bit 4
                    rol     odata,  #1      wc       
                    andn    outa,   sck           'clock low  
                    muxc    outa,   mosi          
                    or      outa,   sck           'clock high
                    
                    'Bit 5
                    rol     odata,  #1      wc       
                    andn    outa,   sck           'clock low  
                    muxc    outa,   mosi          
                    or      outa,   sck           'clock high
                    
                    'Bit 6
                    rol     odata,  #1      wc       
                    andn    outa,   sck           'clock low  
                    muxc    outa,   mosi          
                    or      outa,   sck           'clock high
                    
                    'Bit 7
                    rol     odata,  #1      wc       
                    andn    outa,   sck           'clock low  
                    muxc    outa,   mosi          
                    or      outa,   sck           'clock high
                    
                    and     idata,  #$FF          'trim
                    add     pbuff,  #1            '+ HUB pointer
                    djnz    len,    #:write       'Next byte
                    or      outa,   cs            'Deselect
                     
                    jmp     #:done 
'--------------------------------------------------------------------------
'Done - return
'--------------------------------------------------------------------------
:done               mov     t1,     par
                    mov     cmd,    #0
                    wrlong  cmd,    t1
                    jmp     #:getCmd

'
' Initialized data
'
zero                    long    $0000_0000
opMask                  long    $0000_8000
lenMask                 long    $0000_7FFF

'
' Uninitialized data
'
pbuff                   res     1
idata                   res     1
odata                   res     1
cmd                     res     1
op                      res     1 
len                     res     1
bits                    res     1
'------[SPI Buss ]------------------- 
mosi                    res     1 
sck                     res     1 
cs                      res     1 
miso                    res     1
spi                     res     1 
'------[Temp Vars]-------------------
t1                      res     1
t2                      res     1
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