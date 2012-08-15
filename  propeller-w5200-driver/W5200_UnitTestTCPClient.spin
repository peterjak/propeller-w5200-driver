CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K                     = $800
  DEFAULT_RX_TX_BUFFER          = $800

  'Protocol Enum
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  CR = $0D
  LF = $0A
  NULL = $0 
       
VAR

DAT
  buff          byte  $0[BUFFER_2K]
  hello         byte  "Hello World", $00
  request       byte  "GET /spinneret/myip.aspx HTTP/1.1", CR, LF, {
}               byte  "Host: agaverobotics.com", CR, LF, {
}               byte  "User-Agent: Wiz5200", CR, LF, CR, LF, $0

OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5200"


 
PUB Main | sock, port, bytesToRead

  pst.Start(115_200)
  pause(500)
  
  wiz.Init

  'Initialize Socket 0 port 8080
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  wiz.SetIp(192, 168, 1, 130)

  sock := 0
  port := 8080
  wiz.InitSocket(sock, TCP, port)

  'wiz.DebugRead(wiz#MODE_REG, @buff, $34)
  PrintIp(@buff+wiz#GATEWAY0)
  PrintIp(@buff+wiz#SUBNET_MASK0)
  PrintIp(@buff+wiz#SOURCE_IP0)
  PrintMac(@buff+wiz#MAC0)



  wiz.RemoteIp(sock, 65, 98, 8, 151)
  wiz.SetRemotePort(sock, 80)


  'wiz.DebugRead($4000, @buff, 25)
  DisplayMemory(@buff, 25, true)
  
  'pst.hex(DeserializeWord(@buff), 4)
  'pst.hex(byte[@buff], 4)

  'wiz.DebugRead($4000, @buff, 4)
  'PrintIp(@buff)

  'wiz.DebugRead($4010, @buff, 2)
  'DeserializeWord(@buff)
  
  'return 

  'pst.hex(wiz.GetSocketRegister(sock, wiz#S_DEST_IP0), 4)
  'pst.char(CR)
  'pst.hex(wiz.GetSocketRegister(sock, wiz#S_DEST_PORT0), 4)
  'return

  {
  wiz.RemoteIp(sock, 65, 98, 8, 151)
  PrintIp(wiz.GetWorkSpace)

  wiz.RemotePort(sock, 80)
  pst.dec(DeserializeWord(wiz.GetWorkSpace))
  pst.char(CR)
  pst.char(CR)
  
  wiz.GetRemoteIp(sock)
  PrintIp(wiz.GetWorkSpace)


 
  'wiz.DebugRead(sock, wiz#GATEWAY0, @buff, 4)
  'PrintIp(@buff)
  
  wiz.DebugRead(sock, wiz#S_DEST_PORT0, @buff, 2)
  'DisplayMemory(@buff, 5, true)
  pst.dec(DeserializeWord(@buff))
  pst.char(CR)
  return                                                                            
  }


   '----------------------------------------------------
   'Open
   '----------------------------------------------------
   pst.str(string("Open", CR))
   wiz.OpenSocket(sock)
   
   '---------------------------------------------------- 
   'Listen
   '----------------------------------------------------
   pst.str(string("Connect Request", CR))
   wiz.OpenRemoteSocket(sock)
   
   '---------------------------------------------------- 
   'Connection?
   '----------------------------------------------------
   
   PrintNameValue(string("Status"), wiz.SocketStatus(sock), 4)
   repeat until wiz.IsEstablished(sock)
     pause(100)

   pst.str(string("Connected", CR))
   PrintNameValue(string("Status"), wiz.SocketStatus(sock), 4)
   
   '----------------------------------------------------      
   'Request
   '----------------------------------------------------
   wiz.Tx(sock, @request, strsize(@request))
   PrintNameValue(string("Status"), wiz.SocketStatus(sock), 4)

   bytesToRead := wiz.GetRxBytesToRead(sock)
   PrintNameValue(string("Bytes To Read"), bytesToRead, 4) 
   
   PrintPointers(sock)
   PrintNameValue(string("Status"), wiz.SocketStatus(sock), 4)
   
   'Process request
   wiz.Rx(sock, @buff, bytesToRead)
   
   pst.char(CR)
   pst.str(string(CR, "Print Buffer", CR))
   DisplayMemory(@buff, strsize(@buff), true)
   pst.str(@buff)
   pst.char(CR)
   
   PrintNameValue(string("Status"), wiz.SocketStatus(sock), 4)
   
   '----------------------------------------------------      
   'Response
   '---------------------------------------------------- 
   bytesToRead := wiz.Tx(sock, @hello, strsize(@hello))
   PrintNameValue(string("Tx Result"), bytesToRead, 4)
   
   
   '----------------------------------------------------      
   'Send FIN
   '----------------------------------------------------
   wiz.DisconnectSocket(sock) 
   PrintNameValue(string("Status"), wiz.SocketStatus(sock), 4)
   'Close wait?
   repeat 10
     pause(100)
     if(wiz.IsCloseWait(sock))
       wiz.DisconnectSocket(sock)
       PrintNameValue(string("Close Wait"), 1, 2)
     else
       PrintNameValue(string("Close Wait"), 0, 2)    
   'Are we dissconnected?
   repeat 10
     pause(100)
     if(wiz.IsClosed(sock))
       PrintNameValue(string("Is Closed"), 1, 2)
       next
     else
       PrintNameValue(string("Is Closed"), 0, 2)  
   
  'Did we timeout?
   wiz.CloseSocket(sock)
   PrintNameValue(string("Forse close"), 1, 2)
   
   ClearBuffer 
    

 

PRI ClearBuffer
  bytefill(@buff, 0, $800)

PRI PrintPointers(sock)
  {PrintNameValue(string("S_TX_R_PTR0"), wiz.DebugReadWord(sock, wiz#S_TX_R_PTR0), 4)
  PrintNameValue(string("S_TX_W_PTR0"), wiz.GetTxWritePointer(sock), 4)
  PrintNameValue(string("S_RX_R_PTR0"), wiz.DebugReadWord(sock, wiz#S_RX_R_PTR0), 4)
  PrintNameValue(string("S_RX_W_PTR0"), wiz.DebugReadWord(sock, wiz#S_RX_W_PTR0), 4) }

    
  
PRI SerializeWord(value, buffer)
  byte[buffer++] := (value & $FF00) >> 8
  byte[buffer] := value & $FF

PRI DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value

PUB testMethod(value) | t1, t2
  t1 := @value
  t2 := long[t1]
  return t1


PUB PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)

PUB PrintMac(addr) | i
  repeat i from 0 to 5
    pst.hex(byte[addr][i],2)
    if(i < 5)
      pst.char($2E)
    else
      pst.char($0D)  

PUB PrintNameValue(name, value, digits) | len
  len := strsize(name)
  
  pst.str(name)
  repeat 30 - len
    pst.char($2E)
  if(digits > 0)
    pst.hex(value, digits)
  else
    pst.dec(value)
  pst.char(CR)

{
PRI PrintMaskAndBase | i
  repeat i from 7 to 0
    PrintNameValue(string("_sockTxBase"), wiz._sockTxBase(i), 4)
    PrintNameValue(string("_sockTxMask"), wiz._sockTxMask(i), 4)

  pst.char(CR)
  
  repeat i from 7 to 0
    PrintNameValue(string("_sockRxBase"), wiz._sockRxBase(i), 4)
    PrintNameValue(string("_sockRxMask"), wiz._sockRxMask(i), 4)
 }       
PUB PrintStatus(value)
  pst.str(string("Status: "))
  pst.hex(value, 2)
  pst.char(CR)
        
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
  
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return

  
    'Initialize W5200 Common Register
  'wiz.SetCommonnMode(%0001_0000)
  'wiz.SetGateway(192, 168, 1, 1)
  'wiz.SetSubnetMask(255, 255, 255, 0)
  'wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  'wiz.SetIp(192, 168, 1, 130)
  'wiz.SetDefault2kRxTxBuffers 

  {    
PUB DebugRx
  PrintNameValue(string("_rxrp1"), wiz._rxrp1, 8) 
  PrintNameValue(string("_rxlen1"), wiz._rxlen1, 8)
  PrintNameValue(string("_rxlen2"), wiz._rxlen2, 8)
  PrintNameValue(string("_rxrp2"), wiz._rxrp2, 8)
  
PUB DebugTx
  pst.str(wiz._towrite)
  pst.char(CR)
  PrintNameValue(string("_txmask"), wiz._txmask, 8)
  PrintNameValue(string("_txwp1"), wiz._txwp1, 8)
  PrintNameValue(string("_mask"), wiz._mask, 8)
  PrintNameValue(string("_pointer"), wiz._pointer, 8)
  PrintNameValue(string("_txwp2"), wiz._txwp2, 8)
  PrintNameValue(string("_txrp1"), wiz._txrp1, 8)
  PrintNameValue(string("_txrp2"), wiz._txrp2, 8)
  } 
{       
PUB GetBaseAddress(sock, pointer) | mask, ptr
  mask := wiz.DebugReadWord(sock, pointer) & $07FF
  ptr := mask + $8000
}
   
  
  'pst.dec(long[testMethod(2)])
  'return

  'pst.hex(wiz.GetSocketRegister(0, wiz#S_RX_MEM_SIZE),4)
  'return

  {
  'Initialize W5200 Common Register
  wiz.SetCommonnMode(%0001_0000)
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  wiz.SetIp(192, 168, 1, 130)
  }
   
  
    {
  'Socket setup
  'wiz.SetDefault2kRxTxBuffers
  
  'debug
  wiz.DebugRead(wiz#MODE_REG, @buff, $34)
  DisplayMemory(@buff, $34, true)
  pst.char($0D)

  PrintIp(@buff+wiz#GATEWAY0)
  PrintIp(@buff+wiz#SUBNET_MASK0)
  PrintIp(@buff+wiz#SOURCE_IP0)

  repeat i from 0 to 7
    pst.dec(wiz.DebugReadByte(wiz.GetSocketRegister(i, wiz#S_RX_MEM_SIZE)))
    pst.char($0D)
    pst.dec(wiz.DebugReadByte(wiz.GetSocketRegister(i, wiz#S_TX_MEM_SIZE)))
    pst.char($0D)
    pst.char($0D)

 }




{
PUB _Port
  return port1 + port0 * $100

PUB Port_(value)
  port0 := (value + $FF00) >> 16
  port1 := value + $FF
 }
{
PUB RegisterUnitTest | regbuff
  regBuff := wreg.Main
  pst.str(String("Reg Buffer......"))
  pst.dec(regBuff)
  pst.char(13)
  pst.str(string("Reg Length......"))
  pst.dec(wreg.RegLen)
  pst.char(13)
  
}


{  
PUB ClearBuffer
  bytefill(@buff, 0, 128)
}
  

  {

  DAT
  mode          byte  %00010000                  'enable ping
  gatewayIp     byte  192, 168,   1,   1
  subnetmaskIp  byte  255, 255, 255,   0
  mac           byte  $00, $08, $DC, $16, $F8, $01
  ipAddress     byte  192, 168,   1,   130
  smode         byte  %0000_0001                'TCP Mode
  port0         byte  $1F                       'Port 8080
  port1         byte  $90
  open          byte  $01
  listen        byte  $02

  
  'pst.hex(wreg#SOCK0+wreg#S_PORT0,4)
  'pst.dec(_Port)


  'Init common registers
  RegisterUnitTest
  WriteReg(wreg#MODE, @mode, 1)
  WriteReg(wreg#GATEWAY0, @gatewayIp, 4)
  WriteReg(wreg#SUBNET_MASK0, @subnetmaskIp, 4)
  WriteReg(wreg#MAC0, @mac, 6)
  WriteReg(wreg#SOURCE_IP0, @ipAddress, 4)

  'Init Rx and Tx Memory
  

  'Setup Socket
  WriteReg(wreg#SOCK0+wreg#S_MR, @smode, 1)
  WriteReg(wreg#SOCK0+wreg#S_PORT0, @port0, 2)
  WriteReg(wreg#SOCK0+wreg#S_CR, @open, 1)
  pause(1000)
  'repeat until wreg#SOCK_INT ==


  ReadRegisters(wreg#SOCK0+wreg#S_SR, 1)
  pst.hex(buff[0], 2)
  pst.char(13)

  'Listen
  WriteReg(wreg#SOCK0+wreg#S_CR, @listen, 1)
  pause(1000)
  
  ReadRegisters(wreg#SOCK0+wreg#S_SR, 1)
  pst.hex(buff[0], 2)
  pst.char(13)
  
  {
  'Wait for a connection
  repeat until ReadRegister(wreg#SOCK0+wreg#S_SR) == wreg#SOCK_ESTABLISHED

  'Confirm TCP data received
  repeat until NOT ReadRegister(wreg#SOCK0+wreg#S_RX_RCV_SIZE0) == 0

  'Get data length to read
  ReadRegisters(wreg#SOCK0+wreg#S_RX_RCV_SIZE0, 2)
  len := buff[1] + buff[0] * $100
  }
  'Calculate the offset
  'Mike G  I need to study the buffer allocation documentation
  
  
 }
  
  
  

  'ReadRegisters(wreg#SOCK0+wreg#S_PORT0, 2)
  'ReadRegisters(0, 54)
    
  'data :=  buff[1] + buff[0] * $100
  'pst.hex(data, 4)

 


  {   
  opcode := $0
  cmd := (addr << 16) + (opcode << 15) + len
  spi.WriteRead( 32, cmd, $FF )
  
  repeat idx from 0 to len-1
    data := spi.WriteRead( 8, $00, $FF )
    pst.dec(data)
    pst.char(13) 
    buff[idx] := data & $FF


  repeat idx from 0 to len-1
    pst.dec(buff[idx])
    pst.char(13)
 } 

  {
  pst.hex(spi.WriteRead( 16, 1, $FF ), 2)
  pst.hex(spi.WriteRead( 16, $8000+1, $FF ), 2)
  pst.hex(spi.WriteRead( 8, 192, $FF ), 2)


  pst.hex(spi.WriteRead( 16, 2, $FF ), 2)
  pst.hex(spi.WriteRead( 16, $8000+1, $FF ), 2)
  pst.hex(spi.WriteRead( 8, 168, $FF ), 2)

  pst.hex(spi.WriteRead( 16, 3, $FF ), 2)
  pst.hex(spi.WriteRead( 16, $8000+1, $FF ), 2)
  pst.hex(spi.WriteRead( 8, 1, $FF ), 2)

  pst.hex(spi.WriteRead( 16, 4, $FF ), 2)
  pst.hex(spi.WriteRead( 16, $8000+1, $FF ), 2)
  pst.hex(spi.WriteRead( 8, 1, $FF ), 2)
  }
  'pause(500)
  'pst.char(13)
  'pst.char(13)
  { 
  spi.WriteRead( 16, 1, $FF )
  spi.WriteRead( 16, $0000+1, $FF )
  pst.dec(spi.WriteRead( 8, 0, $FF ))
  pst.char($2E)

  spi.WriteRead( 16, 2, $FF )
  spi.WriteRead( 16, $0000+1, $FF )
  pst.dec(spi.WriteRead( 8, 0, $FF ))
  pst.char($2E)

  spi.WriteRead( 16, 3, $FF )
  spi.WriteRead( 16, $0000+1, $FF )
  pst.dec(spi.WriteRead( 8, 0, $FF ))
  pst.char($2E)

  spi.WriteRead( 16, 4, $FF )
  spi.WriteRead( 16, $0000+1, $FF )
  pst.dec(spi.WriteRead( 8, 0, $FF ))
  pst.char(13)
   } 