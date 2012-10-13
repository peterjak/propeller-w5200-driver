'*********************************************************************************************
{
 AUTHOR: Mike Gebhard
 COPYRIGHT: Parallax Inc.
 LAST MODIFIED: 10/08/2012
 VERSION 1.0
 LICENSE: MIT (see end of file)

DESCRIPTION:
  Unit test the NetBIOS protocol using a WizNet 5200 and Propeller. This test
  will attempt to register the name PROPNET on the local network.
  If the name PROPNET is unique then we can register the name and IP.

  This program partially implements NetBIOS name services
        * Registration
        * NB Name Query 
        * NBSTAT Name Query 

RESOURCES:
  http://tools.ietf.org/html/rfc1001
  http://tools.ietf.org/html/rfc1002
  http://ubiqx.org/cifs/NetBIOS.html

OPERATION:
 Make sure to configure MAC and IP for your network.
   ' SPI pins
  SPI_MOSI          = 1 ' SPI master out serial in to slave
  SPI_SCK           = 0 ' SPI clock from master to all slaves
  SPI_CS            = 3 ' SPI chip select (active low)
  SPI_MISO          = 2 ' SPI master in serial out from slave

  Run the code and start the serial terminal.

  Form a DOS prompt run nbtstat -a PROPNET.
----------------------------------------------------- 
  C:\>nbtstat -a PROPNET

  Local Area Connection:
  Node IpAddress: [192.168.1.103] Scope Id: []

           NetBIOS Remote Machine Name Table

       Name               Type         Status
    ---------------------------------------------
    PROPNET        <00>  UNIQUE      Registered
    WORKGROUP      <00>  GROUP       Registered

    MAC Address = 00-08-DC-16-F8-01
-----------------------------------------------------
  
  From a DOS prompt execute ping PROPNET
----------------------------------------------------- 
  C:\>ping PROPNET
   
  Pinging PROPNET [192.168.1.107] with 32 bytes of data:
   
  Reply from 192.168.1.107: bytes=32 time<1ms TTL=128
  Reply from 192.168.1.107: bytes=32 time<1ms TTL=128
  Reply from 192.168.1.107: bytes=32 time<1ms TTL=128
  Reply from 192.168.1.107: bytes=32 time<1ms TTL=128
   
  Ping statistics for 192.168.1.107:
      Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
  Approximate round trip times in milli-seconds:
      Minimum = 0ms, Maximum = 0ms, Average = 0ms

----------------------------------------------------- 


-------------------
Error messages
-------------------  
RCODE field values:
 
Symbol      Value   Description:
 
FMT_ERR       0x1   Format Error.  Request was invalidly
                    formatted.
SRV_ERR       0x2   Server failure.  Problem with NBNS, cannot
                    process name.
IMP_ERR       0x4   Unsupported request error.  Allowable only
                    for challenging NBNS when gets an Update type
                    registration request.
RFS_ERR       0x5   Refused error.  For policy reasons server
                    will not register this name from this host.
ACT_ERR       0x6   Active error.  Name is owned by another node.
CFT_ERR       0x7   Name in conflict error.  A UNIQUE name is
}
'*********************************************************************************************                       owned by more than one node.

CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K         = $800
  BUFFER_16         = $10
  
  CR                = $0D
  LF                = $0A
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
  #0, OK, FMT_ERR, SRV_ERR, IMP_ERR, RFS_ERR, ACT_ERR, CFT_ERR

  NB            = $20
  NB_STAT       = $21  

  {{ Packet Enum}}
  TRANSACTION_ID    = $00
  FLAGS             = $02
  QUESTIONS         = $04
  ANSWERS           = $06
  AUTHORITY         = $08
  ADDITIONAL        = $0A
  QUERY             = $0C
  NB_1              = $2E
  IN_1              = $30
  TTL               = $32
  DATA_LEN          = $36
  NB_FLAGS          = $38
  NB_IP             = $3A               
       
VAR

