'*********************************************************************************************
{
AUTHOR: Mike Gebhard / Michael Sommer (@MSrobots)
COPYRIGHT: Parallax Inc.
LAST MODIFIED: 9/2/2013
VERSION 1.0
LICENSE: MIT (see end of file)

DESCRIPTION:
  The NETBIOS object  - original file was NetBiosUnitTest

  This program partially implements NetBIOS name services
        * Registration
        * NB Name Query                                                     
        * NBSTAT Name Query 

RESOURCES:
  http://tools.ietf.org/html/rfc1001
  http://tools.ietf.org/html/rfc1002
  http://ubiqx.org/cifs/NetBIOS.html

MODIFICATION:
  9/2/2013      original file was NetBiosUnitTest.spin
                created NetBios shrunk down as much as possible
                added hostname. and workgoup to Init
                Michael Sommer (MSrobots)

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
CFT_ERR       0x7   Name in conflict error.  A UNIQUE name is owned by more than one node.
}
'*********************************************************************************************
CON 
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
  encName          byte $0[33], $00
  encGroup         byte $0[33], $00
  encServer        byte $0[33], $00
                                                        '             R      ATRR   
                                                        '             E      ACDA   B
                                                        '             Q OPcd NMflags  Rcode
  nbNameReg        byte $68, $C8, $29, $10,             { trn flags: %0_0101_001000_1_0000
}                       $00, $01, $00, $00,             { QDcnt ANcnt (Questions[1] Answers)    
}                       $00, $00, $00, $01,             { NScnt ARcnt (Authority Additional[1]) - end header 
}                       $20, $0[32], $00,               { Question Name
}                       $00, $20, $00, $01,             { Qtype NB Qclass IN
}                       $C0, $0C,                       { ptr RR_NAME
}                       $00, $20, $00, $01,             { Rtype NB Rclass IN
}                       $00, $00, $00, $00,             { infinite TTL for broadcast 
}                       $00, $06, $00, $00              { RDlen(6) NB_FLAGS %0_00_00000_00000000}
  ipReg            byte $C0, $A8, $01, $68              { NB address (IP) }
  enbNameReg       byte 0
                                                         '%1_0000_101000_1_0000 wrong $85 $10
  nbPosQueryResp   byte $68, $C8, $85, $00,             { trn flags: %1_0000_101000_0_0000
}                       $00, $00, $00, $01,             { Questions Answers[1] 
}                       $00, $00, $00, $00,             { Authority Additional - end header 
}                       $20, $0[32], $00,               { RP_NAME
}                       $00, $20, $00, $01,             { NB IN
}                       $00, $04, $90, $E0,             { TTL = 10 minutes
}                       $00, $06, $00, $00              { NB_FLAGS %0_00_00000_00000000 }
  ipResp           byte $C0, $A8, $01, $68              { NB address (IP) }                       
  enbPosQueryResp  byte 0

                                                       '              R      ATRR   
                                                        '             S      ACDA   B
                                                        '             P OPcd NMflags  Rcode
  nbStatQueryResp  byte $68, $C8, $84, $00,             { trn flags: %1_0000_100000_0_0000
}                       $00, $00, $00, $01,             { Questions Answers[1] 
}                       $00, $00, $00, $00,             { Authority Additional - end header
}                       $20, $0[32], $00,               { RP_NAME (offset 13)
}                       $00, $21, $00, $01,             { NB IN
}                       $00, $00, $00, $00,             { 0 (TTL has no meaning in this context)
}                       $00, $66, $03,                  { Len = 102; names = 3 (*18) + 48
}                       "               ", $00,         { Hostname (offset 57)
}                       $04, $00,                       { flag ACT (active)
}                       "               ", $00,         { Workgroup (offset 75)
}                       $84, $00,                       { flag G (Group) ACT (active) 
}                       "               ", $20,         { Hostname (offset 93) FileServerService
}                       $04, $00                        { ACT (active) }    
  nbMac            byte $00, $08, $DC, $16, $F8, $01,   { MAC               
}                       $00, $00, $00, $00, $00, $00,   { Jumpers; test; version; stats
}                       $00, $00, $00, $00, $00, $00,   { CRC, alignment error; collitions
}                       $00, $00, $00, $00, $00, $00,   { aborts;  sends 
}                       $00, $00, $00, $00, $00, $00,   { receives; retransmits
}                       $00, $00, $00, $00, $00, $00,   { no resource; command block; pending session
}                       $00, $00, $00, $00, $00, $00,   { max pend sessions; max sessions; Session data size
}                       $00, $00, $00, $00, $00, $00    { padding }            
  enbStatQueryResp byte 0

                                                        '             R      ATRR   
                                                        '             E      ACDA   B
                                                        '             Q OPcd NMflags  Rcode
  nbNameQueryReq   byte $68, $C8, $01, $10,             { trn flags: %0_0000_001000_1_0000
}                       $00, $01, $00, $00,             { QDcnt ANcnt (Questions[1] Answers)    
}                       $00, $00, $00, $00,             { NScnt ARcnt (Authority Additional) - end header 
}                       $20, $0[32], $00,               { Question Name
}                       $00, $20, $00, $01              { Qtype NB Qclass IN }
  enbNameQueryReq  byte 0
  
  _buffPtr         long  $00
  _sockId          long  $00
  _lastReadSize    long  $00    ' last bytes read in sendreceive
  null             long  $00 

