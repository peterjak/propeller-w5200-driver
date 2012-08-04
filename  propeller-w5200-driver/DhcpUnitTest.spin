CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  NULL          = $00
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

       
VAR

DAT
  DHCPDISCOVER   byte $01, $01, $06, $00, { Options: OP, HTYPE, HLEN, HOPS
}                     $39, $03, $F3, $26, { Trqansaction ID
}                     $00, $00, $00, $00, { SECS, FLAGS
}                     $00, $00, $00, $00, { Client IP
}                     $00, $00, $00, $00, { Your IP
}                     $00, $00, $00, $00, { Server IP
}                     $00, $00, $00, $00, { Gateway IP
}                     $00, $08, $DC, $16, { Mac (client hardware address)
}                     $F8, $01, $00, $00, { Padding
}                     $00, $00, $00, $00, { Padding 
}                     $00, $00, $00, $00, { Padding
}                     $0[64], $0[128],    { 0x44 Host name |  Boot file name
}                     $63, $82, $53, $63, { Magic cookie
}                     $35, $01, $01,      { DHCP Message = Discover
}                     $32, $04, $C0, $A8, $01, $6B, { IP Request
}                     $37, $04, $01, $03, $06, $2A, { Paramter Request; mask, router, domain name server, network time 
}                     $FF 
  padDiscover    byte $0[$200]
                                            
  DHCPREQUEST    byte $01, $01, $06, $00, { Options: OP, HTYPE, HLEN, HOPS
}                     $39, $03, $F3, $26, { Trqansaction ID
}                     $00, $00, $00, $00, { SECS, FLAGS
}                     $00, $00, $00, $00, { Client IP
}                     $00, $00, $00, $00, { Your IP
}                     $C0, $A8, $01, $01, { Server IP
}                     $00, $00, $00, $00, { Gateway IP switched by relay
}                     $00, $08, $DC, $16, { Mac (client hardware address)
}                     $F8, $01, $00, $00, { Padding
}                     $00, $00, $00, $00, { Padding 
}                     $00, $00, $00, $00, { Padding
}                     $0[192],            { overflow space for additional options 
}                     $63, $82, $53, $63, { Magic cookie
}                     $35, $01, $03,                    { DHCP Message  = Request
}                     $32, $04, $C0, $A8, $01, $82,     { Requested IP
}                     $36, $04, $C0, $A8, $01, $01,     { DHCP Server
}                     $FF
  padRequest       byte $0[$200]
  
  buff          byte  $0[BUFFER_2K]
OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  wiz           : "W5200"


 
PUB Main | bytesToRead, buffer, bytesSent, receiving, ptr, len
  {{
    TODO: Make the Demo
  }}
  bytesToRead := 0
  pst.Start(115_200)
  pause(500)

  'bytemove(@DHCPDISCOVER + (4*11), string("PropNet"), strsize(string("PropNet")))
  'bytemove(@DHCPREQUEST + (4*11), string("PropNet"), strsize(string("PropNet"))) 

  len := @padDiscover - @DHCPDISCOVER
  'len := @padRequest - @DHCPREQUEST
  
  len += len // 16 + 16
  pst.str(string("DHCP Options Len: "))
  pst.dec(len)
  pst.char(CR)


  pst.str(string("Initialize", CR))

  'Wiz Mac and Ip
  wiz.Init
  wiz.SetIp(192, 168, 1, 107)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  
  'DHCP Port
  buffer := sock.Init(0, UDP, 68)

  'Broadcast
  sock.RemoteIp(255, 255, 255, 255)
  sock.RemotePort(67)
  
  pst.str(string("Start UPD Client",CR))
  pst.str(string("Open",CR))
  sock.Open
  
  pst.str(string("Send Message",CR))
  
  sock.Send(@DHCPDISCOVER, len)
  'sock.Send(@DHCPREQUEST, len)

  receiving := true
  repeat while receiving 
    'Data in the buffer?
    bytesToRead := sock.Available
    pst.str(string("Bytes to Read: "))
    pst.dec(bytesToRead)
    pst.char(13)
    pst.char(13)
     
    'Check for a timeout
    if(bytesToRead == -1)
      receiving := false
      pst.str(string("Fail safe", CR))
      next

    if(bytesToRead == 0)
      receiving := false
      pst.str(string("Done", CR))
      next 

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      ptr := sock.Receive(@buff)
      pst.char(CR)
      pst.str(string("UPD Header:",CR))
      PrintIp(@buff)
      pst.dec(DeserializeWord(@buff + 4))
      pst.char(CR)
      pst.dec(DeserializeWord(@buff + 6))
      pst.char(CR)
       
      pst.char(CR) 
      DisplayMemory(ptr, DeserializeWord(@buff + 6), true) 
      pst.char(CR)
      
    bytesToRead~

  pst.str(string(CR, "Disconnect", CR)) 
  sock.Disconnect

  
   
  DisplayMemory(ptr, 36, true)



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