DAT
  'WORKSTATION
  'PROPNET
  workspace       byte  $0[BUFFER_16]  
  buff            byte  $0[BUFFER_2K]
  group           byte  "WORKGROUP", $00 
  nbName          byte  "PROPNET", $00
  
  encName         byte  $0[33], $00
  nbNameReg       byte  $68, $C8, $29, $10,             { %0_0101_001000_1_0000
}                       $00, $01, $00, $00,             { 
}                       $00, $00, $00, $00,             {
}                       $20, $0[32], $00,               { Question Name
}                       $00, $20, $00, $01,             { NB IN
}                       $C0, $0E, $00, $00,             { PR_NAME
}                       $00, $20, $00, $01,             { NB IN
}                       $00, $04, $90, $E0,             { TTL = 10 minutes 
}                       $00, $06, $00, $00,             { NB_FLAGS %0_00_00000_00000000
}                       $C0, $A8, $01, $6B              { NB address (IP) }
  enbNameReg      byte  0

  nbPosQueryResp  byte  $68, $C8, $85, $00,             { %1_0000_101000_1_0000
}                       $00, $00, $00, $01,             { Questions Answers 
}                       $00, $00, $00, $00,             { Authority Additional
}                       $20, $0[32], $00,               { RP_NAME
}                       $00, $20, $00, $01,             { NB IN
}                       $00, $04, $90, $E0,             { TTL = 10 minutes
}                       $00, $06, $00, $00,             { NB_FLAGS %0_00_00000_00000000
}                       $C0, $A8, $01, $6B              { NB address (IP) }                       
  enbPosQueryResp byte  0

  nbStatQueryResp  byte $68, $C8, $84, $00,             { 
}                       $00, $00, $00, $01,             { Questions Answers 
}                       $00, $00, $00, $00,             { Authority Additional
}                       $20, $0[32], $00,               { RP_NAME
}                       $00, $21, $00, $01,             { NB IN
}                       $00, $00, $00, $00,             { TTL = 10 minutes
}                       $00, $54, $02,                  { Len = 30; names = 2
}                       "PROPNET        ", $00,         {
}                       $04, $00,                       {
}                       "WORKGROUP      ", $00,         {
}                       $84, $00,                       {
}                       $00, $08, $DC, $16, $F8, $01,   { MAC
}                       $00, $00, $00, $00, $00, $00,    { Jumpers; test; version; stats
}                       $00, $00, $00, $00, $00, $00,    { CRC, alignment error; collitions
}                       $00, $00, $00, $00, $00, $00,    { aborts;  sends 
}                       $00, $00, $00, $00, $00, $00,    { receives; retransmits
}                       $00, $00, $00, $00, $00, $00,    { no resource; command block; pending session
}                       $00, $00, $00, $00, $00, $00,    { max pend sessions; max sessions; Session data size
}                       $00, $00, $00, $00, $00, $00    { padding }            
  enbStatQueryResp byte 0


  buffPtr         long  $00
  transId         long  $00
  null            long  $00 

OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  wiz           : "W5200"

