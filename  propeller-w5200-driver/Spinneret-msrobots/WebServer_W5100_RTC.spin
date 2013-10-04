'':::::::[ Server_W5100_RTC ]:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
{{
''
''AUTHORS:          Mike Gebhard / Michael Sommer
''COPYRIGHT:        Parallax Inc.
''LAST MODIFIED:    10/04/2013
''VERSION:          1.0
''LICENSE:          MIT (see end of file)
''
''
''DESCRIPTION:
''                  The MAIN webserver object for spinneret
''
''NOTE:             Please change MAC address below at top of the first
''                  CON section to the number on the back of your spinneret.
''        
''                  You also may need to change the hostname and workgroup at top of the
''                  DAT section if you need more then one spineret in the same network.
''
''MODIFICATIONS:
'' 8/31/2013        added support for OPTIONS,HEAD,PUT,MKCOL,DELETE (minimal PROPFIND)
''                  added SetHostname to DHCP
''                  added support for dynamic PASM pages/responses (and some demos)     
'' 9/26/2013        commented out alot of unused methods
''                  commented sourcecode and added some spindoc comments
''                  added netbios
''                  did some optimisation for size ... running out of space ...
'' 9/30/2013        replaced PST by fullDuplexSerial4port
''10/04/2013        added spindoc comments
''                  Michael Sommer (MSrobots)
}}
CON                                                     
''
''=======[ Global CONstants ... ]=========================================================
{{
''
'' YOU MUST CHANGE MAC_1 TO MAC_6 HERE TO AVOID CONFLICTS IN YOUR NETWORK
'' please change MAC address below to the numbers on the back of your spinneret.
''
}}
''-------[ Hardware Configuration ]-------------------------------------------------------
  _clkmode          = xtal1 + pll16x     
  _xinfreq          = 5_000_000
  
  'wiz.SetMac($00, $08, $DC, $16, $F1, $32)             'MAC Mike G

  MAC_1             = $00                               'MAC MSrobots          ' 
  MAC_2             = $08
  MAC_3             = $DC
  MAC_4             = $16
  MAC_5             = $F0
  MAC_6             = $4F

  { Serial IO PINs } 
  USB_Rx            = 31
  USB_Tx            = 30

''-------[ Web Server Configuration ]-----------------------------------------------------
  SOCKETS           = 4                                 '4 w5100 8 w5200

  MULTIUSE_SOCK     = SOCKETS -1                        'sock 3   (7) used for DHCP, NETBIOS and SNTP
  HTTPSOCKETS       = MULTIUSE_SOCK -1                  'sock 0-2 (6) used for http
  ATTEMPTS          = 5

  { Port Configuration }
  HTTP_PORT         = 80
  SNTP_PORT         = 123

  { SD IO }
  DISK_PARTION      = 0 
  SUCCESS           = -1
  IO_OK             = 0
  IO_READ           = "r"
  IO_WRITE          = "w"
  IO_APPEND         = "a"

  { Content Types }
  #0, CSS, GIF, HTML, ICO, JPG, JS, PDF, PNG, TXT, XML, ZIP
  
  { USA Standard Time Zone Abbreviations}
  #-10, HST,AtST,_PST,MST,CST,EST,AlST

  GMT               = 0
  AZ_TIME           = 1
              
  { USA Daylight Time Zone Abbreviations   }
  #-9, HDT,AtDT,PDT,MDT,CDT,EDT,AlDT

  Zone = MST        '<- Insert your timezone

''-------[ PSX/PSE CMDS ... ]-------------------------------------------------------------
  { PSX CMDS }    
  REQ_PARA_STRING   = 1
  REQ_PARA_NUMBER   = 2
  REQ_FILENAME      = 3
  REQ_HEADER_STRING = 4
  REQ_HEADER_NUMBER = 5
  
  SEND_FILE_EXT     = 11
  SEND_SIZE_HEADER  = 12
  SEND_DATA         = 13
  SEND_STRING       = 14
  SEND_FLUSH        = 15
  SEND_FILE_CONTENT = 16        
  
  CHANGE_DIRECTORY  = 21
  LIST_ENTRIES      = 22
  LIST_ENTRY_ADDR   = 23        
  CREATE_DIRECTORY  = 24        ' todo (MKcol already there)
  DELETE_ENTRY      = 25        ' todo (Delete already there)      
  FILE_WRITE_BLOCK  = 26        
  FILE_READ_BLOCK   = 27        
  
  PSE_CALL          = 91
  PSE_TRANSFER      = 92

''-------[ Other constants  ... ]---------------------------------------------------------
  TCP_MTU           = 1460
  BUFFER_3K         = $C00
  BUFFER_LOG        = $80
  BUFFER_WS         = $20
  BUFFER_SNTP       = 48+8 
  
  CR                = $0D
  LF                = $0A

  RTC_CHECK_DELAY   = 4_000_000  '1_000_000 = ~4 minutes

''=======[ Global DATa ]==================================================================
{{
''
'' YOU MAY NEED TO CHANGE hostname AND workgroup HERE TO AVOID CONFLICTS IN YOUR NETWORK
''
}}
DAT                                                      
  hostname      byte  "PROPNET",0 '<- you need to change this if you have more then one spineret
  'workgroup     byte  "WORKGROUP", 0
  workgroup     byte  "MSROBOTS", 0
  
  version       byte  "1.2", $0
  
  time          byte  "00/00/0000 00:00:00", 0
  hasSd         byte  $00
  wizver        byte  $00
  dhcpRenew     byte  $00

  divider       byte  CR, "-----------------------------------------------", CR, $0

  _404          byte  "HTTP/1.1 404 OK", CR, LF,                                {
}                     "Content-Type: text/html", CR, LF, CR, LF,                {
}                     "<html>",                                                 {
}                     "<head>",                                                 {
}                     "<title>Not Found</title><head>",                         {
}                     "<body>",                                                 {
}                     "Page not found!",                                        {                                                                                                       
}                     "</body>",                                                {
}                     "</html>", CR, LF
  _404end       byte  0
  xmlPinState   byte  "<root>", CR, LF, "  <pin>" 
  pinNum        byte  $30, $30, "</pin>", CR, LF, "  <value>"
  pinState      byte  $30, $30, "</value>", CR, LF, "  <dir>" 
  pinDir        byte  $30, $30, "</dir>", CR, LF,                               {
}                     "</root>", 0

  xmlTime       byte  "<root>", CR, LF, "  <time>" 
  xtime         byte  "00/00/0000 00:00:00</time>", CR, LF, "  <day>"
  xday          byte  "---","</day>", CR, LF, "</root>", $0

  _optallow     byte  "Allow:"
  _optallowend
  _optpublic    byte  "Public:"
  _optpublicend  
  _options      byte  " OPTIONS, HEAD, GET, POST, PUT, MKCOL, DELETE, PROPFIND"
                'byte  "Allow: OPTIONS, HEAD, GET, POST, PUT, MKCOL, DELETE, PROPFIND, PROPPATCH, COPY, MOVE, LOCK, UNLOCK", CR, LF
                'byte  "Public: OPTIONS, HEAD, GET, POST, PUT, MKCOL, DELETE, PROPFIND", CR, LF
                'byte  "DAV: 1",CR, LF           ' ,2,3
                'byte  "MS-Author-Via: DAV", CR, LF
