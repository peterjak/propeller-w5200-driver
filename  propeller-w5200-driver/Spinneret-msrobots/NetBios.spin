'':::::::[ NetBios ]::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
{{
''
''AUTHORS:          Mike Gebhard / Michael Sommer
''COPYRIGHT:        See LICENCE (MIT)    
''LAST MODIFIED:    10/04/2013
''VERSION:          1.0
''LICENSE:          MIT (see end of file)
''
''
''DESCRIPTION:
''                  The NETBIOS object - original file was NetBiosUnitTest
''
'' This program partially implements NetBIOS name services
''                * sending Registration
''                * sending NB Name Query Response                                          
''                * sending NBSTAT Name Query Response
''
''RESOURCES:
''                  http://tools.ietf.org/html/rfc1001
''                  http://tools.ietf.org/html/rfc1002
''                  http://ubiqx.org/cifs/NetBIOS.html
''
''MODIFICATIONS:
'' 9/2/2013         original file was NetBiosUnitTest.spin
''                  created NetBios shrunk down as much as possible
''                  added hostname. and workgoup to Init
''10/04/2013        added spindoc comments
''                  Michael Sommer (MSrobots)
''
'' Form a DOS prompt run nbtstat -a PROPNET.
''-----------------------------------------------------
'' C:\>nbtstat -a PROPNET
''
'' Local Area Connection:
'' Node IpAddress: [192.168.1.103] Scope Id: []
''
''         NetBIOS Remote Machine Name Table
''
''     Name               Type         Status
''  ---------------------------------------------
''  PROPNET        <00>  UNIQUE      Registered
''  WORKGROUP      <00>  GROUP       Registered
''
''  MAC Address = 00-08-DC-16-F8-01
''-----------------------------------------------------
''
'' From a DOS prompt execute ping PROPNET
''-----------------------------------------------------
'' C:\>ping PROPNET
'' 
'' Pinging PROPNET [192.168.1.107] with 32 bytes of data:
'' 
'' Reply from 192.168.1.107: bytes=32 time<1ms TTL=128
'' Reply from 192.168.1.107: bytes=32 time<1ms TTL=128
'' Reply from 192.168.1.107: bytes=32 time<1ms TTL=128
'' Reply from 192.168.1.107: bytes=32 time<1ms TTL=128
'' 
'' Ping statistics for 192.168.1.107:
''    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
'' Approximate round trip times in milli-seconds:
''    Minimum = 0ms, Maximum = 0ms, Average = 0ms
''
''Error messages
''-------------------
''RCODE field values:
''
''Symbol    Value   Description:
''
''FMT_ERR     0x1   Format Error.  Request was invalidly
''                  formatted.
''SRV_ERR     0x2   Server failure.  Problem with NBNS, cannot
''                  process name.
''IMP_ERR     0x4   Unsupported request error.  Allowable only
''                  for challenging NBNS when gets an Update type
''                  registration request.
''RFS_ERR     0x5   Refused error.  For policy reasons server
''                  will not register this name from this host.
''ACT_ERR     0x6   Active error.  Name is owned by another node.
''CFT_ERR     0x7   Name in conflict error.  A UNIQUE name is owned by more than one node.
}}
CON                                                     
''
''=======[ Global CONstants ... ]=========================================================
  ZERO                          = $00
  CR                            = $0D
  LF                            = $0A
  SPACE                         = $20
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
  #0, OK, FMT_ERR, SRV_ERR, IMP_ERR, RFS_ERR, ACT_ERR, CFT_ERR

  NB                            = $20
  NB_STAT                       = $21

  { Packet Enum}
  TRANSACTION_ID                = $00
  FLAGS                         = $02
  QUESTIONS                     = $04
  ANSWERS                       = $06
  AUTHORITY                     = $08
  ADDITIONAL                    = $0A
  QUERY                         = $0C
  NB_1                          = $2E
  IN_1                          = $30
  TTL                           = $32
  DATA_LEN                      = $36
  NB_FLAGS                      = $38
  NB_IP                         = $3A

  { CheckSocket Enum }
  CHECKSOCKET_NOTHING           = $0
  CHECKSOCKET_NB_SEND           = $1
  CHECKSOCKET_NBSTAT_SEND       = $2
  CHECKSOCKET_OTHER             = $3

