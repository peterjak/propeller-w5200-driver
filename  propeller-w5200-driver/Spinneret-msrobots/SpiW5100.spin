'********************************************************************************************* 
{
 General static SPI drive for the WizNet W5200 Hardwired TCP/IP embedded Ethernet controller
 
 AUTHOR: Mike Gebhard
 COPYRIGHT: Parallax Inc.
 LAST MODIFIED: 8/12/2012
 VERSION 1.0
 LICENSE: MIT (see end of file)

 COMMENTS: The SPI driver is derived directly from SPI SRAM - SRAM_driver_23K256_v010.spin.

 ORIGINAL AUTHOR: Andre' LaMothe
 COPYRIGHT: Parallax Inc.
 LAST MODIFIED: 4/4/11
 VERSION 1.0

 MODIFICATIONS:
 1) Removed method and members that did not pertain to the W5200.
 2) PIN IO moved to the DAT block. Doing so makes the SPI driver PIN IO static.
    Once this driver is initialized the SPI driver is initialized for all objects.

  SPI_MOSI          = 1 ' SPI master out serial in to slave
  SPI_SCK           = 3 ' SPI clock from master to all slaves
  SPI_CS            = 2 ' SPI chip select (active low)
  SPI_MISO          = 0 ' SPI master in serial out from slave
}
'********************************************************************************************* 
CON
  ' null pointer, null character
  NULL         = 0  

DAT
  
  
  SPI_MISO      long    0
  SPI_MOSI      long    1
  SPI_CS        long    2
  SPI_SCK       long    3
  ENABLE_SPI    long    15
  RESET         long    14