OBJ
  sock          : "Socket"
  wiz           : "W5100"

PUB Init(buffer, socket, hostname , workgroup) | ptr , tr1, tr2, tr3

  _buffPtr := buffer
  _sockId  := socket
  
  ' Fill the hostname and workgroup into nbStatQueryResp
  bytemove(@nbStatQueryResp+57,hostname,strsize(hostname) <# 15 )               ' host name
  bytemove(@nbStatQueryResp+75,workgroup,strsize(workgroup) <# 15)              ' group
  bytemove(@nbStatQueryResp+93,hostname,strsize(hostname) <# 15 )               ' host FileServer
  
  'Fill the encoded hostname into our 3 packets types
  
  FirstLevelEncode(@encName, hostname, $00)
  FirstLevelEncode(@encGroup, workgroup, $00)
  FirstLevelEncode(@encServer, hostname, $20)                          
  
  'Fill in MAC & IP
  bytemove(@nbMac, wiz.GetMac, 6)
  bytemove(@ipReg, wiz.GetIp, 4)
  bytemove(@ipResp, wiz.GetIp, 4)
  
  ReInitSocket
  
  'Create a unique IDs
  tr1 := CreateTransactionId($FFFF)
  tr2 := CreateTransactionId($FFFF)
  tr2 := CreateTransactionId($FFFF)

  'Broadcast NetBIOS on port 137
  'Send the name registration request 3 times
  'If we do not get a response then the name is available
  nbNameReg[2] := $29 ' RD bit 1 -  NAME REGISTRATION REQUEST
  repeat 3
    sendRegister(tr1, @encName, 0)                    ' no group
    sendRegister(tr2, @encServer, 0)                  ' no group
    sendRegister(tr3, @encGroup, $80)                 ' group

  sock.Available
  repeat
      if CheckSocket == 3
        RESULT := (DeserializeWord(_buffPtr+constant(FLAGS+8)) & $000F)
          if (RESULT)
            return RESULT
  until _lastReadSize == 0
    
  nbNameReg[2] := $28 ' RD bit 0 -  NAME OVERWRITE DEMAND 
  sendRegister(tr1, @encName, 0)                      ' no group
  sendRegister(tr2, @encServer, 0)                    ' no group
  
  return null         

PRI sendRegister(trn, encn, grp) 
  byte[@ipReg-2] := grp                           
  word[@nbNameReg] := trn  
  bytemove(@nbNameReg+13, encn, 32)
  sock.Send(@nbNameReg, constant(@enbNameReg - @nbNameReg))
   
PRI waitForBytes(count)
  RESULT := sock.DataReady
  if RESULT < count                                       ' If to less data
    RESULT := sock.Available                              ' wait for more
    if RESULT < count                                     ' still to less data ... 
        DisconnectSocket                                  ' error - reinit
        ReInitSocket
        RESULT := 0
      
PUB CheckSocket  | avail, needed, ptr
  _lastReadSize := 0
  if ((avail := waitForBytes(8)) => 8)                  'Header Data in the buffer?
    sock.Receive(_buffPtr, 8)                           'Get udp header
    needed := DeserializeWord(_buffPtr + 6)             'size packet
    if ((avail := waitForBytes(needed)) => needed)      'Data there?
      sock.Receive(_buffPtr+8, needed)
      _lastReadSize := needed + 8                       'remember last block size
      RESULT := 3                                       ' return typ 3 other  
      ifnot ((byte[_buffPtr+constant(FLAGS+8)] & $80) == $80) ' just requests no responses  
        'Is this broadcast for ME?
        ptr := 0
        if strcomp(_buffPtr+constant(QUERY+1+8),@encName)
          ptr := @encName
        elseif strcomp(_buffPtr+constant(QUERY+1+8),@encServer)
          ptr := @encServer        
                  
        if ptr                                              ' query for hostname?  
          case DeserializeWord(_buffPtr + constant(NB_1+8))
            NB:  
              byte[@ipResp-2] := 0                          ' no group
              sendResponse(ptr, @nbPosQueryResp, constant(@enbPosQueryResp - @nbPosQueryResp))            
              RESULT := 11                                  ' return typ 11 response (nbpos host)
            NB_STAT:
              sendResponse(ptr, @nbStatQueryResp, constant(@enbStatQueryResp - @nbStatQueryResp))            
              RESULT := 12                                  ' return typ 12 response (nbstat host)
            other:
              RESULT := 1                                   ' return typ 1 no response (host but not answered)
        elseif strcomp(_buffPtr+constant(QUERY+1+8),@encGroup) ' query for group?
          case DeserializeWord(_buffPtr + constant(NB_1+8))
            NB:  
              byte[@ipResp-2] := $80                        ' group
              sendResponse(@encGroup, @nbPosQueryResp, constant(@enbPosQueryResp - @nbPosQueryResp))            
              RESULT := 21                                  ' return typ 21 response (nbpos group)
            other:
              RESULT := 2                                   ' return typ 2 response (group but not answered)           

PRI sendResponse(name, response, size)
  'Set the target IP address to requester
  sock.RemoteIp(byte[_buffPtr], byte[_buffPtr+1], byte[_buffPtr+2], byte[_buffPtr+3])
  bytemove(response, _buffPtr+8, 2)             'set trn
  bytemove(response+13, name, 32)               'set name
  sock.Send(response, size)
  sock.RemoteIp(255, 255, 255, 255)  
   
PUB DisconnectSocket
  sock.Disconnect
  sock.Close
  
PUB ReInitSocket
  sock.Init(_sockId, UDP, 137)
  'sock.RemoteIp(192, 168, 1, 255)
  sock.RemoteIp(255, 255, 255, 255)
  sock.RemotePort(137)
  sock.Open

PUB SendNameQuery(queryname, suffix) 
  RESULT := word[@nbNameQueryReq] := CreateTransactionId($FFFF) 
  FirstLevelEncode(@nbNameQueryReq+13, queryname, suffix)
  sock.Send(@nbNameQueryReq, constant(@enbNameQueryReq - @nbNameQueryReq))
 ' bytemove(_buffPtr,@nbNameQueryReq, constant(@enbNameQueryReq - @nbNameQueryReq)) 
  sock.Available  '?

PUB GetLastReadSize
  return _lastReadSize 

PUB DecodeLastNameInplace | ptr, address , value
  address := _buffPtr+21
  ptr := address
  repeat 15
    byte[ptr++] := ((byte[address++] - $41) << 4) + (byte[address++] - $41)
  byte[ptr++] := "#"  
  if (value := byte[address++] - $11) > $39
    value += 7     
  byte[ptr++] := value 
  if (value := byte[address++] - $11) > $39
    value += 7     
  byte[ptr++] := value 
  byte[ptr++] := 0 'trminate string 
   
PUB GetLastName
  'DecodeNameInplace(_buffPtr+21)
  return _buffPtr+21
  
PUB GetLastIP
RESULT := _buffPtr + constant(@ipResp - @nbPosQueryResp+8) ' adr ip

PRI FirstLevelEncode(dest, source, suffix) | char, ptr, size
  ptr  := source
  size := strsize(source) <# 15
  if ((size == 1) and (byte[ptr] == "*"))
    char := byte[ptr++] & $FF
    byte[dest++] := (char >> 4) + $41
    byte[dest++] := (char & $0F) + $41
    'Pad zeros
    repeat 14
      byte[dest++] := $43
      byte[dest++] := $41     
  else
    'Encode the name
    'pst.str(string("01234567012345670123456701234567", CR))
    repeat size
      char := byte[ptr++] & $FF
      byte[dest++] := (char >> 4) + $41
      byte[dest++] := (char & $0F) + $41     
    'Pad spaces
    repeat 15 - size
      byte[dest++] := $43
      byte[dest++] := $41
     
    'Add the suffix
  byte[dest++] := (suffix >> 4) + $41
  byte[dest++] := (suffix & $0F) + $41

PRI CreateTransactionId(mask)
  RESULT := CNT
  ?RESULT
  RESULT &= mask
{
PRI IsError(buffer) | ptr
  ifnot(buffer == @null)
    RESULT := DeserializeWord(buffer+FLAGS) & $000F

PRI SendReceive(buffer, len)    
  sock.Open
  sock.Send(buffer, len)
  _lastReadSize := sock.Available  
  if(_lastReadSize > 0 )                                  
    RESULT := sock.Receive(_buffPtr, _lastReadSize)         'Get the Rx buffer into main buff, not own DAT
  else                                             
    RESULT := @null                                'timeout
    _lastReadSize := 0
  sock.Disconnect
}
PRI DeserializeWord(buffer) 
  RESULT := byte[buffer++] << 8
  RESULT += byte[buffer]

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