''     
''=======[ Global DATa ]==================================================================
DAT
  
  encName          byte $0[33], $00
  encGroup         byte $0[33], $00
  encServer        byte $0[33], $00
  wildcard         byte $0[33], $00
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

''
''=======[ Used OBJects ]=================================================================
OBJ
  sock          : "Socket"
  wiz           : "W5100"

''
''=======[ PUBlic Spin Methods]===========================================================
PUB Init(buffer, socket, hostname , workgroup) | tr1, tr2, tr3 'Init NetBios and register hostname and workgroup
{{
''Init:             Init NetBios and register hostname and workgroup
''Returns:          0 success >0 NetBios Err ... see RCODE field values in CON section
}}
  _buffPtr := buffer
  _sockId  := socket  
  ' Fill the hostname and workgroup into nbStatQueryResp
  bytemove(@nbStatQueryResp+57,hostname,strsize(hostname) <# 15 )               ' host name
  bytemove(@nbStatQueryResp+75,workgroup,strsize(workgroup) <# 15)              ' group
  bytemove(@nbStatQueryResp+93,hostname,strsize(hostname) <# 15 )               ' host FileServer
                  
  'encode names  
  FirstLevelEncode(@wildcard, string("*"), ZERO, $00)
  FirstLevelEncode(@encName, hostname, SPACE, $00)
  FirstLevelEncode(@encGroup, workgroup, SPACE, $00)
  FirstLevelEncode(@encServer, hostname, SPACE, $20)                   
  
  'Fill in MAC & IP
  bytemove(@nbMac, wiz.GetMac, 6)
  bytemove(@ipReg, wiz.GetIp, 4)
  bytemove(@ipResp, wiz.GetIp, 4)
  
  ReInitSocket
  
  'Create a unique IDs
  tr1 := CreateTransactionId($FFFF)
  tr2 := CreateTransactionId($FFFF)
  tr3 := CreateTransactionId($FFFF)

  'Broadcast NetBIOS on port 137
  'Send the name registration request 3 times
  'If we do not get a response then the name is available
  
  nbNameReg[2] := $29                                   'RD bit 1 - NAME REGISTRATION REQUEST
  repeat 3
    sendRegister(tr1, @encName, 0)                      'no group
    sendRegister(tr2, @encServer, 0)                    'no group
    sendRegister(tr3, @encGroup, $80)                   'group
' should be inside repeat?
  sock.Available
  repeat
      if CheckSocket == CHECKSOCKET_OTHER               'not sure here... check needed?
        RESULT := (wiz.DeserializeWord(_buffPtr+constant(FLAGS+8)) & $000F)
          if (RESULT)
            return RESULT
  until _lastReadSize == 0
    
  nbNameReg[2] := $28                                   'RD bit 0 - NAME OVERWRITE DEMAND
  sendRegister(tr1, @encName, 0)                        'no group
  sendRegister(tr2, @encServer, 0)                      'no group
  sendRegister(tr3, @encGroup, $80)                     'group    

PUB CheckSocket  | avail, needed, ptr, name             'checks NetBios Name Service and if there processes one request
{{
''CheckSocket:      Checks NetBios Name Service and if there processes one request
''Returns:          see CheckSocket Enum values in CON section
                    buffer contains last received request/response
}}
  _lastReadSize := 0
  if sock.DataReady > 0                                 'Any Data ?
    if ((avail := waitForCountBytes(8)) => 8)           'Header Data in the buffer?
      sock.Receive(_buffPtr, 8)                         'Get udp header
      needed := wiz.DeserializeWord(_buffPtr + 6)       'size packet
      if ((avail := waitForCountBytes(needed)) => needed)'Data there?
        sock.Receive(_buffPtr+8, needed)
        _lastReadSize := needed + 8                     'remember last block size
        RESULT := CHECKSOCKET_OTHER                     'return typ 3 other as default
        
        ifnot ((byte[_buffPtr+constant(FLAGS+8)] & $80) == $80) ' just requests no responses            
          ptr := 0                                      'nothing
          name := _buffPtr+constant(QUERY+1+8)          'adress of query name
          byte[@ipResp-2] := 0                          'no group
          if strcomp(name,@encName)                     'query for host workstation?
            ptr := @encName
          elseif strcomp(name,@encServer)               'query for host server?
            ptr := @encServer
          elseif strcomp(name,@wildcard)                'query for wildcard?
            ptr := @wildcard
          elseif strcomp(name,@encGroup)                'query for group?
            byte[@ipResp-2] := $80                      'group
            ptr := @encGroup
                   
          if ptr                                        'query for me?  
            case wiz.DeserializeWord(_buffPtr + constant(NB_1+8)) 'what typ?
              NB:  
                sendResponse(ptr, @nbPosQueryResp, constant(@enbPosQueryResp - @nbPosQueryResp))            
                RESULT := CHECKSOCKET_NB_SEND           'return typ 1 response (nbpos host/group)
              NB_STAT:
                sendResponse(ptr, @nbStatQueryResp, constant(@enbStatQueryResp - @nbStatQueryResp))            
                RESULT := CHECKSOCKET_NBSTAT_SEND       'return typ 2 response (nbstat host/group)
     
PUB DisconnectSocket | tmp                              'processes all outstanding requests and disconnect Multi-Socket
{{
''DisconnectSocket: Processes all outstanding requests and disconnect Multi-Socket
}}
  repeat
    CheckSocket
  until (_lastReadSize == 0)
  sock.Disconnect
  
PUB ReInitSocket | tmp                                  'ReInit Mult-Socket for NetBios
{{
''ReInitSocket:     ReInit Mult-Socket for NetBios
}}
  sock.Init(_sockId, UDP, 137) 
  sock.RemoteIp($FF, $FF, $FF, $FF)
  sock.RemotePort(137)
  sock.Open

PUB SendQuery(queryname, pad, suffix, nbstat)           'Still Debug - send Query
{{
''SendQuery:        Still Debug - send Query
}}
  if nbstat
    byte[@nbNameQueryReq+3]  := $00                     'no Broadcast
    byte[@enbNameQueryReq-3] := NB_STAT                 'nb status query
    sock.RemoteIp(192, 168, 1, 105)  
  else
    byte[@nbNameQueryReq+3]  := $10                     'Broadcast
    byte[@enbNameQueryReq-3] := NB                      'nb name query 
    sock.RemoteIp($FF, $FF, $FF, $FF)  
  RESULT := word[@nbNameQueryReq] := CreateTransactionId($FFFF) 
  FirstLevelEncode(@nbNameQueryReq+13, queryname, pad, suffix)
  sock.Send(@nbNameQueryReq, constant(@enbNameQueryReq - @nbNameQueryReq))
  sock.Available  '?

PUB GetLastReadSize | tmp                               'get lastReadSize .. size last recived frame
{{
''GetLastReadSize:  Get lastReadSize .. size last recived frame
}}
  RESULT :=  _lastReadSize 

PUB GetLastIP | tmp                                     'Still Debug - Get Ip ?not needed?
{{
''GetLastIP:        Still Debug - Get Ip ?not needed?
}}
  RESULT :=  _buffPtr + constant(@ipResp - @nbPosQueryResp+8) 'adr ip

PUB DecodeLastNameInplace | tmp                         'Still Debug - decode Name in buffer for readability
{{
''DecodeLastNameInplace: Still Debug - decode Name in buffer for readability
}}
  FirstLevelDecode(_buffPtr+21, _buffPtr+21)
  
PUB GetLastName | tmp                                   'Still Debug - give address of (decoded?) Name
{{
''GetLastName:      Still Debug - give address of (decoded?) Name
}}
  RESULT := _buffPtr+21

''
''=======[ PRIvate Spin Methods ... ]=====================================================
PRI SendRegister(trn, encn, grp)                        'send register request
{{
''SendRegister:     Send register request
}}
  byte[@ipReg-2] := grp                           
  word[@nbNameReg] := trn  
  bytemove(@nbNameReg+13, encn, 32)
  sock.Send(@nbNameReg, constant(@enbNameReg - @nbNameReg))
   
PRI SendResponse(name, response, size)                  'answer query
{{
''SendResponse:     Answer query
}}
  sock.RemoteIp(byte[_buffPtr], byte[_buffPtr+1], byte[_buffPtr+2], byte[_buffPtr+3])
  bytemove(response, _buffPtr+8, 2)                     'set trn
  bytemove(response+13, name, 32)                       'set name
  sock.Send(response, size)
  sock.RemoteIp($FF, $FF, $FF, $FF)  
                                       
PRI WaitForCountBytes(count)                            'wait for count bytes on socket
{{
''WaitForCountBytes: Wait for count bytes on socket
}}
  RESULT := sock.DataReady
  if RESULT < count                                     'If to less data
    RESULT := sock.Available                            'wait for more
    if RESULT < count                                   'still to less data ... 
        sock.Disconnect                                 'error - reinit
        ReInitSocket                                    
        RESULT := 0
      
PRI FirstLevelEncode(dest, source, pad, suffix) | char, size 'Encode the name
{{
''FirstLevelEncode: Encode Name
}}
  size := strsize(source) <# 15  
  repeat size                                           'Encode the name
    char := byte[source++] & $FF
    byte[dest++] := (char >> 4) + $41
    byte[dest++] := (char & $0F) + $41    
  repeat 15 - size                                      'Pad spaces/zeros
    byte[dest++] := (pad >> 4) + $41
    byte[dest++] := (pad & $0F) + $41  
  byte[dest++] := (suffix >> 4) + $41                   'Add the suffix
  byte[dest++] := (suffix & $0F) + $41

PRI FirstLevelDecode(dest, source)                      'Decode Name
{{
''FirstLevelDecode: Decode Name
}}
  repeat 15
    byte[dest++] := ((byte[source++] - $41) << 4) + (byte[source++] - $41)
  byte[dest++] := "#"  
  if (RESULT := byte[source++] - $11) > $39
    RESULT += 7     
  byte[dest++] := RESULT 
  if (RESULT := byte[source++] - $11) > $39
    RESULT += 7     
  byte[dest++] := RESULT 
  byte[dest++] := 0 'terminate string
   
PRI CreateTransactionId(mask)                           'Create Random TransactionId
{{
''CreateTransactionId: Create Random TransactionId
}}
  RESULT := CNT
  ?RESULT
  RESULT &= mask

''
''=======[ MIT License ]==================================================================
CON                                                     'MIT License
{{{
 ______________________________________________________________________________________
|                            TERMS OF USE: MIT License                                 |                                                            
|______________________________________________________________________________________|
|Permission is hereby granted, free of charge, to any person obtaining a copy of this  |
|software and associated documentation files (the "Software"), to deal in the Software |
|without restriction, including without limitation the rights to use, copy, modify,    |
|merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    |
|permit persons to whom the Software is furnished to do so, subject to the following   |
|conditions:                                                                           |
|                                                                                      |
|The above copyright notice and this permission notice shall be included in all copies |
|or substantial portions of the Software.                                              |
|                                                                                      |
|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   |
|INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         |
|PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    |
|HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF  |
|CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE  |
|OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                         |
|______________________________________________________________________________________|
}} 