'                byte  "Content-Length: 0", CR, LF
  _optionsend   
  
  _h100         byte  "HTTP/1.1 100 Continue"
  _h100end      byte  $0      
  _h200         byte  "HTTP/1.1 200 OK"
  _h200end      byte  $0    
  _h201         byte  "HTTP/1.1 201 Created"
  _h201end      byte  $0   
  _h207         byte  "HTTP/1.1 207 Multi-Status"
  _h207end      byte  $0      
  _h403         byte  "HTTP/1.1 403 Forbidden"
  _h403end      byte  $0  
'  _h404         byte  "HTTP/1.1 404 Not Found", CR, LF
'  _h404end      byte  $0 
  _h409         byte  "HTTP/1.1 409 Conflict"
  _h409end      byte  $0
  
  _css          byte  "Content-Type: text/css", $0
  _gif          byte  "Content-Type: image/gif", $0
  _html         byte  "Content-Type: text/html", $0
  _ico          byte  "Content-Type: image/x-icon", $0
  _jpg          byte  "Content-Type: image/jpeg", $0
  _js           byte  "Content-Type: application/javascript", $0
  _pdf          byte  "Content-Type: application/pdf", $0
  _png          byte  "Content-Type: image/png", $0 
  _txt          byte  "Content-Type: text/plain; charset=utf-8", $0  
  _xml          byte  "Content-Type: text/xml", $0
  _zip          byte  "Content-Type: application/zip", $0
  _contLen      byte  "Content-Length: "
  _contlenend   byte  $0          
  _newline      byte  CR, LF
  _newlineend   byte  $0
  

' now all long aligned
  outBufPtr     long  0 ' used for delayed writing

  pse           long
                byte "PSE",0
  psx           long
                byte "PSX",0

  buff          long
                byte  $0[BUFFER_3K]
  sntpBuff      byte  $0[BUFFER_SNTP]
  workSpace     byte  $0[BUFFER_WS]
  logBuf        byte  $0[BUFFER_LOG]
  null          long  $00
  
  contentType   long  @_css, @_gif, @_html, @_ico, @_jpg, @_js, @_pdf, @_png, @_txt, @_xml, @_zip, $0
  mtuBuff       long  TCP_MTU
  
  longHIGH      long  0         'Expected 4-contigous variables for SNTP
  longLOW       long  0
  MM_DD_YYYY    long  0
  DW_HH_MM_SS   long  0

''
''=======[ Used OBJects ]=================================================================
OBJ                                                     
  ser               : "fullDuplexSerial4port" 
  rtc               : "S35390A_RTCEngine" 
  sd                : "S35390A_SD-MMC_FATEngineWrapper"
  wiz               : "W5100"                           
  sock[SOCKETS]     : "Socket"
  dhcp              : "Dhcp"
  netbios           : "NetBios"
  req               : "HttpHeader"
  sntp              : "SNTP Simple Network Time Protocol v2.01"

