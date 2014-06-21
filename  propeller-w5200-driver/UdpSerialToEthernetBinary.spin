'*********************************************************************************************
{
 AUTHOR: Mike Gebhard
 COPYRIGHT: AgaveRobotics LLC.
 LAST MODIFIED: 06/21/2014
 VERSION 1.0
 LICENSE: MIT (see end of file)

 INITIAL STUFF:
 UdpSerialToEthernetBinary is an enhance version of the demo UdpSerialToEthernet.
 This version adds binary data handling to the existing ASCII capabilities.

 This is an open source demo with debug statements lightly sprinkled throughout!  The demo expects
 a terminal application like PST attached to the serial port for viewing debug output.

 There is not concept of parsing a data packet or any custom data processing. Processing data or
 deciding what to do with data is up to you to figure out.  Post a question on the Parallax forum
 if you need help.
 
 DESCRIPTION:
 UdpSerialToEthernetBinary is a software serial to Ethernet transceiver.  Data received on the
 serial port are transmitted over UDP.  Incoming UDP data is transmitted on the serial port.

 Serial Port I/O pins are 30 (Rx) and 31 (Tx).
 Network parameters are set in the Main method below.  You must set up the local network parameters
 and remote IP and Port.

 OPERATION:
 There are two main processes running; SerialHandler and UdpHandler.  The two processes are running
 in separate COGs.

 The SerialHandler listens for incoming serial data then forwards the data to the UDP remote host.
 The UpdHandler functions similarly.  UDP data is received and forwarded to the serial port.

 The SerialHandler has no idea when serial data will start and it has no idea how much data 
 to expect.  Byte-to-byte timeout and max characters are the two methods SerialHandler uses
 to figure where the data ends; 

 Timeout:
 A timeout is when the next byte is not received within 200ms (default) of the previous byte. A
 timeout sends all buffered serial data to the remote UDP host. 

 Max Characters:
 The RxBuffer is divided into two halves, lower and upper.  When one half of the RxBuffer is full,
 that half is sent to the remote host while the other half continues to fill with serial data.

 The UdpHandler is less complicated on the surface because the lower layers handle the UPD data.

 Note: This demo is not configured to handle UDP packets larger than 1480 (1472 data) bytes
 reliably.  It's also possible to overload the serial port by sending many UPD messages.
 
}
'*********************************************************************************************
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

  UDP_DATA_OFFSET          = 8

  LOCAL_UPD_PORT           = 10000     


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
  txSerial       byte  $0[TX_BUFFER]
  rxUdp          byte  $0[RX_BUFFER]

  'COG Process flags
  serialIO       byte  $FF
  udpIO          byte  $FF
        
  txSerialPtr    long  $0[2]
  serialTimeout  long  $0
  
  'Data structure for passing values between COG processes
  sBytes         long  $0
  sBuffIdx       long  $0
  uBytes         long  $0
  uBuffIdx       long  $0
  
  
OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5200"
  sock          : "Socket"

PUB Main 

  wiz.HardReset(WIZ#WIZ_RESET) 
  pst.Start(115_200)
  pause(1000)
  
  pst.str(string("Serial To Ethernet Demo", CR))
  pst.str(string("-----------------------------------------------------", CR))
  
  'Init serialTimeout
  'This is the max time between bytes on the serial port
  serialTimeout := clkfreq / 1_000 * SERIAL_TIMEOUT_IN_MS 

  'Network parameters
  wiz.Start(WIZ#SPI_CS, WIZ#SPI_SCK, WIZ#SPI_MOSI, WIZ#SPI_MISO) 
  wiz.SetCommonnMode(0)

  '------------------------------------------------
  'Set the 4 items below according to
  'your network configuration 
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 140)
  wiz.SetMac($00, $08, $DC, $16, $F1, $32)
  '------------------------------------------------
  PrintNetworkParams
  
  'local socket setup
  pst.str(string("Initialize Sock", CR))
  Sock.Init(SERIAL_SOCK, UDP, LOCAL_UPD_PORT)


  '------------------------------------------------ 
  'Set remote host IP and port
  'This is the other network device, like your PC, 
  'that you're wanting to communcation with. 
  'Sock.RemoteIp(192, 168, 1, 100)
  'Sock.RemotePort(8000)
  Sock.RemoteIp(192, 168, 1, 130)
  Sock.RemotePort(10000)
  '------------------------------------------------ 

  'Init txSerial buffer pointers
  txSerialPtr[0] := @txSerial
  txSerialPtr[1] := @txSerial+(TX_BUFFER/2)   

  
  'Open a UDP socket and start up handlers
  sock.Open
  cognew(SerialHandler, @serialStack)
  pause(200)
  cognew(UdpHandler, @udpStack)
  pause(200)
  pst.str(string("-----------------------------------------------------", CR, CR))
  
  ' Keep the main COG running
  ' OR add your own processing code
  repeat 



PRI SerialHandler | char, i, startTime, counter, txSerialIdx
  pst.str(string("Start Serial Listener", CR))

  'Init local varibles
  serialIO := char := -1
  i := startTime := txSerialIdx := counter := 0
  
  repeat

    'Detect a charater, somehting other than -1, in the serial buffer
    if (char := pst.RxCheck) <> NOTHING
      startTime := CNT
      txSerial[i++] := char
      counter++


      if(counter > TX_BUFFER/2 - 1)
        startTime~
      
        'Debug
        pst.str(string("Length exceeded",CR))
        DisplayMemory(txSerialPtr[txSerialIdx], counter, true)

        'Send UPD data  
        'Init parameter and set IO flag
        sBytes := counter
        sBuffIdx := txSerialPtr[txSerialIdx]
        udpIO := TX
        counter~
        
        'Ping pong between lower and upper Rx buffer
        txSerialIdx := (txSerialIdx+1) & $01
        if (txSerialIdx == 0)
          i~
        
    else
      'Timeout logic
      if ((CNT - startTime) > serialTimeout) AND (startTime <> 0)
        i := startTime := 0
        
        'Debug
        pst.str(string("Serial Timeout",CR)) 
        DisplayMemory(txSerialPtr[txSerialIdx], counter, true)
         
        'Init parameter and set IO flag  
        sBytes := counter
        sBuffIdx := txSerialPtr[txSerialIdx]
        udpIO := TX
        counter~
            
        txSerialIdx := 0  


    'Send buffered UDP data to the COM port
    if(serialIO == RX)
    
      'Debug Display -> process the serial data  
      DisplayMemory(@rxUdp + UDP_DATA_OFFSET, uBytes - UDP_DATA_OFFSET, false)
      
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
      sock.Receive(@rxUdp, bytesToRead)
      'Let SerialHandler know we have serial data ready

      uBytes := bytesToRead
      uBuffIdx := @rxUdp
      serialIO := RX

    'Send buffered serial data to the UDP port 
    if(udpIO == TX)
      pst.str(string("Send serial data",CR))
      sock.Send(sBuffIdx, sBytes)
      udpIO~~
      


{ Debug Utilities }
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
  pst.str(string("Network Parameters",CR))
  'pst.str(string("Sock Remote IP...."))
  'PrintIp(sock.GetRemoteIP)
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
  pst.str(string("-----------------------------------------------------", CR))



  
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