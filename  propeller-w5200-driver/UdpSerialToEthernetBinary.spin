CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  CR                       = $0D   
  LF                       = $0A   
  SP                       = $20   
  DOT                      = $2E   
  ZERO_TERM                = $00                       
  NOTHING                  = -1

  'Buffer size
  RX_BUFFER                = $800
  TX_BUFFER                = $800                 

  'Socket ID
  SERIAL_SOCK              = 0     


  'MAx milliseconds between bytes received on the serial port.
  'All bytes in the Rx buffer are flushed (sent) on a serial Rx timesout.                  
  SERIAL_TIMEOUT_IN_MS     = 200
                         
  #0, RX, TX             
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
                         
VAR                      
  long          udpStack[100]
  long          serialStack[100]


DAT
  'Serial buffers
  txSerial      byte  $0[TX_BUFFER]
  rxSerial      byte  $0[RX_BUFFER]

  'COG Process flags
  serialIO      byte  $FF
  udpIO         byte  $FF


  txSerialIdx   byte  $0
  counter       long  $0
  
  serialTimeout long  $0

  txSerialPtr   long  $0[2]


  'Data structure for passing values between COG processes
  sBytes         long  $0
  sBuffIdx       long  $0

  uBytes         long  $0
  uBuffIdx       long  $0
  
  
OBJ
  pst           : "Parallax Serial Terminal"
  fds           : "FullDuplexSerial"
  wiz           : "W5200"
  sock          : "Socket"

PUB Main 

  wiz.HardReset(WIZ#WIZ_RESET) 
  pst.Start(115_200)
  pause(1000)

  'Init serialTimeout
  'This is the time between bytes on the serial port
  serialTimeout := clkfreq / 1_000 * SERIAL_TIMEOUT_IN_MS 

  'Set network parameters
  wiz.Start(WIZ#SPI_CS, WIZ#SPI_SCK, WIZ#SPI_MOSI, WIZ#SPI_MISO) 
  wiz.SetCommonnMode(0)
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 130)
  wiz.SetMac($00, $08, $DC, $16, $F1, $32)

  'Socket init
  pst.str(string("Initialize Sock", CR))
  Sock.Init(SERIAL_SOCK, UDP, 10000)

  'Remote host init
  Sock.RemoteIp(192, 168, 1, 100)
  Sock.RemotePort(8000)

  'Init txSerial buffer pointers
  txSerialPtr[0] := @txSerial
  txSerialPtr[1] := @txSerial+(TX_BUFFER/2)   

  'Open a UDP socket and start up listeners
  sock.Open
  cognew(SerialHandler, @serialStack)
  pause(200)
  cognew(UdpHandler, @udpStack)

  ' Keep the main COG running
  ' OR add your own processing code
  repeat 



PRI SerialHandler | char, i, startTime
  pst.str(string("Start Serial Listener", CR))
  
  serialIO~~
  char~~
  
  i~
  startTime~
  txSerialIdx~
  
  repeat

    'Detect a charater, somehting other than -1, in the serial buffer
    if (char := pst.RxCheck) <> NOTHING
      startTime := CNT
      txSerial[i++] := char
      counter++
      
      'ConsoleHex(String("Char"), char, 2)
      'ConsoleValue(String("counter"), counter, true) 
      'ConsoleValue(String("Serial Buffer"), @txSerial, false)
      'pst.char(CR)
      'ConsoleValue(String("startTime"), startTime, true)
      
      'Max char check
      if(counter > TX_BUFFER/2 - 1)
        startTime~
      
        'Send UPD data delegate mock
        pst.str(string("Length exceeded",CR))
        DisplayMemory(txSerialPtr[txSerialIdx], counter, true)

        
        'Init parameter and set IO flag
        sBytes := counter
        sBuffIdx := txSerialPtr[txSerialIdx]
        udpIO := TX
        'End parameter and set IO flag

        counter~
        'end mockup 

        
        'Ping pong between lower and upper buffer
        txSerialIdx := (txSerialIdx+1) & $01
        if (txSerialIdx == 0)
          i~
        
    else
      'serialTimeout logic
      if ((CNT - startTime) > serialTimeout) AND (startTime <> 0)
        i := startTime := 0
        
        'Send UPD data delegate mock
        pst.str(string("serialTimeout",CR)) 
        DisplayMemory(txSerialPtr[txSerialIdx], counter, true)
         
        'Init parameter and set IO flag
        sBytes := counter
        sBuffIdx := txSerialPtr[txSerialIdx]
        udpIO := TX
        'End parameter and set IO flag
        
        counter~  
        'end mockup 

        
        txSerialIdx := 0  





    'Send buffered UDP data to the COM port
    if(serialIO == RX)
      'Debug Display -> process the serial data  
      DisplayMemory(@rxSerial+8, uBytes-8, false)
      serialIO~~
      counter++    
          


             
     
PRI UdpHandler | bytesToRead
  pst.str(string("Start UDP Handler", CR)) 
  udpIO~~
  repeat
    bytesToRead~
    'Is there UDP Rx data to process?
    if(bytesToRead := sock.DataReady)
      'Buffer the received UDP data
      sock.Receive(@rxSerial, bytesToRead)
      'Let SerialHandler know we have serial data ready

      uBytes := bytesToRead
      uBuffIdx := @rxSerial
      serialIO := RX


    
    'Send buffered serial data to the UDP port 
    if(udpIO == TX)
      pst.str(string("Send serial data",CR))
      sock.Send(sBuffIdx, sBytes)
      udpIO~~
      

PRI ConsoleHex(label, value, digits)
  pst.str(label)
  repeat 25 - strsize(label)
    pst.char(".")

  pst.hex(value, digits)
  pst.char(CR)
  
PRI ConsoleValue(label, value, isNum)
    pst.str(label)
  repeat 25 - strsize(label)
    pst.char(".")
  if(isNum)
    pst.dec(value)
  else
    pst.str(value)
  pst.char(CR)
  

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

  pst.char(CR)

  
PUB DisplayMemory(addr, len, isHex) | j
  pst.str(string(CR,"-----------------------------------------------------",CR))
  pst.str(string(CR, "      "))
  repeat j from 0 to $F
    pst.hex(j, 2)
    pst.char(SP)
  pst.str(string(CR, "      ")) 
  repeat j from 0 to $F
    pst.str(string("-- "))

  pst.char(CR) 
  repeat j from 0 to len-1
    if(j == 0)
      pst.hex(0, 4)
      pst.char(SP)
      pst.char(SP)
      
    if(isHex)
      pst.hex(byte[addr + j], 2)
    else
      pst.char(SP)
      if(byte[addr+j] == 0)
        pst.char(SP)
      if(byte[addr+j] < 15)
        pst.char(SP)
      else
        pst.char(byte[addr+j])

    pst.char(SP) 
    if((j+1) // $10 == 0) 
      pst.char(CR)
      pst.hex(j+1, 4)
      pst.char(SP)
      pst.char(SP)  
  pst.char(CR)
  
  pst.char(CR)
  pst.str(string("Start: "))
  pst.dec(addr)
  pst.str(string(" Len: "))
  pst.dec(len)
  pst.str(string(CR,"-----------------------------------------------------",CR,CR))
      
PUB PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char(DOT)
    else
      pst.char(CR)

PUB PrintMac(addr) | i
  repeat i from 0 to 5
    pst.hex(byte[addr][i], 2)
    if(i < 5)
      pst.char(":")
    else
      pst.char(CR)      
      
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