PUB Main | ptr, bytesToRead

  buffPtr := @buff

  pst.Start(115_200)
  pause(500)
  
  FirstLevelEncode(@encName, @nbName, $00)

  'Fill the encoded name our 3 packets types
  bytemove(@nbNameReg[13], @encName, 32)
  bytemove(@nbPosQueryResp[13], @encName, 32)
  bytemove(@nbStatQueryResp[13], @encName, 32)  
  
  pst.str(string("Initialize", CR))

  'Create a unique ID
  CreateTransactionId($FFFF)
  FillTransactionID
  
  'Set network parameters
  wiz.Init
  wiz.SetCommonnMode(0)
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 107)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)

  'Broadcast NetBIOS on port 137
  sock.RemoteIp(192, 168, 1, 255)
  sock.RemotePort(137)
  pause(500)

  'Send the name registration request 6 times
  'If we do not get a response then the name "PROPNET" is available
  {   } 
  repeat 6
    ptr := Register
    ifnot(ptr == @null)
      pst.str(string(CR, "Not NULL", CR))
      if(IsError(ptr))
        pst.str(string("Error ID: "))
        pst.dec(IsError(ptr))
        return  

  pst.str(@nbName)
  pst.str(string(" is available on the network!"))

  word[@nbPosQueryResp] := transId
  repeat
    sock.Open
    
    'Data in the buffer?
    repeat until null <  bytesToRead := sock.Available
  
    'Get the Rx buffer  
    sock.Receive(@buff, bytesToRead)
    PrintDebug(@buff, bytesToRead)

    'Is this broadcast for PROPNET?
    if(IsMine(@buff + 8))
      'Set the target IP address to requester
      sock.RemoteIp(byte[@buff], byte[@buff+1], byte[@buff+2], byte[@buff+3])

      if(IsNbType(@buff + 8))
        bytemove(@nbPosQueryResp, @buff+8, 2)
        sock.Send(@nbPosQueryResp, @enbPosQueryResp - @nbPosQueryResp)

      if(IsNbStatType(@buff + 8))
        bytemove(@nbStatQueryResp, @buff+8, 2)
        sock.Send(@nbStatQueryResp, @enbStatQueryResp - @nbStatQueryResp)
    else
      pst.str(string("*** Not For Me ***")) 

    pause(100)
    sock.Disconnect
    
    bytesToRead~

PUB PrintDebug(buffer,bytesToRead)
  pst.char(CR)
  pst.str(string(CR, "Request from: "))
  PrintIp(buffer)
  pst.char(":")
  pst.dec(DeserializeWord(buffer + 4))
  pst.str(string(" ("))
  pst.dec(DeserializeWord(buffer + 6))
  pst.str(string(")", CR))
   
  DisplayMemory(buffer+8, bytesToRead-8, true)  

PUB IsMine(buffer)
 return strcomp((buffer+QUERY+1),@encName)

PUB GetNbType(buffer)
  return DeserializeWord(buffer+NB_1)  

PUB IsNbType(buffer)
  return DeserializeWord(buffer+NB_1) == NB

PUB IsNbStatType(buffer)
  return DeserializeWord(buffer+NB_1) == NB_STAT  
  
PUB FirstLevelEncode(dest, source, suffix) | char, ptr
  ptr := source

  'Encode the name
  'pst.str(string("01234567012345670123456701234567", CR))
  repeat strsize(source)
    char := byte[ptr++] & $FF
    byte[dest++] := (char >> 4) + $41
    byte[dest++] := (char & $0F) + $41

  'Pad spaces
  repeat 15 - strsize(source)
    byte[dest++] := $43
    byte[dest++] := $41

  'Add the suffix
  byte[dest++] := (suffix >> 4) + $41
  byte[dest++] := (suffix & $0F) + $41    
    
    
PUB IsError(buffer) | ptr
  if(buffer == @null)
      return 0
  return DeserializeWord(buffer+FLAGS) & $000F


PUB Register | ptr
  return SendReceive(@nbNameReg, @enbNameReg - @nbNameReg )                                  


PUB CreateTransactionId(mask)
  transId := CNT
  ?transId
  transId &= mask

PUB FillTransactionID
  word[@nbNameReg] := transId
    
PUB SendReceive(buffer, len) | bytesToRead, ptr 
  
  bytesToRead := 0

  pst.str(string("Send Bytes......."))
  pst.dec(len)             
  pst.char(CR)

  sock.Open
  sock.Send(buffer, len)
  
  pause(500)

  bytesToRead := sock.Available
  pst.str(string("Bytes to Read...."))
  pst.dec(bytesToRead)
  pst.char(13)
  pst.char(13)
   
  'Check for a timeout
  if(bytesToRead =< 0 )
    bytesToRead~
    return @null

  if(bytesToRead > 0) 
    'Get the Rx buffer  
    ptr := sock.Receive(buffer, bytesToRead)
    PrintDebug(buffer,bytesToRead)

  sock.Disconnect
  return ptr


PUB TxRaw(addr, len) | i
  repeat 5
    pst.char("*")
  repeat i from 0 to len-1
    pst.char(byte[addr][i])
  repeat 5
    pst.char("*")

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
      'pst.char($0D)
      
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