PUB Init(pSPI_CS, pSPI_SCK, pSPI_MOSI, pSPI_MISO)  
{{
DESCRIPTION: This method initializes the SPI functionality, the SRAM, and the SRAM
             cache.
PARMS:       
      SPI_CS   - the Prop I/O signal connected to the W5200 chip's select pin    
      SPI_SCK  - the Prop I/O signal connected to the W5200 chip's clock pin    
      SPI_MOSI - the Prop I/O signal connected to the W5200 chip's master out serial in pin
      SPI_MISO - the Prop I/O signal connected to the W5200 chip's master in serial out pin

RETURNS: address of cache page, so caller can access data directly.
}}

  ' /////////////////////////////////////////////////////////////////////////////
  ' INITIALIZE I/O PINS /////////////////////////////////////////////////////////
  ' /////////////////////////////////////////////////////////////////////////////

  OUTA[ENABLE_SPI]     := 1
  DIRA[ENABLE_SPI]     := 1

  dira[RESET]~~
  outa[RESET]~
  waitcnt(((clkfreq / 1_000_000 * 3 - 3932) #> 381) + cnt)
  outa[RESET] ~~
  waitcnt(((clkfreq / 1_000 * 300 - 3932) #> 381) + cnt)
  
  SPI_CS   := pSPI_CS    
  SPI_SCK  := pSPI_SCK   
  SPI_MOSI := pSPI_MOSI
  SPI_MISO := pSPI_MISO  

  ' initialize SPI IO
  SpiInit



PUB ChipSelect
{{
DESCRIPTION: This method asserts the chip select pin on the SRAM
PARMS: none
RETURNS: nothing.
}}
  ' select the SPI SRAM
  OUTA[SPI_CS] := 0 





PUB ChipDeselect
{{
DESCRIPTION: This method de-asserts the chip select pin on the SRAM
PARMS: none
RETURNS: nothing.
}}

  ' select the SPI SRAM
  OUTA[SPI_CS] := 1 



PUB Write( addr, numberOfBytes, source) | idx, _data,  _spi_word

  ' validate
  if (numberOfBytes => 1)

    ' chip select
    OUTA[SPI_CS] := 0
     
    '_spi_word := ($F0 << 24) + (addr << 8)

    ' Write data
    repeat idx from 0 to numberOfBytes-1

      ' get byte to write
      _data := byte[ source][ idx ]
      _spi_word := ($F0 << 24) + (addr++ << 8) + (_data & $FF)
      ' write the byte
      WriteRead( 32, _spi_word, $FFFF_FFFF )

    ' de-select the SPI SRAM
    OUTA[SPI_CS] := 1 

    ' return bytes written
    return( numberOfBytes )

  else
    ' catch error
    return 0 



PUB Read(addr, numberOfBytes, dest_buffer_ptr) | _index, _data, _spi_word

  ' test for anything to read?
  if (numberOfBytes => 1)

    ' select SPI SRAM
    OUTA[SPI_CS] := 0 

    'Create and send command
    repeat _index from 0 to numberOfBytes-1
      _spi_word := ($0F << 24) + (addr++ << 8) + 0 
      byte [dest_buffer_ptr][_index] := WriteRead( 32, _spi_word, $FF )


    OUTA[SPI_CS] := 1 

    ' return bytes read
    return( numberOfBytes )
  else
    ' catch error
    return 0 


PUB SpiInit
{{
DESCRIPTION: This method initializes the SPI IO's, counter, and mux, selects channel 0 and returns.
PARMS: none.
RETURNS: nothing.
}}

  ' set up SPI lines
  OUTA[SPI_MOSI]     := 0 ' set to LOW
  OUTA[SPI_SCK]      := 0 ' set to LOW
  OUTA[SPI_CS]       := 1 ' set to HIGH (de-assert)
 
  DIRA[SPI_MOSI]     := 1 ' set to output
  DIRA[SPI_MISO]     := 0 ' set to input
  DIRA[SPI_SCK]      := 1 ' set to output
  DIRA[SPI_CS]       := 1 ' set to output


PUB ResetSpiPins( pSPI_CS, pSPI_SCK, pSPI_MOSI, pSPI_MISO )      
{{
DESCRIPTION: This method changes the SPI bus pin set going to the SRAM or whatever, you must call it AFTER
             calls to Init(...) since Init actually sets up the SPI system, SRAM, and cache.
             Thus, this function assumes the SRAM and SPI have been previously set up with call(s)
             to Init(...) and this function is used to switch SRAMs on the fly if you have more than
             one hooked up to the Prop. Ideally you will only change the CS pin, but you can use an
             entirely different bus with this funtion.
PARMS:       
      SPI_CS   - the Prop I/O signal connected to the W5200/W5100 chip's select pin    
      SPI_SCK  - the Prop I/O signal connected to the W5200/W5100 chip's clock pin    
      SPI_MOSI - the Prop I/O signal connected to the W5200/W5100 chip's master out serial in pin
      SPI_MISO - the Prop I/O signal connected to the W5200/W5100 chip's master in serial out pin

RETURNS: nothing.

}}


  SPI_CS   := pSPI_CS    
  SPI_SCK  := pSPI_SCK   
  SPI_MOSI := pSPI_MOSI
  SPI_MISO := pSPI_MISO  

  ' re-initialize SPI IO, redundant, but want to make sure bus is good
  SpiInit



' /////////////////////////////////////////////////////////////////////////////

PUB WriteRead( num_bits, data_out, bit_mask) | data_in, num_bits_minus_1
{{
DESCRIPTION: This method writes and reads SPI data a bit at a time
(SPI is a circular buffer protocal), the data is in MSB to LSB format
and up to 32-bits can be transmitted and received, the final result is
bit masked by bit_mask

PARMS:

num_bits : number of bits to transmit from data_out
data_out : source of data to transmit
bit_mask : final result of SPI transmission is masked with this to grab the relevant least significant bits

RETURNS: data retrieved from SPI transmission

}}
  ' clear result
  data_in := 0
  num_bits_minus_1 := num_bits-1 ' optimization pre-compute this since compiler will continually evaluate any constant math


  ChipSelect

  ' optimize code for 8 bit case by unrolling loop, if other bit lengths occur frequently unroll as well
  if (num_bits == 8)
  
    ' begin 8-bit case --------------------------------------------------------
    ' now read the bits in/out
          
    ' bit 0
    OUTA[SPI_SCK]  := 0                                    ' drop clock
    OUTA[SPI_MOSI] := (data_out >> 7)                      ' place next bit on MOSI
    data_in := (data_in << 1) + INA[SPI_MISO]              ' now read next bit from MISO
    OUTA[SPI_SCK]  := 1                                    ' raise clock
     
    ' bit 1
    OUTA[SPI_SCK]  := 0                                    ' drop clock
    OUTA[SPI_MOSI] := (data_out >> 6)                      ' place next bit on MOSI
    data_in := (data_in << 1) + INA[SPI_MISO]              ' now read next bit from MISO
    OUTA[SPI_SCK]  := 1                                    ' raise clock
     
    ' bit 2
    OUTA[SPI_SCK]  := 0                                    ' drop clock
    OUTA[SPI_MOSI] := (data_out >> 5)                      ' place next bit on MOSI
    data_in := (data_in << 1) + INA[SPI_MISO]              ' now read next bit from MISO
    OUTA[SPI_SCK]  := 1                                    ' raise clock
     
    ' bit 3
    OUTA[SPI_SCK]  := 0                                    ' drop clock
    OUTA[SPI_MOSI] := (data_out >> 4)                      ' place next bit on MOSI
    data_in := (data_in << 1) + INA[SPI_MISO]              ' now read next bit from MISO
    OUTA[SPI_SCK]  := 1                                    ' raise clock
     
    ' bit 4
    OUTA[SPI_SCK]  := 0                                    ' drop clock
    OUTA[SPI_MOSI] := (data_out >> 3)                      ' place next bit on MOSI
    data_in := (data_in << 1) + INA[SPI_MISO]              ' now read next bit from MISO
    OUTA[SPI_SCK]  := 1                                    ' raise clock
     
    ' bit 5
    OUTA[SPI_SCK]  := 0                                    ' drop clock
    OUTA[SPI_MOSI] := (data_out >> 2)                      ' place next bit on MOSI
    data_in := (data_in << 1) + INA[SPI_MISO]              ' now read next bit from MISO
    OUTA[SPI_SCK]  := 1                                    ' raise clock
     
    ' bit 6
    OUTA[SPI_SCK]  := 0                                    ' drop clock
    OUTA[SPI_MOSI] := (data_out >> 1)                      ' place next bit on MOSI
    data_in := (data_in << 1) + INA[SPI_MISO]              ' now read next bit from MISO
    OUTA[SPI_SCK]  := 1                                    ' raise clock
     
    ' bit 7
    OUTA[SPI_SCK]  := 0                                    ' drop clock
    OUTA[SPI_MOSI] := data_out                             ' place next bit on MOSI
    data_in := (data_in << 1) + INA[SPI_MISO]              ' now read next bit from MISO
    OUTA[SPI_SCK]  := 1                                    ' raise clock
     
    ' end 8-bit case --------------------------------------------------------

  else ' general n bit case

    ' now read the bits in/out
    repeat num_bits
      ' drop clock
      OUTA[SPI_SCK] := 0
     
      ' place next bit on MOSI
      OUTA[SPI_MOSI] := ((data_out >> (num_bits_minus_1--)))  ' optimization, no need for "& $01"
     
      ' now read next bit from MISO
      data_in := (data_in << 1) + INA[SPI_MISO]
        
      ' raise clock
      OUTA[SPI_SCK] := 1
     
  ' set clock and MOSI to LOW on exit
  OUTA[SPI_MOSI]  := 0
  OUTA[SPI_SCK]   := 0

  ChipDeselect

  ' at this point, the data has been written and read, return result
  return ( data_in & bit_mask )

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