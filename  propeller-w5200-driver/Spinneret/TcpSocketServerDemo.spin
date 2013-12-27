CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  NULL          = $00
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  'W5100 I/O
  SPI_MISO          = 0 ' SPI master in serial out from slave 
  SPI_MOSI          = 1 ' SPI master out serial in to slave
  SPI_CS            = 2 ' SPI chip select (active low)
  SPI_SCK           = 3  ' SPI clock from master to all slaves
  WIZ_INT           = 13
  WIZ_RESET         = 14
  SPI_MODE          = 15

    
VAR

DAT
  header        byte  "HTTP/1.1 200 OK", CR, LF, {
}                     "Content-Type: text/html", CR, LF, CR, LF, $0 
  body          byte  "Hello World!", CR, LF, $0


  buff            byte  $0[BUFFER_2K]
  fileErrorHandle long  $0
  approot               byte    "\", 0 

OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5100" 
  sock          : "Socket"
  SDCard        : "S35390A_SD-MMC_FATEngineWrapper"
 
PUB Main | bytesToRead, offset, tail

  bytesToRead := 0
  pst.Start(115_200)
  pause(500)

  SDCard.Start
  pause(500)
  'Mount the SD card
  pst.str(string("Mount SD Card - ")) 
  SDCard.mount(fileErrorHandle)
  pst.str(string("OK",13))
  
  wiz.HardReset(WIZ_RESET)
  
  'Set network parameters
  wiz.Start(SPI_CS, SPI_SCK, SPI_MOSI, SPI_MISO)  
  wiz.SetCommonnMode(0)
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 105)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  
  pst.str(string("Initialize Socket",CR))
  sock.Init(0, TCP, 8080)

  pst.str(string("Start Socket server",CR))
  
  repeat
  
    sock.Open
    sock.Listen

    'Connection?
    repeat until sock.Connected
    
    'Data in the buffer?
    repeat until NULL < bytesToRead := sock.Available

    'Check for a timeout
    if(bytesToRead < 0)
      sock.Disconnect
      bytesToRead~
      next
  
    'Get the Rx buffer  
    sock.Receive(@buff, bytesToRead)

    {{ Process the Rx data}}
    pst.char(CR)
    pst.str(@buff)

    offset := BufferHeader(@buff, @header)
    tail := BufferIndex(@buff, offset)
    'pst.dec(tail)
    'sock.Send(@buff, strsize(@buff))
    sock.Send(@buff, tail - @buff)

    'sock.Send(@header, strsize(@header))

    sock.Disconnect
    
    bytesToRead~

{    } 
PUB BufferHeader(buffer, source)
  result := strsize(source)
  bytemove(buffer, source, result)


PUB BufferIndex(buffer, offset) | fileSize
  pst.str(string("Open", CR))
  
  sdcard.listEntry(string("index.htm")) 
  pst.str(SDCard.openFile(string("index.htm"), "r"))
  
  fileSize := SDCard.getFileSize
  pst.str(string(" ("))
  pst.dec(fileSize)
  pst.str(string(")", CR))

  result := buffer+offset

  SDCard.readFromFile(result, fileSize)
  result += fileSize
  byte[result] := 0

  'NOTE: add a pause if pst.str is removed
  'else we'll have a problem closing the file
  pst.str(buffer)
  'pause(500)
  pst.str(string(CR, "closeFile", CR))
  SDCard.closeFile

  'pst.str(string("done", CR))

    
PUB PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)
  
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return