''
''=======[ PUBlic Spin Methods]===========================================================
PUB RunServer : value                                   'Run Server
{{
''RunServer:        STARTUP Server
}}
  '---------------------------------------------------
  'Reset wiznet
  '---------------------------------------------------
  wiz.HardReset(WIZ#WIZ_RESET)                          'A hardware reset can take 1.5 seconds before the Sockets are ready to Send/Receive                           
  pause(500)
  '---------------------------------------------------
  'Start the 4-port Serial driver              (1 cog)
  '---------------------------------------------------
  ser.Init                                              'so we can start some driver before we proceed ... first start Serial
  ser.AddPort(0,USB_Rx,USB_Tx,ser#PINNOTUSED,ser#PINNOTUSED,ser#DEFAULTTHRESHOLD,ser#NOMODE,ser#BAUD115200)
  ser.Start
  pause(500)
  '---------------------------------------------------
  'Initialize the Realtime clock library
  '--------------------------------------------------- 
  rtc.RTCEngineStart(29, 28, -1)                        'needed? sd should do this or not ?
  '---------------------------------------------------
  'Start the SD Driver and Mount the SD card   (1 cog) 
  '--------------------------------------------------- 
  sd.Start                                              'next start sd driver
  pause(500)
  value := sd.mount(DISK_PARTION)                       'and try to mount first partition
  hasSd := strcomp(value, string("OK"))                 'set hasSd flag if mounted  
  '--------------------------------------------------- 
  'Start the WizNet SPI driver                 (1 cog)
  '--------------------------------------------------- 
  wiz.Start(WIZ#SPI_CS, WIZ#SPI_SCK, WIZ#SPI_MOSI, WIZ#SPI_MISO)
  wizver := GetVersion                                  'Verify SPI connectivity by reading the WizNet 5100 version register
  if(wizver == 0)
    PrintStr(string(CR, CR, "SPI communication to WizNet failed!", CR, "Check connections", CR))
    return                                              'ERROR - DONE!
  wiz.SetMac(MAC_1,MAC_2,MAC_3,MAC_4,MAC_5,MAC_6)       'MAC (Source Hardware Address) must be unique on the local network
  '---------------------------------------------------
  'Display Version and Cog Usage
  '--------------------------------------------------- 
  PrintStrStr(string(CR,"Init RTC: "),FillTime(@time))
  PrintStrStr(string(CR, "COG[0]: Spinneret Web Server v"),@version)
  PrintStr(string(CR, "COG[1]: Parallax Serial Terminal"))
  PrintStrDecStr(string(CR, "COG["), sd.GetCogId, string("]: SD Driver - "))
  PrintStr(value) 
  PrintStrDecStr(string(CR, "COG["), wiz.GetCogId, string("]: Started W5100 SPI Driver - "))   
  PrintStrDec(string("WizNet 5100 Connected; Reg(0x19) = "), wizver)    
  PrintStr(string(CR, "COG[n]: 4 COGs in Use"))   
  PrintStr(@divider)  
  '--------------------------------------------------- 
  'Invoke DHCP to retrive network parameters            
  '---------------------------------------------------
  ifnot DoDhcp(false)                                   'This assumes the WizNet 5100 is connected to a router with DHCP support
    return                                              'ERROR - DONE! 
  '--------------------------------------------------- 
  'Invoke NetBios to register hostname and group
  '---------------------------------------------------
  PrintStr(string(CR, "Register with NetBios ... ")) 
  value := netbios.Init(@Buff, MULTIUSE_SOCK, @hostname, @workgroup)
  if value > 0                                          'if you end up here the name could not be registered
    PrintStrDec(string("NetBios Error ID: "), value)    ' most common is name conflict of hostname - rename hostname at top of first dat section
    nbDebug(3,true)
    return                                              'ERROR - DONE! ?
  else
    PrintStrStr(@hostname, string(" registered", CR))   'now we can be found by NetBios name!
  '--------------------------------------------------- 
  'Snyc the RTC using SNTP
  '---------------------------------------------------
  PrintStrStr(string(CR, "Sync RTC with Time Server"), @divider)                                                   
  if(SyncSntpTime)
    PrintStr(string("NTP Server IP....."))
    PrintIpCR(dhcp.GetNtpServer)
    PrintStr(string("Web time.........."))
    DisplayHumanTime
  else
    PrintStr(string(CR, "Sync failed"))
  '--------------------------------------------------- 
  ' Set DHCP renew -> (Current hour + 12) // 24
  '---------------------------------------------------
  SetDhcpRenew
  '--------------------------------------------------- 
  'Start up the app server
  '---------------------------------------------------
  PrintStrStr(string(CR, "Initialize Sockets"), @divider)
  repeat value from 0 to HTTPSOCKETS                    'Do this for all HTTPSOCKETS
    sock[value].Init(value, WIZ#TCP, HTTP_PORT)         ' Init Socket as HTTP
    sock[value].Open                                    ' Open and start Listen
    PrintStrDec(string(CR, "Socket "), value)
    if(sock[value].Listen)                              ' if ok report status
      PrintStrDec(string(": Port="), sock[value].GetPort)
      PrintStrDec(string("; MTU="), sock[value].GetMtu)
      PrintStrDec(string("; TTL="), sock[value].GetTtl)
    else                                                ' if not
      PrintStr(string(": Listener failed"))             '   report failure           
  mtuBuff := sock[0].GetMtu                             'get current mtu and save in setting  
  '--------------------------------------------------- 
  'Run Server - catch exceptions
  '---------------------------------------------------
  PrintStr(string(CR, "Start Server", CR))
  value :=  \Server                                     'now run Server/ ... ex. MultiSocketService
  '--------------------------------------------------- 
  'Handle exceptions
  '---------------------------------------------------
  PrintStrDec(string(CR, "Fatal Error!!! "), value)     'if we are here something went way wrong
  if (strsize(value)<200)                               'is tmp maybe string?
    PrintStr(value)                                     '  well try out and see
  PrintStr(string(CR, "Rebooting..."))
  pause(1000) 
  reboot                                                'ERROR - DONE!

'' 
''=======[ PRIvate Spin Methods ... ]=====================================================
PRI Server : handled | bytesToRead, sockId, rtcDelay, JustHeader, filename, ticks 'Main Program Loop (Spin cog 0)
{{
''Server:           Main Program Loop (Spin cog 0)
}}
  bytesToRead := sockId := rtcDelay := 0                'Init local vars
  repeat    '                                           'Repeat forever or until an exception kills us
    repeat                                              'Cycle through the sockets one at a time looking for a connections
      handled := netbios.CheckSocket                    '  run netbios loop
      nbDebug(handled,false)                            '  just for debug ... Request data still in Buffer                                
      if(++rtcDelay//RTC_CHECK_DELAY == 0)              '  check for timeout of DHCP renewal
        rtc.readTime
        if(rtc.clockHour == dhcpRenew)                  '  if needed 
          RenewDhcpLease                                '    renew DHCP 
        rtcDelay~                                       '  reset timeout

        if InputAvailableBytes(0) > 0                                
          bytesToRead := 0 ' do nothing yet, debug      todo
        
      sockId := ++sockId // constant(HTTPSOCKETS+1)     '  check next socket 
    until sock[sockId].Connected                        'until any (sockID) socket is connected
        
    PrintStrDecStr(string(CR, CR, "sockID: "), sockId, @divider)'now handle this request on the socket sockID
    ticks := cnt
    repeat until bytesToRead := sock[sockId].Available  'Repeat until we have data in the buffer
    if(bytesToRead =< 0)                                'Check for a timeout error
      PrintStrDec(string(CR, "Timeout: "), bytesToRead) ' print out error message and request size
      PrintAllStatuses                                  ' and Status - done with this request!
    else
      sock[sockId].Receive(@buff, bytesToRead)          'Move the Rx buffer into HUB memory
      PrintStr(@buff)                                   'Display the request header      
      req.TokenizeHeader(@buff, bytesToRead)            'Tokenize and index the header
      filename := req.GetFileName                       'get request pathfilename
      PrintStr(filename)                                'Display request pathfilename
      handled := false                                  'preset not found
      JustHeader := false                               'preset not just header (HEAD verb)
      outBufPtr := @Buff                                'used for delayed writing (global)
     
      ifnot strcomp(@buff, string("GET"))               'if GET verb just move on ...
        handled := true                                 'preset found (done with this request)
        if strcomp(@buff, string("PROPFIND"))           'if PROPFIND verb 
          handled := PseHandler(sockId, string("/PROPFIND.PSE"), false) ' run PASM extension for PROPFIND
        elseif strcomp(@buff, string("MKCOL"))          'if MKOL verb create directory and report result - done with this request!       
          handled := SendFlushOKorERR(sockId, not (sd.newDirectory(filename) == true),@_h201, constant(@_h201end-@_h201), @_h409, constant(@_h409end-@_h409))
        elseif strcomp(@buff, string("DELETE"))         'if DELETE verb delete file/directory and report result - done with this request!   
          handled := SendFlushOKorERR(sockId, not (sd.deleteEntry(filename) == true),@_h200, constant(@_h200end-@_h200), @_h409, constant(@_h409end-@_h409))
        elseif OptionsHandler(sockId, filename)         'if OPTIONS verb handle it and report result - done with this request!   
        elseif PutHandler(sockId, filename)             'if PUT verb handle it and report result - done with this request!
        else
          handled := false                              'preset not found - not handled yet
          if (strcomp(@buff, string("HEAD")))           'if HEAD verb
            JustHeader := true                          '  set JustHeader flag
                      
      ifnot handled                                     'if request not handled
        if PsxHandler(sockId, filename, JustHeader)     'if psx/pse run PASM pages/requests (also propfind) - done with this request!
        elseif FileHandler(sockId, filename, JustHeader, false)'if file on sd send it - done with this request!
        elseif RenderDynamic(sockId, JustHeader)        'if RenderDynamic send it  - done with this request! 
        else
          sock[sockId].Send(@_404, constant(@_404end - @_404)) ' if all fail send 404  - done with this request! 
    sock[sockId].Disconnect                             'reset just USED socket - and leave all other sockets alone - all done!  
    'sock[sockId].Close                                 'Close the socket, reset the interupt register and reopen listener
    'sock[sockId].SetSocketIR($FF)                       '?needed?
    sock[sockId].Open
    sock[sockId].Listen
    ticks :=  cnt-ticks
    PrintStrDec(string(CR, "Ticks: "), ticks)
    PrintStrDec(string(" ms: "), ticks / (clkfreq / 1_000))
                                                        'wash rinse repeat with next socket
''-------[ Response Handler ... ]---------------------------------------------------------
PRI BuildStatusHeader(sockID, status, contentLength) | src 'write HEADER into outBuf
{{
''BuildStatusHeader: write HEADER into outBuf
}}
  SendStrCRLF(sockID, status)                           'write Status
  SendStrCRLF(sockID, GetContentType(req.GetFileNameExtension)) 'write ContentType
  if(contentLength > -1)                                'if >-1 Add content-length : value CR, LF
    SendBytes(sockID, @_contLen, constant(@_contlenend-@_contLen))
    SendStrCRLF(sockID, Dec(contentLength))
  SendCRLF(sockID)                                      'End the header with a new line
      
PRI FileHandler(sockID, fn, JustHeader, NoHeader) | fs, bytes 'Handle static File Requests
{{
''FileHandler:      Handle static File Requests
}}
  if FileOpen(fn, IO_READ)                              'Render a static file from the SD Card
    mtuBuff := sock[sockID].GetMtu                      'get mtu of socket
    fs := sd.getFileSize                                'and get size
    ifnot NoHeader
      BuildStatusHeader(sockID, @_h200, fs)             'amd create header
    SendFlushOutBuf(sockID)                           '  flush out
    ifnot JustHeader                                    'if request was HEAD
      repeat                                            'the offset is just used on the first chunk
        if(fs < mtuBuff)                                'if it fits into the buffer
          bytes := fs                                   '  we are done!
        else                                            
          bytes := mtuBuff                              'else send mtu bytes
        sd.readFromFile(@buff, bytes)                   'read (remaining) bytes into buffer
        fs -= sock[sockID].Send(@buff, bytes)           'send buffer and subtract size send
      until fs =< 0        
    sd.closeFile
    outBufPtr := @Buff                                  'reset bufptr   
    RESULT := true                                      'we are done! 

PRI OptionsHandler(sockID, fn) | options                'Handle OPTIONS Requests
{{
''OptionsHandler:   Handle OPTIONS Requests
}}
  if strcomp(@buff, string("OPTIONS"))                  'is it OPTIONS verb?
    SendBytesCRLF(sockID, @_h200, constant(@_h200end-@_h200))       'send 200 OK
    SendBytes(sockID, @_optallow, constant(@_optallowend-@_optallow)) 'allow:
    SendBytesCRLF(sockID, @_options, constant(@_optionsend-@_options)) 'send _options
    SendBytes(sockID, @_optpublic, constant(@_optpublicend-@_optpublic))'public:
    SendBytesCRLF(sockID, @_options, constant(@_optionsend-@_options)) 'send _options 
    SendBytes(sockID, @_contLen, constant(@_contlenend-@_contLen))
    SendStrCRLF(sockID, Dec(0))
    SendCRLF(sockID)                                    'send _newline
    SendFlushOutBuf(sockID)                             'flush out
    RESULT := true                                      'we are done!
    
PRI PutHandler(sockID, fn) | bytesToRead, size , status, noerr 'Handle PUT Requests
{{
''PutHandler:       Handle PUT Requests
}}
  if strcomp(@buff, string("PUT"))                      'is it PUT verb?
    status :=  @_h201                                   '201 created
    size := StrToBase(req.Header(string("Content-Length")) , 10)
    if FileOpen(fn, IO_READ)                            'if file already there
      status :=  @_h200                                 '   200 OK ( or 202 no Content?)
      sd.closeFile                                   
      \sd.deleteEntry(fn)                               '   delete file
    \sd.newFile(fn)                                     'new file
    sd.closeFile                                        
    noerr := sd.OpenFile(fn, IO_WRITE)                                 
    ifnot (noerr == true)                               'now open file write
      status :=  @_h409                                 '409 Conflict   
    else
      SendBytesCRLF(sockID, @_h100, constant(@_h100end-@_h100)) 'send 100 continue
      SendCRLF(sockID)                                  'send _newline   
      SendFlushOutBuf(sockID)
      repeat 
        repeat until bytesToRead := sock[sockID].Available 'Repeat until we have data in the buffer                          
        if(bytesToRead < 1)                             'Check for a timeout error  
          size := -1 'timeout / end
        else       
          sock[sockID].Receive(@buff, bytesToRead)      'Move the Rx buffer into HUB memory  
          size -= bytesToRead
          sd.writeData(@buff, bytesToRead)              'now write file         
      until size<1                                      'expecting size bytes
      sd.closeFile                                      'now close file
    RESULT := SendFlushOKorERR(sockID,false,status, strsize(status),0,0) ' send 409 Conflict 201 Created or 200 OK                           
  
PRI PsxHandler(sockID, fn, JustHeader) | ext            'Handle PSX Requests
{{
''PsxHandler:       Handle PSX Requests
}}
  ext := long[req.GetFileNameExtension] & (!$202020)    'convert to upper case
  if ext==psx '(ext==psx1) OR (ext==psx2)               'if psx extension
    RESULT := PseHandler(sockID, fn, JustHeader)        ' execute
  elseif ext==pse '(ext==pse1) OR (ext==pse2)           'if pse extension
    RESULT := SendFlushOKorERR(sockID,true,0, 0, @_h403, constant(@_h403end-@_h403)) ' send 403 Forbidden (no direct call allowed for pse)
 
PRI PseHandler(sockID, fn, JustHeader) | daisy, fs, psmptr, bufptr, cog, cmd, param1, param2 , param3, param4, param5, param6 'Handle PSE Requests
{{
''PseHandler:       Handle PSE Requests
}}
  cmd := param1 := param2 := param3 := param4 := param5 := param6 := 0
  repeat                             
    RESULT:= false                                                                        
    daisy := 0                                          'no DaisyChain yet
    if FileOpen(fn, IO_READ)                            'load PASM to end of Buffer
      fs := sd.getFileSize - 28                         'we just need Pasm block
      if fs>0 and fs<1985
        bufptr := (@buff+constant(BUFFER_3K-$400)) & $FFFFFC' last 1 kb buffer
        psmptr := (@buff-fs+BUFFER_3K) & $FFFFFC        'end buffer minus pasm size
        sd.readFromFile(bufptr, 24)                     'load fist 24 bytes and discard
        sd.readFromFile(psmptr, fs)                     'load pasm to end of buffer
      else
        fs := -1                                        'no pasm/wrong size
      sd.closeFile
      if fs>0                                           'if no error yet
        cmd := -1                                       'idle
        param1 := bufptr                                'output area for pasm at init      
        param2 := 0                                          
        cog := cognew(psmptr, @cmd) + 1                 'run pasm
        if cog                                          'if started
          PrintStrDecStr(string(CR, "using COG["), cog-1, string("].."))' show cog used and filename
          PrintStr(fn)                                  
          repeat 
            case cmd                                    'commands from PASM cog to spin
              REQ_PARA_STRING:                          'PASM request Param as String
                param1 := req.Get(@param1)              'Param1-4 CONTAIN string up to 15 letter+0
                param2 := strsize(param1)               'Param2 returns string size
                cmd := -1                               'Param1 returns address of string
              REQ_PARA_NUMBER:                          'PASM request Param as Number
                param2 := req.Get(@param1)              'Param1-4 CONTAIN string up to 15 letter+0
                param1 := StrToBase(param2 , 10)        'Param1 returns value as long
                param2 := strsize(param2)               'Param2 returns string size
                cmd := -1                                    
              REQ_FILENAME:                             'PASM request org. Filename
                param1 := req.GetFileName               '(used by propfind)
                cmd := -1                               'Param1 returns address of string   
              REQ_HEADER_STRING:                        'PASM request Header as string (used by propfind)
                param1 := req.Header(@param1)           'Param1-4 CONTAIN key up to 15 letter+0
                param2 := strsize(param1)               'Param2 returns string size
                cmd := -1                               'return address of string in Param1
              REQ_HEADER_NUMBER:                        'PASM request Header as number (used by propfind)
                param2 := req.Header(@param1)           'Param1-4 CONTAIN string up to 15 letter+0
                param1 := StrToBase(param2 , 10)        'Param1 returns value as long
                param2 := strsize(param2)               'Param2 returns string size
                cmd := -1                               'return value as long in Param1                
              SEND_FILE_EXT:
                if param1>0                             'PASM sends ext.
                  Bytemove(req.GetFileNameExtension,@param1,3) 'Param1 contains string up to 3 letter+0
                cmd := -1                               'idle - back to PASM
              SEND_SIZE_HEADER:                         'PASM sends size or -1
                if (param2==1)                          
                  BuildStatusHeader(sockID, @_h207, param1) 'send header 207 Multi-Status    
                else
                  BuildStatusHeader(sockID, @_h200, param1) 'send header 200 OK    
                if JustHeader                           'if request is HEAD
                  daisy := 0
                  cmd := 0                              '     exit 
                else
                  cmd := -1                             'idle - back to PASM
              SEND_DATA:                                'PASM sends data in bufptr
                SendBytes(sockID, param1, param2)       'param2 bytes at address param1
                cmd := -1                               'idle - back to PASM
              SEND_STRING:                              'PASM sends string in bufptr
                param2 := strsize(param1)               'returns aize in param2                  
                SendBytes(sockID, param1, param2)       'strsize bytes at address param1
                cmd := -1                               'idle - back to PASM
              SEND_FLUSH:
                SendFlushOutBuf(sockID)                 'send buffered output manual if needed
                cmd := -1                               'idle - back to PASM
              SEND_FILE_CONTENT:                        'param1 addr string path filename, param2 NoHeader 
                param1 := FileHandler(sockID, param1, false, param2)
                cmd := -1                               'idle - back to PASM
              CHANGE_DIRECTORY:                         'Change Directory param1 path
                param1 := sd.changeDirectory(param1)    'param1 addr string path
                sd.listEntry(string("."))               '? bug? needed or sd.listEntries wont work ?
                cmd := -1                               'idle - back to PASM   
              LIST_ENTRIES:                             'List Directory param1 "W" or "N"
                param1 := sd.listEntries(@param1)       'param1 contains string up to 3 letter+0
                cmd := -1                               'idle - back to PASM
              LIST_ENTRY_ADDR:                          'PASM needs sd directoryEntryCache    
                param1 := sd.GetADDRdirectoryEntryCache 'addr EntryCache
                cmd := -1                               'idle - back to PASM
              FILE_WRITE_BLOCK:                         'param1-4 filename, position, addressToGet, count
                param1 := FileWriteBlock(param1, param2, param3, param4)
                cmd := -1                               'idle - back to PASM
              FILE_READ_BLOCK:                          'param1-4 filename, position, addressToPut, count 
                param1 := FileReadBlock(param1, param2, param3, param4)
                cmd := -1                               'idle - back to PASM
                
              PSE_CALL:                                 'call pse
                SendFlushOutBuf(sockID)                 'flush out if not done yet
                fs := strsize(bufptr)                   'size request
                bytemove(@buff,bufptr,fs)               'move to buff
                req.TokenizeHeader(@buff, fs)           'tokenize
                param1:=PseHandler(sockID, req.GetFileName, false) ' call self with sub modul (new cog)
                cmd := -1                               'idle - back to PASM   
              PSE_TRANSFER:                             'dasychain pse
                SendFlushOutBuf(sockID)                 'flush out if not done yet
                fs := strsize(bufptr)                   'size request
                bytemove(@buff,bufptr,fs)               'move to buff                               
                req.TokenizeHeader(@buff, fs)           'tokenize
                fn := req.GetFileName                   'get pse filename
                daisy := 1                              'run in same cog
                cmd := 0                                'exit
          until cmd==0                                  '0 is exit                                              

          SendFlushOutBuf(sockID)                       'flush out if not done yet
                                      
          if cog                                        'shut down PASM cog (if still running?) and report it     
            PrintStrDecStr(string("..COG["), cog-1, string("] finished."))
            cogstop(cog~ - 1)
          RESULT := true                                'return succsess
  until (Daisy == 0)
  
PRI RenderDynamic(id, JustHeader)                       'Handle RenderDynamic Requests
{{
''RenderDynamic:    Handle RenderDynamic Requests 
}}
  'req.TokenizeFilename                                  ' now ready for RESTful stuff
  
  'Process pinstate
  
  if(strEndsWith(req.GetFileName, string("pinstate.xml")))
    BuildPinStateXml( req.Get(string("led")), req.Get(string("value")) )
    BuildStatusHeader(id, @_h200, -1)
    SendBytes(id, @xmlPinState, strsize(@xmlPinState))
    SendFlushOutBuf(id)
    return true

  if(strEndsWith(req.GetFileName, string("p_encode.xml")))
    BuildPinEndcodeStateXml( req.Get(string("value")) )
    BuildStatusHeader(id, @_h200, -1)
    SendBytes(id, @xmlPinState, strsize(@xmlPinState))
    SendFlushOutBuf(id)
    return true

  if(strEndsWith(req.GetFileName, string("time.xml")))
    FillTime(@xTime)
    FillDay(@xday)
    BuildStatusHeader(id, @_h200, -1)
    SendBytes(id, @xmlTime, strsize(@xmlTime))
    SendFlushOutBuf(id)
    return true
               
  if(strEndsWith(req.GetFileName, string("sntptime.xml")))
    SyncSntpTime
    FillTime(@xTime)
    FillDay(@xday) 
    BuildStatusHeader(id, @_h200, -1)
    SendBytes(id, @xmlTime, strsize(@xmlTime))
    SendFlushOutBuf(id)
    return true  

  return false
           
''-------[ Subs for RenderDynamic ... ]---------------------------------------------------
PRI strEndsWith(str1,str2) | lenmin, len1, len2, pos1, pos2 'checks if str1 ends with str2
  RESULT := true
  lenmin := len1 := strsize(str1)
  len2 := strsize(str2)  
  if len2 < lenmin
    lenmin := len2
  pos1 := str1 + len1
  pos2 := str2 + len2  
  repeat lenmin-1
    if (byte[--pos1] <> byte[--pos2])    
      RESULT := false

PRI BuildPinStateXml(strpin, strvalue) | pin, value, state, dir
  pin := StrToBase(strpin, 10)
  value := StrToBase(strvalue, 10)  

  SetPinState(pin, value)
  state := ReadPinState(pin)

  'Write the pin number to the XML doc
  if(strsize(strpin) > 1)
    bytemove(@pinNum,strpin, 2)
  else
    byte[@pinNum] := $30
    byte[@pinNum][1] := byte[strpin]

  'Write the pin value
  value := Dec(ReadPinState(pin))
  if(strsize(value) > 1)
    bytemove(@pinState, value, 2)
  else
    byte[@pinState] := $30
    byte[@pinState][1] := byte[value]

  'Write Pin direction
  dir := Dec(ReadDirState(pin))
  if(strsize(dir) > 1)
    bytemove(@pinDir, value, 2)
  else
    byte[@pinDir] := $30
    byte[@pinDir][1] := byte[dir]


PRI ReadDirState(pin)
  return dira[pin]
   
PRI ReadPinState(pin)
  return outa[pin] | ina[pin]
 
PRI SetPinState(pin, value)
  if(value == -1)
    return
  if(pin < 23 or pin > 27)
    return
      
  dira[pin]~~
  outa[pin] := value  


PRI BuildPinEndcodeStateXml(strvalue) | value, state, dir
  value := StrToBase(strvalue, 10)  

  'pst.dec(value)
  
  if(value > -1)
    SetEncodedPinstate(value)
    state := ReadEncodedPinState

  'Write the pin number to the XML doc
  bytemove(@pinNum,string("$F"), 2)

  'Write the pin value
  value := Dec(ReadEncodedPinState)
  if(strsize(value) > 1)
    bytemove(@pinState, value, 2)
  else
    byte[@pinState] := $30
    byte[@pinState][1] := byte[value]

  'Write Pin direction
  dir := Dec(ReadEncodedDirState)
  if(strsize(dir) > 1)
    bytemove(@pinDir, value, 2)
  else
    byte[@pinDir] := $30
    byte[@pinDir][1] := byte[dir]

    
PRI ReadEncodedDirState
  return dira[27..24]
   
PRI ReadEncodedPinState
  return outa[27..24] | ina[27..24]

PRI SetEncodedPinState(value)
  dira[27..24]~~
  outa[27..24] := value   
  
PRI ValidateParameters(pin, value)
  if(pin < 23 or pin > 27)
    return false
  if(value > 1 or value < -1)
    return false

  return true

''-------[ DHCP Handling ... ]------------------------------------------------------------
PRI RenewDhcpLease                                      'renews DHCP lease
{{
''RenewDhcpLease:   Renews DHCP lease
}}
  netbios.DisconnectSocket
  DoDhcp(true)  
  rtc.readTime
  SetDhcpRenew
  netbios.ReInitSocket
  
PRI SetDhcpRenew                                        'sets TimeOut for DHCP renewal - not happy with this
{{
''SetDhcpRenew:     Sets TimeOut for DHCP renewal - not happy with this
}}
  dhcpRenew := (rtc.clockHour + 12) // 24
  PrintStr(string("DHCP Renew........"))
  if(dhcpRenew < 10)
    PrintChar("0")
  PrintDec(dhcpRenew)
  PrintStr(string(":00:00",CR))

PRI DoDhcp(setRequestIp)                                'runs DHCP request. Prints Result
{{
''DoDhcp:           Runs DHCP request. Prints Result
}}
  PrintStrStr(string(CR,"Retrieving Network Parameters...Please Wait"), @divider)           
  if(InvokeDhcp(setRequestIp))                             
    PrintStrIPCR(string("Assigned IP......."), dhcp.GetIp)
    PrintStrDecStr(string("Lease Time........"), dhcp.GetLeaseTime,string(" (seconds)",CR))
    PrintStrIPCR(string("DNS Server........"), wiz.GetDns)
    PrintStrIPCR(string("NTP Server........"), dhcp.GetNtpServer)
    PrintStrIPCR(string("DHCP Server......."), dhcp.GetDhcpServer)
    PrintStrIPCR(string("Router............"), dhcp.GetRouter)
    PrintStrIPCR(string("Gateway..........."), wiz.GetGatewayIp)
    RESULT := true
  else
    if(dhcp.GetErrorCode > 0)
      PrintStrDec(string(CR, CR, "Error Code: "), dhcp.GetErrorCode)
      PrintChar(CR)
      PrintStr(dhcp.GetErrorMessage)
      PrintChar(CR)
                            
PRI InvokeDhcp(setRequestIp) | requestIp, i             'runs DHCP request. if setRequestIp == true then try to get old IP
{{
''InvokeDhcp:       Runs DHCP request. if setRequestIp == true then try to get old IP
}}
  dhcp.Init(@buff, MULTIUSE_SOCK)                       'initialize the DHCP object
  dhcp.SetHostname(@hostname)                           'hostname defined at top of first DAT section
  if setRequestIp                                       
    requestIp := dhcp.GetIp                             'Request an IP. The requested IP might not be assigned by DHCP
    dhcp.SetRequestIp(byte[requestIp][0],byte[requestIp][1],byte[requestIp][2],byte[requestIp][3])  
  i := 0 
  repeat until dhcp.DoDhcp(true)                        'Invoke the SHCP process
    if(++i > ATTEMPTS)
      return false  
  return true

''-------[ SNTP Handling ... ]------------------------------------------------------------
PRI SyncSntpTime | ptr                                  'runs SNTP request and if success set the RTC
{{
''SyncSntpTime:     Runs SNTP request and if success set the RTC
}}
  netbios.DisconnectSocket                              'free up MultiUseSocket
  ptr := dhcp.GetNtpServer                              'get addr of NtpServer IP
  sock[MULTIUSE_SOCK].Init(MULTIUSE_SOCK, WIZ#UDP, SNTP_PORT) 'Initialize the socket
  sock[MULTIUSE_SOCK].RemoteIp(byte[ptr][0], byte[ptr][1], byte[ptr][2], byte[ptr][3])
  sock[MULTIUSE_SOCK].RemotePort(SNTP_PORT)
  sntp.CreateUDPtimeheader(@sntpBuff)                   'create request
  ptr := SntpSendReceive(@sntpBuff, 48)                 'send and wait for answer
  if(ptr == @null)
    RESULT := false                                     'no answer - DONE!
  else
    'Set the time
    SNTP.GetTransmitTimestamp(Zone,@sntpBuff,@LongHIGH,@LongLOW)
    'PUB writeTime(second, minute, hour, day, date, month, year)                      
    rtc.writeTime(byte[@DW_HH_MM_SS][0],      { Seconds
                } byte[@DW_HH_MM_SS][1],      { Minutes
                } byte[@DW_HH_MM_SS][2],      { Hour
                } byte[@DW_HH_MM_SS][3],      { Day of week
                } byte[@MM_DD_YYYY][2],       { Day
                } byte[@MM_DD_YYYY][3],       { Month
                } word[@MM_DD_YYYY][0])       { Year}
    RESULT := true                                      'success - DONE!
  netbios.ReInitSocket                                  'use socket for netbios again
                                    
PRI SntpSendReceive(buffer, len) | bytesToRead          'sends SNTP request and waits for answer
{{
''SntpSendReceive:  Sends SNTP request and waits for answer
}}
  RESULT := @null
  sock[MULTIUSE_SOCK].Open                              'Open socket and Send Message
  sock[MULTIUSE_SOCK].Send(buffer, len)
  pause(500)                                            'needed?
  bytesToRead := sock[MULTIUSE_SOCK].Available
  if(bytesToRead =< 0 )                                 'Check for a timeout
    bytesToRead~
  else
    RESULT := sock[MULTIUSE_SOCK].Receive(buffer, bytesToRead) 'Get the Rx buffer
  sock[MULTIUSE_SOCK].Disconnect

PRI DisplayHumanTime                                    'prints Day and Time
{{
''DisplayHumanTime: Prints Day and Time
}}
    if byte[@MM_DD_YYYY][3]<10
       PrintChar("0")
    PrintDec(byte[@MM_DD_YYYY][3])
    PrintChar("/")
    if byte[@MM_DD_YYYY][2]<10
       PrintChar("0")
    PrintDec(byte[@MM_DD_YYYY][2])
    PrintChar("/")
    PrintDec(word[@MM_DD_YYYY][0])                    
    PrintChar($20)
    if byte[@DW_HH_MM_SS][2]<10
       PrintChar("0")
    PrintDec(byte[@DW_HH_MM_SS][2])
    PrintChar(":")
    if byte[@DW_HH_MM_SS][1]<10
       PrintChar("0")
    PrintDec(byte[@DW_HH_MM_SS][1])
    PrintChar(":")
    if byte[@DW_HH_MM_SS][0]<10
       PrintChar("0")
    PrintDec(byte[@DW_HH_MM_SS][0])
    PrintStr(string("(GMT "))
    if Zone<0
       PrintChar("-")
    else
       PrintChar("+")
    PrintStr(string(" ",||Zone+48,":00) ",CR))

    
PRI FillTime(addressToPut)                              'outputs rtc time to addressToPut (00/00/0000 00:00:00)
{{
''FillTime:         Outputs rtc time to addressToPut (00/00/0000 00:00:00)
}}
  rtc.readTime
  FillTimeHelper(rtc.clockMonth, addressToPut)
  addressToPut += 3
  FillTimeHelper(rtc.clockDate, addressToPut)
  addressToPut += 3
  FillTimeHelper(rtc.clockYear, addressToPut)
  addressToPut += 5
  FillTimeHelper(rtc.clockHour , addressToPut)
  addressToPut += 3
  FillTimeHelper(rtc.clockMinute , addressToPut)
  addressToPut += 3
  FillTimeHelper(rtc.clockSecond, addressToPut)
  return addressToPut-17

PRI FillDay(addressToPut)                               'outputs first 3 chars of rtc.getDayString to addressToPut
{{
''FillDay:          Outputs first 3 chars of rtc.getDayString to addressToPut
}}
  rtc.readTime
  bytemove(addressToPut, rtc.getDayString, 3)
  return addressToPut
  
PRI FillTimeHelper(value, addressToPut) | t1            'outputs a numeric value as string, min 2 digits to addressToPut
{{
''FillTimeHelper:   Outputs a numeric value as string, min 2 digits to addressToPut
}}
  if(value < 10)
    byte[addressToPut++] := "0"
  t1 := Dec(value)
  bytemove(addressToPut, t1, strsize(t1))

''-------[ Common Subs ... ]--------------------------------------------------------------
PRI GetVersion | i                                      'get Version from wizNet driver
{{
''GetVersion:       Get Version from wizNet driver
}}
  i := 0
  result := 0
  repeat until result > 0
    result := wiz.GetVersion
    if(i++ > ATTEMPTS*5)
      return 0
    pause(250)

PRI FileOpen(filename, action) | rc                     'open file for read return success
{{
''OpenFile:         Open file for read return success
}}
  if(hasSd)
    rc := sd.listEntry(filename)
    if(rc == IO_OK)
      rc := sd.OpenFile(filename, action)
        if(rc == SUCCESS)
          RESULT := true

PRI FileWriteBlock(filename, position, addressToGet, count)'Write count bytes from addressToGet to position in file
{{
''FileWriteBlock:   Open File filename
''                  Write count bytes from addressToGet to position in file
''                  Close File
''                  NOTE: If file not there it will be created. Position <0 will append to file
}}
  if(hasSd)
    if position<0
      RESULT := FileOpen(filename, IO_APPEND)
    else
      RESULT := FileOpen(filename, IO_WRITE)
    ifnot RESULT
      sd.newFile(filename)                              'new file
      sd.closeFile                                                                       
      if(sd.OpenFile(filename, IO_WRITE) == SUCCESS)
          RESULT := true
    if RESULT
      if position > 0
        RESULT := sd.fileSeek(position)                 'todo result now position ?   or exeception
      sd.writeData(addressToGet, count)
      sd.closeFile

PRI FileReadBlock(filename, position, addressToPut, count) 'Read count bytes from position in file to addressToPut
{{
''FileReadBlock:    Open File filename
''                  Read count bytes from position in file to addressToPut
''                  Close File
}}
  if(hasSd)
    if FileOpen(filename, IO_READ)
      if position > 0
        RESULT := sd.fileSeek(position)                 'todo result now position ?   or exeception
      sd.readFromFile(addressToPut, count)
      sd.closeFile
     
PRI GetContentType(ext)                                 'returns addr of content type string depending on ext
{{
''GetContentType:   Returns addr of content type string depending on ext  
}}
  if(strcomp(ext, string("css")) OR strcomp(ext, string("CSS")))
    return @@contentType[CSS]
    
  if(strcomp(ext, string("gif")) OR strcomp(ext, string("GIF")))
    return @@contentType[GIF]
    
  if(strcomp(ext, string("htm")) OR strcomp(ext, string("HTM")))
    return @@contentType[HTML]
    
  if(strcomp(ext, string("ico")) OR strcomp(ext, string("ICO")))
    return @@contentType[ICO]
    
  if(strcomp(ext, string("jpg")) OR strcomp(ext, string("JPG")))
    return @@contentType[JPG]
    
  if(strcomp(ext, string("js")) OR strcomp(ext, string("JS")))
    return @@contentType[JS]
    
  if(strcomp(ext, string("pdf")) OR strcomp(ext, string("PDF")))
    return @@contentType[PDF]
    
  if(strcomp(ext, string("png")) OR strcomp(ext, string("PNG")))
    return @@contentType[PNG]
    
  if(strcomp(ext, string("txt")) OR strcomp(ext, string("TXT")))
    return @@contentType[TXT]
    
  if(strcomp(ext, string("xml")) OR strcomp(ext, string("XML")))
    return @@contentType[XML]
    
  if(strcomp(ext, string("zip")) OR strcomp(ext, string("ZIP")))
    return @@contentType[ZIP]
    
  return @@contentType[HTML]

PRI Dec(value) | i, x, j                                'encode value into string (base 10)
{{
''Dec:              Converts value to zero terminated string representation. (base 10) 
''                  Note: This source came from the Parallax Serial Terminal library
}}
  j := 0
  x := value == NEGX                                    'Check for max negative
  if value < 0
    value := ||(value+x)                                'If negative, make positive; adjust for max negative and output sign

  i := 1_000_000_000                                    'Initialize divisor

  repeat 10                                             'Loop for 10 digits
    if value => i
      workspace[j++] := value / i + "0" + x*(i == 1)    'If non-zero digit, output digit; adjust for max negative
      value //= i                                       'and digit from value
      result~~                                          'flag non-zero found
    elseif result or i == 1
      workspace[j++] := "0"                             'If zero digit (or only digit) output it
    i /= 10
    
  workspace[j] := 0
  return @workspace

PRI StrToBase(addressToGet, base) : value | chr, index  'decode string into value
{{
''StrToBase:        Converts a zero terminated string representation of a number to a
''                  value in the designated base. Ignores all non-digit characters
''                  (except negative (-) when base is decimal (10)).
}}
  value := index := 0
  repeat until ((chr := byte[addressToGet][index++]) == 0)
    chr := -15 + --chr & %11011111 + 39*(chr > 56)      'Make "0"-"9","A"-"F","a"-"f" be 0 - 15, others out of range                             
    if (chr > -1) and (chr < base)                      'Accumulate valid values into result; ignore others
      value := value * base + chr                                                  
  if (base == 10) and (byte[addressToGet] == "-")       'If decimal, address negative sign; ignore otherwise
    value := - value
             
PRI Pause(Duration)                                     'pause duration milliseconds
{{
''Pause:            Pause duration milliseconds
}}
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)

''-------[ Output Buffer Handling ... ]---------------------------------------------------
PRI SendBytes(sockID, addressToGet, count)              'write count BYTES from addressToGet into outBuf
{{
''SendBytes:        Buffered output of count BYTES from address addressToGet on socket sockID
}}
  if (outBufPtr + count - @Buff) > mtuBuff              'and flush to Wiznet if needed 
    SendFlushOutBuf(sockID)
  bytemove(outBufPtr, addressToGet, count)
  outBufPtr += count

PRI SendBytesCRLF(sockID, addressToGet, count)          'write count BYTES from addressToGet into outBuf followed by CRLF
{{
''SendBytesCRLF:    Buffered output of count BYTES from address addressToGet followed by CRLF
}}
  SendBytes(sockID, addressToGet, count)                'and flush to Wiznet if needed
  SendCRLF(sockID)

PRI SendStr(sockID, addressToGet)                       'write STRING at addressToGet into outBuf
{{
''SendStr:          Buffered output of string at address addressToGet on socket sockID
}}
  SendBytes(sockID, addressToGet, strsize(addressToGet)) 'and flush to Wiznet if needed

PRI SendStrCRLF(sockID, addressToGet)                   'write STRING at addressToGet into outBuf followed by CRLF
{{
''SendStrCRLF:      Buffered output of string at address addressToGet followed by CRLF
}}
  SendBytesCRLF(sockID, addressToGet, strsize(addressToGet)) 'and flush to Wiznet if needed

PRI SendCRLF(sockID)                                    'write CRLF into outBuf
{{
''SendCRLF:         Buffered output of CRLF on socket sockID
}}
  SendBytes(sockID, @_newline, constant(@_newlineend-@_newline)) 'and flush to Wiznet if needed 

PRI SendFlushOutBuf(sockID) | ptr, size                 'flush outBuf to socket if some data there
{{
''SendFlushOutBuf:  Flush outBuf to socket if some data there
}}
  ifnot outBufPtr == @Buff                              'flush needed?
    size := outBufPtr - @Buff
    sock[sockID].Send(@Buff,size)                       'rest of buff
  outBufPtr := @Buff                                    'reset outBufPtr

PRI SendFlushOKorERR(sockID, iserr, okaddr, oksize, erraddr, errsize) 'send one of two responses depending on iserr and flush out to socket
{{
''SendFlushOKorERR: Send one of two responses depending on iserr and flush out to socket
}}
  ifnot iserr
    SendBytes(sockID, okaddr, oksize)                   'send ok-message           
  else
    SendBytes(sockID, erraddr, errsize)                 'send err-message
  SendCRLF(sockID)                                      'send _newline
  SendFlushOutBuf(sockID)                               'and flush out
  return true
    
''-------[ Print (debug) Handling ... ]---------------------------------------------------
PRI PrintStatus(sockID)                                 'Debug output one HttpSockets
{{
''PrintStatus:      Debug output one HttpSockets
}}
  PrintStrDecStr(string("Status ("),sockID, string(")......."))
  PrintHex(wiz.GetSocketStatus(sockID), 2)
  PrintChar(13)

PRI PrintAllStatuses | i                                'Debug output all HttpSockets
{{
''PrintAllStatuses: Debug output all HttpSockets
}}
  PrintStr(string(CR, "Socket Status", CR))
  repeat i from 0 to HTTPSOCKETS
    PrintDec(i)
    PrintStr(string("  "))
  PrintChar(CR)
  repeat i from 0 to HTTPSOCKETS
    PrintHex(wiz.GetSocketStatus(i), 2)
    PrintChar($20)
  PrintChar(CR)
      
PRI nbDebug(nbs, showdata)                              'Debug output NetBios CheckSocket
{{
''nbDebug:          Debug output NetBios CheckSocket
}}
  if (nbs>netbios#CHECKSOCKET_NOTHING)
    PrintStrDec(string(CR,"NB size "), netbios.GetLastReadSize)
    PrintStr(string(" op "))    
    PrintHex((byte[@buff+constant(netbios#FLAGS+8)]>>3),2) ' what op?
    PrintStr(string(" typ "))    
    PrintHex(wiz.DeserializeWord(@buff + constant(netbios#NB_1+8)),4) ' what typ?
    case nbs
      netbios#CHECKSOCKET_NB_SEND:
        PrintStr(string(" send PosQueryResp  "))
      netbios#CHECKSOCKET_NBSTAT_SEND:
        PrintStr(string(" send StatQueryResp "))
      netbios#CHECKSOCKET_OTHER:
        PrintStr(string(" other "))
    netbios.DecodeLastNameInplace
    PrintStrStr(netbios.GetLastName, string(" Request from: "))
    PrintIp(@buff)
    PrintChar(":")
    PrintDec(wiz.DeserializeWord(@buff + 4))
    PrintStrDecStr(string(" ("), wiz.DeserializeWord(@buff + 6), string(")"))
    if showdata
      DisplayUdpHeader(@Buff)    

PRI DisplayUdpHeader(buffer)                            'Debug output UDP package
{{
''DisplayUdpHeader: Debug output UDP package
}}
  PrintStr(string(CR, "Message from:......."))
  PrintIp(buffer)
  PrintChar(":")
  PrintDec(wiz.DeserializeWord(buffer + 4))
  PrintStrDec(string(" Size:"), wiz.DeserializeWord(buffer + 6))
  PrintChar(CR)  
  repeat 30
    PrintIpCR( buffer)
    buffer += 4
    
PRI PrintIp(addressToGet) | i                           'Print IP address
{{
''PrintIp:          Print IP address
}}
  repeat i from 0 to 3
    PrintDec(byte[addressToGet][i])
    if(i < 3)
      PrintChar($2E)

PRI PrintIpCR(addressToGet)                             'Print IP address followed by CR
{{
''PrintIpCR:        Print IP address followed by CR
}}
  PrintIp(addressToGet)
  PrintChar(CR)
  
PRI PrintStrIP(addressToGet1, addressToGet2)            'Print String followed by IP address
{{
''PrintStrIP:       Print String followed by IP address
}}
  PrintStr(addressToGet1)                               
  PrintIp(addressToGet2)

PRI PrintStrIPCR(addressToGet1, addressToGet2)          'Print String followed by IP address followed by CR
{{
''PrintStrIPCR:     Print String followed by IP address followed by CR
}}
  PrintStrIP(addressToGet1, addressToGet2)
  PrintChar(CR)
  
PRI PrintStrDec(addressToGet, value)                    'Print String followed by Decimal
{{
''PrintStrDec:      Print String followed by Decimal
}}
  PrintStr(addressToGet)
  PrintDec(value)

PRI PrintStrStr(addressToGet1, addressToGet2)           'Print String followed by String
{{
''PrintStrStr:      Print String followed by String
}}
  PrintStr(addressToGet1)
  PrintStr(addressToGet2)
  
PRI PrintStrDecStr(addressToGet1, value, addressToGet2) 'Print String followed by Decimal followed by String
{{
''PrintStrDecStr:   Print String followed by Decimal followed by String
}}
  PrintStrDec(addressToGet1, value)
  PrintStr(addressToGet2)

PRI PrintChar(value)                                    'wrapper for Serial - above this point Serial is not used directly (except ser.start)
{{
''PrintChar:        Print Character
}}
  ser.tx(0,value)                                                          

PRI PrintDec(value)                                     'wrapper for Serial
{{
''PrintDec:         Print Decimal
}}
  ser.decl(0,value,10,0)                                                

PRI PrintStr(addressToGet)                              'wrapper for Serial
{{
''PrintStr:         Print String
}}
  ser.str(0,addressToGet)                                 

PRI PrintHex(value, digits)                             'wrapper for Serial
{{
''PrintHex:         Print Hex
}}
  ser.hex(0,value, digits)

PRI InputAvailableBytes(port)
  RESULT := ser.rxHowFull(port)

{            
  'PST.dec(netbios.SendQuery(string("MSROBOTS"),0,false))   ' trans id
'  netbios.SendQuery(string("MSROBOTS"),0,true)
'  netbios.SendQuery(string("PAVILION"),netbios#SPACE,0,true)
'  netbios.SendQuery(string("*"),0,true)
'  nbDebug(3,true) 

  repeat
    t1 := netbios.CheckSocket
    t2 := netbios.GetLastReadSize
    if t2
      'if t1 == 3
        
        PST.dec(t2)
        pst.char(CR)
     '   PST.str(netbios.GetLastName)
      '  pst.char(CR)
        PrintIpCR(netbios.GetLastIP)
        pst.char(CR)
      nbDebug(t1,true)
  until t2 == 0
}

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