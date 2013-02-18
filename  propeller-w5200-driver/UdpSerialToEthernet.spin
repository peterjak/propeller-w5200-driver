CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  SOCKET_BUFFER     = $400
  SERIAL_BUFFER     = $400
  SERIAL_SOCK       = 0
  
  CR                = $0D
  LF                = $0A
  NULL              = $00

  #0, RX, TX
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
       
VAR
  long          udpStack[100]
  long          serialStack[100]


DAT
  sockBuff      byte  $0[SOCKET_BUFFER]
  serBuff       byte  $0[SERIAL_BUFFER]
  serialIO      byte  $FF
  udpIO         byte  $FF

  
OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5200"
  sock          : "Socket"

PUB Main | bytesToRead, bytesSent, receiving, ptr

  wiz.HardReset(WIZ#WIZ_RESET) 
  pause(500)
  pst.Start(115_200)
  pause(500)

  'Set network parameters
  wiz.Start(WIZ#SPI_CS, WIZ#SPI_SCK, WIZ#SPI_MOSI, WIZ#SPI_MISO) 
  wiz.SetCommonnMode(0)
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 130)
  wiz.SetMac($00, $08, $DC, $16, $F1, $32)

  
  pst.str(string("Initialize Sock", CR))
  'Initialize Socket 0 port 8080
  Sock.Init(SERIAL_SOCK, UDP, 10000)
  Sock.RemoteIp(192, 168, 1, 106)
  Sock.RemotePort(8000)


  sock.Open

  cognew(SerialHandler, @serialStack)
  pause(1000)
  cognew(UdpHandler, @udpStack)

  ' Keep the main COG running
  ' OR add your own processing code
  repeat 


PRI SerialHandler | char
  pst.str(string("Start Serial Handler", CR)) 
  serialIO~~
  repeat

    'Detect a byte in the Rx buffer
    if(pst.RxCount)
      'If the first byte is a CR (0x13) then flush and quit
      'Otherwise save the first char
      if(CR == char := pst.RxCheck)
        pst.RxFlush
        next
      else
        serBuff[0] := char

      'Blocks until a string ending is 0x13 is found
      'Set the udpIO to let UdpHandler know there
      'is data ready to send   
      pst.StrIn(@serBuff+1)
      udpIO := TX

    'Check the serialIO flag for received data
    'and display the data
    if(serialIO == RX)
      'Debug Display -> process the serial data  
      DisplayMemory(@sockBuff+8, strsize(@sockBuff+8), true)
      serialIO~~

     
PRI UdpHandler | bytesToRead
  pst.str(string("Start UDP Handler", CR)) 
  udpIO~~
  repeat
    bytesToRead~
    'Is there UDP Rx data to process?
    if(bytesToRead := sock.DataReady)
      'Buffer the received UDP data
      sock.Receive(@sockBuff, bytesToRead)
      pause(10)
      'Let SerialHandler know we have serial data ready
      serialIO := RX

    'Send buffered serial data  
    if(udpIO == TX)
      sock.Send(@serBuff, strsize(@serBuff))
      pause(10)
      udpIO~~  


PRI PrintNetworkParams

  pst.str(string("Sock Remote IP...."))
  PrintIp(sock.GetRemoteIP)
  pst.str(string("Sock Remote Port.."))
  pst.dec(sock.GetPort)
  pst.char(CR)

  pst.str(string("Host IP..........."))
  PrintIp(wiz.GetIp)

  pst.str(string("Gateway..........."))                                        
  printIp(wiz.GetGatewayIp)

  pst.str(string("SubNet............"))                                        
  printIp(wiz.GetSubnetMask)

  pst.str(string("MAC..............."))                                        
  PrintMac(wiz.GetMac)

  pst.str(string("Sock IR..........."))                                        
  pst.hex(sock.GetSocketIR, 2)

  
PUB DisplayMemory(addr, len, isHex) | j
  pst.str(string(13,"-----------------------------------------------------",13))
  pst.str(string(13, "      "))
  repeat j from 0 to $F
    pst.hex(j, 2)
    pst.char($20)
  pst.str(string(13, "      ")) 
  repeat j from 0 to $F
    pst.str(string("-- "))

  pst.char(13) 
  repeat j from 0 to len
    if(j == 0)
      pst.hex(0, 4)
      pst.char($20)
      pst.char($20)
      
    if(isHex)
      pst.hex(byte[addr + j], 2)
    else
      pst.char($20)
      if(byte[addr+j] == 0)
        pst.char($20)
      if(byte[addr+j] < 15)
        pst.char($20)
      else
        pst.char(byte[addr+j])

    pst.char($20) 
    if((j+1) // $10 == 0) 
      pst.char($0D)
      pst.hex(j+1, 4)
      pst.char($20)
      pst.char($20)  
  pst.char(13)
  
  pst.char(13)
  pst.str(string("Start: "))
  pst.dec(addr)
  pst.str(string(" Len: "))
  pst.dec(len)
  pst.str(string(13,"-----------------------------------------------------",13,13))
      
PUB PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)

PUB PrintMac(addr) | i
  repeat i from 0 to 5
    pst.hex(byte[addr][i], 2)
    if(i < 5)
      pst.char(":")
    else
      pst.char($0D)      
      
PRI SerializeWord(value, buffer)
  byte[buffer++] := (value & $FF00) >> 8
  byte[buffer] := value & $FF

PRI DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value
        
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return