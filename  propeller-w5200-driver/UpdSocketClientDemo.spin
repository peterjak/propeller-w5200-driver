CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  CR    = $0D
  LF    = $0A

       
VAR

DAT
  udpHead       byte  192, 168, 1, 104, $1F, $90, $00, $0C
  udpMsg        byte  "Hello World!", $0 

OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  wiz           : "W5200"


 
PUB Main | bytesToRead, buffer, bytesSent, receiving, ptr

  receiving := true
  bytesToRead := 0
  pst.Start(115_200)
  pause(500)


  pst.str(string("Initialize", CR))
  'Initialize Socket 0 port 8080
  buffer := sock.Init(0, UDP, 8080)

  'Wiz Mac and Ip
  sock.Mac($00, $08, $DC, $16, $F8, $01)
  sock.Ip(192, 168, 1, 107)
  sock.RemoteIp(192, 168, 1, 104)
  sock.RemotePort(8080)
  
  pst.str(string("Start UPD Client",CR))
  pst.str(string("Open",CR))
  sock.Open
  
  pst.str(string("Send Message",CR))
  sock.Send(@udpMsg, strsize(@udpMsg))



  repeat while receiving 
    'Data in the buffer?
    bytesToRead := sock.Available
    pst.str(string("Bytes to Read: "))
    pst.dec(bytesToRead)
    pst.char(13)
    pst.char(13)
     
    'Check for a timeout
    if(bytesToRead < 0)
      receiving := false
      pst.str(string("Done Receiving Data", CR))
      return

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      ptr := sock.Receive
      pst.char(CR)
      pst.str(string("UPD Header:",CR))
      PrintIp(buffer)
      pst.dec(DeserializeWord(buffer + 4))
      pst.char(CR)
      pst.dec(DeserializeWord(buffer + 6))
      pst.char(CR)
       
      pst.char(CR) 
      pst.str(ptr)
      pst.char(CR)
      
    bytesToRead~

  pst.str(string(CR, "Disconnect", CR)) 
  sock.Disconnect

  
   
  DisplayMemory(ptr, 36, true)



PUB DisplayMemory(addr, len, isHex) | j
  pst.char(13)
  pst.str(string("Start: "))
  pst.dec(addr)
  pst.str(string(" Len: "))
  pst.dec(len)
  pst.char($0D)
  
  pst.str(string("-------- Buffer Dump -----------",13, "    "))
  repeat j from 0 to 9
    pst.dec(j)
    pst.char($20)
    pst.char($20)
  pst.char(13)
  repeat j from 0 to len
    if(j == 0)
      pst.dec(0)
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
    if((j+1) // 10 == 0) 
      pst.char($0D)
      pst.dec((j+10)/10)
      pst.char($20)
      if((j+10)/10 < 10)
        pst.char($20)  
  pst.char(13)
      
PUB PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
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