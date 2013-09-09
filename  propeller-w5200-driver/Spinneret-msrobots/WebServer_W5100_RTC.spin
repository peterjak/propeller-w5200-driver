'*********************************************************************************************
{
AUTHOR: Mike Gebhard
COPYRIGHT: Parallax Inc.
LAST MODIFIED: 8/31/2013
VERSION 1.0
LICENSE: MIT (see end of file)

DESCRIPTION:
The MAIN webserver object for spinneret

NOTE:   please change MAC address below at top of the first CON section
        to the number on the back of your spinneret.
      
        you also may need to change the hostname at top of the first DAT section
        if you need more then one spineret in the same network

MODIFICATIONS:
8/31/2013       added support for OPTIONS,HEAD,PUT,MKCOL,DELETE (minimal PROPFIND)
                added SetHostname to DHCP
                added support for dynamic PASM pages/responses (and some demos)     

}
'*********************************************************************************************
CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000
  
  'wiz.SetMac($00, $08, $DC, $16, $F1, $32)             ' MAC Mike G

  MAC_1         = $00                                   ' MAC MSrobots          ' 
  MAC_2         = $08
  MAC_3         = $DC
  MAC_4         = $16
  MAC_5         = $F0
  MAC_6         = $4F

  TCP_MTU       = 1460
  BUFFER_3K     = $C00
  BUFFER_LOG    = $80
  BUFFER_WS     = $20
  BUFFER_SNTP   = 48+8 
  
  CR            = $0D
  LF            = $0A

  SOCKETS       = 4                                     ' 4 w5100 8 w5200

  { Web Server Configuration }
  MULTIUSE_SOCK = SOCKETS -1                            ' sock 3   (7) used for DHCP, NETBIOS and SNTP
  HTTPSOCKETS   = MULTIUSE_SOCK -1                      ' sock 0-2 (6) 
  ATTEMPTS      = 5
  { Port Configuration }
  HTTP_PORT     = 80
  SNTP_PORT     = 123

  { SD IO }
  DISK_PARTION  = 0 
  SUCCESS       = -1
  IO_OK         = 0
  IO_READ       = "r"
  IO_WRITE      = "w"
  

  { Serial IO PINs } 
  USB_Rx        = 31
  USB_Tx        = 30

  {{ Content Types }}
  #0, CSS, GIF, HTML, ICO, JPG, JS, PDF, PNG, TXT, XML, ZIP
  
  {{ USA Standard Time Zone Abbreviations }}
  #-10, HST,AtST,_PST,MST,CST,EST,AlST

  GMT           = 0
  AZ_TIME       = 1
              
  {{ USA Daylight Time Zone Abbreviations  }}
  #-9, HDT,AtDT,PDT,MDT,CDT,EDT,AlDT

  Zone = MST '<- Insert your timezone

  RTC_CHECK_DELAY = 4_000_000  '1_000_000 = ~4 minutes

  
  {{ PSX CMDS }}  
  REQ_PARA_STRING  = 1
  REQ_PARA_NUMBER  = 2
  REQ_FILENAME     = 3
  REQ_HEADER_STRING= 4
  REQ_HEADER_NUMBER= 5
  
  SEND_FILE_EXT    = 11
  SEND_SIZE_HEADER = 12
  SEND_DATA        = 13
  SEND_STRING      = 14
  SEND_FLUSH       = 15
  
  CHANGE_DIRECTORY = 21
  LIST_ENTRIES     = 22
  LIST_ENTRY_ADR   = 23

  PSE_CALL         = 91
  PSE_TRANSFER     = 92
        
VAR
  long  buttonStack[10]
  long  longHIGH, longLOW, MM_DD_YYYY, DW_HH_MM_SS 'Expected 4-contigous variables for SNTP  
  
DAT
  hostname      byte  "PROPNET",0 '<- you need to change this if you have more then one spineret
  'workgroup     byte  "WORKGROUP", 0
  workgroup     byte  "MSROBOTS", 0
  
  sntpIp        byte  64, 147, 116, 229 '<- This SNTP server is on the west coast
  version       byte  "1.2", $0
  hasSd         byte  $00
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

  _options      byte  "Allow: OPTIONS, HEAD, GET, POST, PUT, MKCOL, DELETE, PROPFIND", CR, LF
                'byte  "Allow: OPTIONS, HEAD, GET, POST, PUT, MKCOL, DELETE, PROPFIND, PROPPATCH, COPY, MOVE, LOCK, UNLOCK", CR, LF
                byte  "Public: OPTIONS, HEAD, GET, POST, PUT, MKCOL, DELETE, PROPFIND", CR, LF
                byte  "DAV: 1",CR, LF           ' ,2,3
                'byte  "MS-Author-Via: DAV", CR, LF
                byte  "Content-Length: 0", CR, LF
  _optionsend   byte   0 
  _h100         byte  "HTTP/1.1 100 Continue", CR, LF
  _h100end      byte  $0      
  _h200         byte  "HTTP/1.1 200 OK", CR, LF
  _h200end      byte  $0    
  _h207         byte  "HTTP/1.1 207 Multi-Status", CR, LF
  _h207end      byte  $0      
  _h201         byte  "HTTP/1.1 201 Created", CR, LF
  _h201end      byte  $0   
  _h403         byte  "HTTP/1.1 403 Forbidden", CR, LF
  _h403end      byte  $0  
'  _h404         byte  "HTTP/1.1 404 Not Found", CR, LF
'  _h404end      byte  $0 
  _h409         byte  "HTTP/1.1 409 Conflict", CR, LF
  _h409end      byte  $0  
  _css          byte  "Content-Type: text/css",CR, LF, $0
  _gif          byte  "Content-Type: image/gif",CR, LF, $0
  _html         byte  "Content-Type: text/html", CR, LF, $0
  _ico          byte  "Content-Type: image/x-icon",CR, LF, $0
  _jpg          byte  "Content-Type: image/jpeg",CR, LF, $0
  _js           byte  "Content-Type: application/javascript",CR, LF, $0
  _pdf          byte  "Content-Type: application/pdf",CR, LF, $0
  _png          byte  "Content-Type: image/png",CR, LF, $0 
  _txt          byte  "Content-Type: text/plain; charset=utf-8",CR, LF, $0  
  _xml          byte  "Content-Type: text/xml",CR, LF, $0
  _zip          byte  "Content-Type: application/zip",CR, LF, $0
  _contLen      byte  "Content-Length: "
  _contlenend   byte  $0          
  _newline      byte  CR, LF
  _newlineend   byte  $0
  time          byte  "00/00/0000 00:00:00", 0
  wizver        byte  $00
  dhcpRenew     byte  $00
  buff          long
                byte  $0[BUFFER_3K]
  sntpBuff      byte  $0[BUFFER_SNTP] 
  workSpace     byte  $0[BUFFER_WS]
  logBuf        byte  $0[BUFFER_LOG]
  null          long  $00
  contentType   long  @_css, @_gif, @_html, @_ico, @_jpg, @_js, @_pdf, @_png, @_txt, @_xml, @_zip, $0
  mtuBuff       long  TCP_MTU
   
  outBufPtr     long  0 ' used for delayed writing

  pse1          long
                byte "pse",0
  pse2          long
                byte "PSE",0
  psx1          long
                byte "psx",0
  psx2          long
                byte "PSX",0

OBJ
  pst             : "Parallax Serial Terminal"
  wiz             : "W5100"                           
  dhcp            : "Dhcp"
  netbios         : "NetBios"
  sock[SOCKETS]   : "Socket"
  req             : "HttpHeader"
  sd              : "S35390A_SD-MMC_FATEngineWrapper"
  sntp            : "SNTP Simple Network Time Protocol v2.01"
  rtc             : "S35390A_RTCEngine" 
 
PUB Init | i, t1 , t2

  'A hardware reset can take 1.5 seconds
  'before the Sockets are ready to Send/Receive
  wiz.HardReset(WIZ#WIZ_RESET)
                           
  pst.Start(115_200)      
  pause(500)

  '---------------------------------------------------
  'Main COG
  '--------------------------------------------------- 
  pst.str(string("COG[0]: Spinneret Web Server v"))
  pst.str(@version)

  '---------------------------------------------------
  'Start the Parallax Serial Terminal
  '---------------------------------------------------
  pst.str(string(CR, "COG[1]: Parallax Serial Terminal"))
  '---------------------------------------------------
  'Start the SD Driver and Mount the SD card 
  '--------------------------------------------------- 
  ifnot(sd.Start)
    pst.str(string(CR, "        Failed to start SD driver!"))
  else
    pst.str(string(CR, "COG["))
    i := sd.GetCogId
    pst.dec(i)
    pst.str(string("]: Started SD Driver"))  
  pause(500)

  pst.str(string(CR,"        Mount SD Card - "))
  t1 := sd.mount(DISK_PARTION)
  pst.str(t1)
  if(strcomp(t1, string("OK")))
    hasSd := true
  else
    hasSd := false

  '---------------------------------------------------
  'Initialize the Realtime clock library
  '--------------------------------------------------- 
  pst.str(string(CR,"        Init RTC: "))
  rtc.RTCEngineStart(29, 28, -1)
  pst.str(FillTime(@time))

  '--------------------------------------------------- 
  'Start the WizNet SPI driver
  '--------------------------------------------------- 
  wiz.Start(WIZ#SPI_CS, WIZ#SPI_SCK, WIZ#SPI_MOSI, WIZ#SPI_MISO)
  pst.str(string(CR, "COG["))
  i := wiz.GetCogId
  pst.dec(i)
  pst.str(string("]: Started W5100 SPI Driver"))

  'Verify SPI connectivity by reading the WizNet 5100 version register 
  wizver := GetVersion
  if(wizver == 0)
    pst.str(string(CR, CR, "SPI communication failed!", CR, "Check connections", CR))
    return
  else
    pst.str(string(CR, "        WizNet 5100 Connected; Reg(0x19) = ") )
    pst.dec(wizver)

  pst.str(string(CR, "COG[n]: "))
  pst.dec(i~ +1)
  pst.str(string(" COGs in Use"))
    
  pst.str(@divider)

  'MAC (Source Hardware Address) must be unique
  'on the local network
  
  'wiz.SetMac($00, $08, $DC, $16, $F1, $32)
  wiz.SetMac(MAC_1,MAC_2,MAC_3,MAC_4,MAC_5,MAC_6)

  'Invoke DHCP to retrived network parameters
  'This assumes the WizNet 5100 is connected 
  'to a router with DHCP support
  pst.str(string(CR,"Retrieving Network Parameters...Please Wait"))
  pst.str(@divider)
  if(InitNetworkParameters)
    PrintNetworkParams
  else
    PrintDhcpError
    return
    
  '--------------------------------------------------- 
  'Startup NetBios
  '---------------------------------------------------
  pst.str(string(CR, "Starting NetBios ... Please Wait ... ")) 
  i := netbios.Init(@Buff, MULTIUSE_SOCK, @hostname, @workgroup)
  if i > 0
    pst.str(string("NetBios Error ID: "))
    pst.dec(i)
    nbDebug(3,true)
  else
    pst.str(@hostname)
    pst.str(string(" registered",CR))  
            
  'PST.dec(netbios.SendNameQuery(string("MSROBOTS"),0))   ' trans id
  netbios.SendNameQuery(string("*"),0)

  repeat
    t1 := netbios.CheckSocket
    t2 := netbios.GetLastReadSize
    if t2
      if t1 == 3
        
        PST.dec(t2)
        pst.char(CR)
     '   PST.str(netbios.GetLastName)
      '  pst.char(CR)
        PrintIp(netbios.GetLastIP)
        pst.char(CR)
      nbDebug(t1,false)
  until t2 == 0
    
  '--------------------------------------------------- 
  'Snyc the RTC using SNTP
  '---------------------------------------------------
  pst.str(string(CR, "Sync RTC with Time Server")) 
  pst.str(@divider)                                                   
  if(SyncSntpTime)
    PrintRemoteIp(MULTIUSE_SOCK)
    pst.str(string("Web time.........."))
    DisplayHumanTime
  else
    pst.str(string(CR, "Sync failed"))

  '--------------------------------------------------- 
  ' Set DHCP renew -> (Current hour + 12) // 24
  '--------------------------------------------------- 
  dhcpRenew := (rtc.clockHour + 12) // 24
  pst.str(string("DHCP Renew........"))
  if(dhcpRenew < 10)
    pst.char("0")
  pst.dec(dhcpRenew)
  pst.str(string(":00:00",CR))
    
  '--------------------------------------------------- 
  'Start up the web server
  '---------------------------------------------------
  pst.str(string(CR, "Initialize Sockets"))
  pst.str(@divider)
  repeat i from 0 to HTTPSOCKETS
    sock[i].Init(i, WIZ#TCP, HTTP_PORT)
           
  mtuBuff := sock[0].GetMtu 

  OpenListeners
  StartListners
     
  pst.str(string(CR, "Start Socket Services", CR))
  MultiSocketService

  pst.str(string("Fatal Error!!!"))  
  CloseAll
  pst.str(string(CR, "Rebooting..."))
  pause(1000) 
  reboot

   
PRI MultiSocketService | bytesToRead, sockId, filename, rtcDelay, JustHeader, i 
  bytesToRead := sockId := rtcDelay := 0
  CloseWait                     ' ? MSrobots    
  repeat                     
    'Cycle through the sockets one at a time
    'looking for a connections
    repeat    
      sockId := ++sockId // constant(HTTPSOCKETS+1)
      
      i := netbios.CheckSocket      
      'just for debug start ... Request  data still in Buffer 
      nbDebug(i,false)
      'just for debug end
                                  
      if(++rtcDelay//RTC_CHECK_DELAY == 0)
        rtc.readTime
        if(rtc.clockHour == dhcpRenew)
          RenewDhcpLease
        rtcDelay~
    until sock[sockId].Connected  
        
    pst.str(@divider)  
            
    'Repeat until we have data in the buffer
    repeat until bytesToRead := sock[sockId].Available

    'Check for a timeout error
    if(bytesToRead =< 0)
      pst.str(string(CR, "Timeout: "))
      pst.dec(bytesToRead) 
      PrintAllStatuses
      sock[sockId].Disconnect
    else
    
      'Move the Rx buffer into HUB memory
      sock[sockId].Receive(@buff, bytesToRead)
       
      'Display the request header
      pst.str(@buff)
       
      'Tokenize and index the header
      req.TokenizeHeader(@buff, bytesToRead)
       
      filename := req.GetFileName
      pst.str(filename)
       
      RESULT := false
      JustHeader := false
      outBufPtr := @Buff     ' used for delayed writing (global)
     
      ifnot strcomp(@buff, string("GET"))
        RESULT := true
        if strcomp(@buff, string("PROPFIND"))
          RESULT := PseHandler(sockId, string("/PROPFIND.PSE"), false)
        elseif OptionsHandler(sockId, filename)
        elseif MKcolHandler(sockId, filename)
        elseif DeleteHandler(sockId, filename)
        elseif PutHandler(sockId, filename)
        elseif (strcomp(@buff, string("HEAD")))
          JustHeader := true
          RESULT := false
        else
          RESULT := false
          
      ifnot RESULT 
        if PsxHandler(sockId, filename, JustHeader)
        elseif FileHandler(sockId, filename, JustHeader)
        elseif RenderDynamic(sockId, JustHeader)
        else
          sock[sockId].Send(@_404, constant(@_404end - @_404))
       
      'Close the socket and reset the
      'interupt register     
      sock[sockId].Disconnect
      sock[sockId].Close
      sock[sockId].SetSocketIR($FF)
      sock[sockId].Open
      sock[sockId].Listen

PRI RenewDhcpLease | requestIp
  netbios.DisconnectSocket
  pst.str(string(CR,"Retrieving Network Parameters...Please Wait"))
  pst.str(@divider)
  requestIp := dhcp.GetIp
  dhcp.SetRequestIp(byte[requestIp][0],byte[requestIp][1],byte[requestIp][2],byte[requestIp][3]) 
  if(InitNetworkParameters)
    PrintNetworkParams
  else
    PrintDhcpError    
  rtc.readTime 
  dhcpRenew := (rtc.clockHour + 12) // 24
  pst.str(string("DHCP Renew........"))
  if(dhcpRenew < 10)
    pst.char("0")
  pst.dec(dhcpRenew)
  pst.str(string(":00:00",CR))
  netbios.ReInitSocket
  
PRI BuildHeader(id, contentLength)
    BuildStatusHeader(id, @_h200, contentLength)
                            
PRI BuildStatusHeader(id, status, contentLength) | src
  write_outBuf(id, status, strsize(status))             ' write status
  src := GetContentType(req.GetFileNameExtension)
  write_outBuf(id, src, strsize(src))                                                        
  if(contentLength > 0)                                 ' Add content-length : value CR, LF
    write_outBuf(id, @_contLen, constant(@_contlenend-@_contLen))
    src := Dec(contentLength)
    write_outBuf(id, src, strsize(src))
    write_outBuf(id, @_newline, constant(@_newlineend-@_newline))   
  write_outBuf(id, @_newline, constant(@_newlineend-@_newline) )       ' End the header with a new line

PRI flush_outBuf(id) | ptr, size  
  ifnot outBufPtr == @Buff                        ' flush needed
    size := outBufPtr - @Buff
    sock[id].Send(@Buff,size)        ' rest of buff
'    ptr := @Buff
'    repeat size
'      PST.Char(byte[ptr++])
  outBufPtr := @Buff                              ' reset outBufPtr

PRI write_outBuf(id, addr, bytes)
  if (outBufPtr + bytes - @Buff) > mtuBuff
    flush_outBuf(id)
  bytemove(outBufPtr, addr, bytes)
  outBufPtr += bytes   

PRI OptionsHandler(id, fn) | options
  if strcomp(@buff, string("OPTIONS"))
    write_outBuf(id, @_h200, constant(@_h200end-@_h200) )            ' send 200 OK
    write_outBuf(id, @_options, constant(@_optionsend-@_options))    ' send _options
    write_outBuf(id, @_newline, constant(@_newlineend-@_newline))    ' send _newline
    flush_outBuf(id)
    return true    
  return false
    
PRI PutHandler(id, fn) | bytesToRead, size , status, noerr
  if strcomp(@buff, string("PUT"))
    status :=  @_h201                                   ' 201 created
    size := StrToBase(req.Header(string("Content-Length")) , 10)
    if FileExists(fn)                                   ' if file already there
      status :=  @_h200                                 '    200 OK ( or 202 no Content?)
      \sd.deleteEntry(fn)                               '    delete
    \sd.newFile(fn)                                     ' new file
    sd.closeFile                                        
    noerr := sd.openFile(fn, IO_WRITE)                                 
    ifnot ( noerr == true)                              ' now open file write
      status :=  @_h409                                 ' 409 Conflict  
    else
      PST.str(string("send 100..."))
      write_outBuf(id, @_h100, constant(@_h100end-@_h100))          ' send 100 continue
      write_outBuf(id, @_newline,constant(@_newlineend-@_newline) ) ' send _newline  
      flush_outBuf(id)
    
      repeat until size<1                               ' expecting size bytes
        repeat until bytesToRead := sock[id].Available  ' Repeat until we have data in the buffer                            
        if(bytesToRead < 1)                             ' Check for a timeout error 
          size := -1 'timeout
        else       
          sock[id].Receive(@buff, bytesToRead)          ' Move the Rx buffer into HUB memory 
          size -= bytesToRead
          PST.str(string("write data..."))
          sd.writeData(@buff, bytesToRead)              ' now write file        \
        
      sd.closeFile                                      ' now close file
    PST.str(status)
    write_outBuf(id, status, strsize(status))           ' send 409 Conflict 201 Created or 200 OK
    write_outBuf(id, @_newline, constant(@_newlineend-@_newline) )     ' send _newline
    flush_outBuf(id)
    return true                                         ' done
  return false
  
PRI MKcolHandler(id, fn) | noerr
  if strcomp(@buff, string("MKCOL"))
    noerr:=sd.newDirectory(fn)
    if noerr==true
      write_outBuf(id, @_h201, constant(@_h201end-@_h201))         ' send 201 created
    else
      write_outBuf(id, @_h409, constant(@_h409end-@_h409))         ' send 409 conflict
    write_outBuf(id, @_newline, constant(@_newlineend-@_newline) )     ' send _newline
    flush_outBuf(id) 
    return true   
  return false

PRI DeleteHandler(id, fn) | noerr
  if strcomp(@buff, string("DELETE"))
    noerr := sd.deleteEntry(fn)
    if noerr == true
      write_outBuf(id, @_h200, constant(@_h200end-@_h200) )         ' send 200 OK 
    else
      write_outBuf(id, @_h409, constant(@_h409end-@_h409))         ' send 409 conflict
    write_outBuf(id, @_newline, constant(@_newlineend-@_newline) )     ' send _newline
    flush_outBuf(id) 
    return true
  return false
                                                
PRI PsxHandler(id, fn, JustHeader) | ext
  ext := long[req.GetFileNameExtension] 
  if (ext==psx1) OR (ext==psx2)
    return PseHandler(id, fn, JustHeader)
  if (ext==pse1) OR (ext==pse2)
    write_outBuf(id, @_h403, constant(@_h403end-@_h403))           ' send 403 Forbidden
    write_outBuf(id, @_newline, constant(@_newlineend-@_newline) )     ' send _newline
    flush_outBuf(id) 
    return true    
  return false
    
PRI PseHandler(id, fn, JustHeader) | Daisy, fs, psmptr, bufptr, cog, cmd, param1, param2 , param3, param4, param5,param6
  cmd := param1 := param2 := param3 := param4 := param5 := param6 := 0
  Daisy := 1
  repeat until (Daisy == 0 )
    RESULT:= false                                                                        
    Daisy := 0                                            ' no DaisyChain yet
    if FileExists(fn)
      OpenFile(fn)                                        ' load PASM to end of Buffer
      fs := sd.getFileSize - 28                           ' we just need Pasm block
      if fs>0 and fs<1985
        bufptr := (@buff+constant(BUFFER_3K-$400)) & $FFFFFC' last 1 kb buffer
        psmptr := (@buff-fs+BUFFER_3K) & $FFFFFC  ' end buffer minus pasm size
        sd.readFromFile(bufptr, 24)                       ' load fist 24 bytes and discard
        sd.readFromFile(psmptr, fs)                       ' load pasm to end of buffer
      else
        fs := -1                                          ' no pasm/wrong size
      sd.closeFile
      if fs>0                                             ' if no error yet
        cmd := -1                                         ' idle
        param1 := bufptr                                  ' output area for pasm at init    
        param2 := 0                                          
        cog := cognew(psmptr, @cmd) + 1                   ' run pasm
        'cog := cognew(psm.getPasmADR, @cmd) + 1
        if cog                                            ' if started
          pst.str(string(CR, "using COG["))
          pst.dec(cog)
          pst.str(string("].."))
          pst.str(fn)
          repeat until cmd==0                             ' exit
            case cmd                                      ' commands from PASM cog to spin
              REQ_PARA_STRING:                            ' PASM request Param as String
                param1 := req.Get(@param1)                ' Param1-4 CONTAIN string up to 15 letter+0
                param2 := strsize(param1)                 ' Param2 returns string size
                cmd := -1                                 ' Param1 returns address of string
              REQ_PARA_NUMBER:                            ' PASM request Param as Number
                param2 := req.Get(@param1)                ' Param1-4 CONTAIN string up to 15 letter+0
                param1 := StrToBase(param2 , 10)          ' Param1 returns value as long
                param2 := strsize(param2)                 ' Param2 returns string size
                cmd := -1                                 '  
              REQ_FILENAME:                               ' PASM request org. Filename
                param1 := req.GetFileName                 ' (used by propfind)
                cmd := -1                                 ' Param1 returns address of string 
              REQ_HEADER_STRING:                          ' PASM request Header as string (used by propfind)
                param1 := req.Header(@param1)             ' Param1-4 CONTAIN key up to 15 letter+0
                param2 := strsize(param1)                 ' Param2 returns string size
                cmd := -1                                 ' return address of string in Param1
              REQ_HEADER_NUMBER:                          ' PASM request Header as number (used by propfind)
                param2 := req.Header(@param1)             ' Param1-4 CONTAIN string up to 15 letter+0
                param1 := StrToBase(param2 , 10)          ' Param1 returns value as long
                param2 := strsize(param2)                 ' Param2 returns string size
                cmd := -1                                 ' return value as long in Param1 
                
              SEND_FILE_EXT:
                if param1>0                               ' PASM sends ext.
                  Bytemove(req.GetFileNameExtension,@param1,3) 'Param1 contains string up to 3 letter+0
                cmd := -1                                 ' idle - back to PASM
              SEND_SIZE_HEADER:                           ' PASM sends size or -1
                if (param2==1)
                  BuildStatusHeader(id, @_h207, param1)   ' send header 207 Multi-Status      
                else
                  BuildStatusHeader(id, @_h200, param1)   ' send header 200 OK      
                if JustHeader                             ' if request is HEAD
                  Daisy := 0
                  cmd := 0                                '    exit 
                else
                  cmd := -1                               ' idle - back to PASM
              SEND_DATA:                                  ' PASM sends data in bufptr
                write_outBuf(id, param1, param2)          ' param2 bytes at adress param1
                cmd := -1                                 ' idle - back to PASM
              SEND_STRING:                                ' PASM sends string in bufptr
                param2 := strsize(param1)                 ' returns aize in param2                
                write_outBuf(id, param1, param2)          ' strsize bytes at adress param1
                'PST.str(param1)
                cmd := -1                                 ' idle - back to PASM
              SEND_FLUSH:
                flush_outBuf(id)                          ' send buffered output manual if needed
                cmd := -1                                 ' idle - back to PASM
              CHANGE_DIRECTORY:                           ' Change Directory param1 path
                param1 := sd.changeDirectory(param1)      ' param1 adr string path
                sd.listEntry(string("."))                 ' ? bug? needed or sd.listEntries wont work ?
                cmd := -1                                 ' idle - back to PASM 
              LIST_ENTRIES:                               ' List Directory param1 "W" or "N"
                param1 := sd.listEntries(@param1)         ' param1 contains string up to 3 letter+0
                cmd := -1                                 ' idle - back to PASM
              LIST_ENTRY_ADR:                             ' PASM needs sd directoryEntryCache 
                param1 := sd.GetADRdirectoryEntryCache    ' adr EntryCache
                cmd := -1                                 ' idle - back to PASM
              PSE_CALL:                                   ' call pse
                fs := strsize(bufptr)                     ' size request
                bytemove(@buff,bufptr,fs)                 ' move to buff
                req.TokenizeHeader(@buff, fs)             ' tokenize
                param1:=PseHandler(id, req.GetFileName, false)   ' call sub modul (new cog)
                cmd := -1                                 ' idle - back to PASM 
              PSE_TRANSFER:                               ' dasychain pse
                fs := strsize(bufptr)                     ' size request
                bytemove(@buff,bufptr,fs)                 ' move to buff                             
                req.TokenizeHeader(@buff, fs)             ' tokenize
                fn := req.GetFileName
                Daisy := 1
                cmd := 0                                  ' exit

          flush_outBuf(id)
                                      
          if cog                                             
            pst.str(string("..COG["))
            pst.dec(cog)
            pst.str(string("] finished."))
            cogstop(cog~ - 1)
          RESULT := true                                ' if done return true
       
PRI FileHandler(id, fn, JustHeader) | fs, bytes , offset
{{
  Render a static file from the SD Card
}}
  if FileExists(fn)
    mtuBuff := sock[id].GetMtu
    OpenFile(fn)
    fs := sd.getFileSize 
    BuildHeader(id, fs)
    if JustHeader     
      flush_outBuf(id) 
    else 
      offset :=  outBufPtr - @Buff 
      repeat until fs =< 0
        if(fs < (mtuBuff - offset))
          bytes := fs
        else
          bytes := (mtuBuff - offset) 
        sd.readFromFile(@buff + offset, bytes)
        fs -= sock[id].Send(@buff, bytes  + offset)
        offset := 0
        
    sd.closeFile
    return true
  return false

PRI RenderDynamic(id, JustHeader) 
  'req.TokenizeFilename                                  ' now ready for RESTful stuff
  
  'Process pinstate
  
  if(strEndsWith(req.GetFileName, string("pinstate.xml")))
    BuildPinStateXml( req.Get(string("led")), req.Get(string("value")) )
    BuildHeader(id, -1)
    write_outBuf(id, @xmlPinState, strsize(@xmlPinState))
    flush_outBuf(id)
    return true

  if(strEndsWith(req.GetFileName, string("p_encode.xml")))
    BuildPinEndcodeStateXml( req.Get(string("value")) )
    BuildHeader(id, -1)
    write_outBuf(id, @xmlPinState, strsize(@xmlPinState))
    flush_outBuf(id)
    return true

  if(strEndsWith(req.GetFileName, string("time.xml")))
    FillTime(@xTime)
    FillDay(@xday)
    BuildHeader(id, -1)
    write_outBuf(id, @xmlTime, strsize(@xmlTime))
    flush_outBuf(id)
    return true
               
  if(strEndsWith(req.GetFileName, string("sntptime.xml")))
    SyncSntpTime
    FillTime(@xTime)
    FillDay(@xday) 
    BuildHeader(id, -1)
    write_outBuf(id, @xmlTime, strsize(@xmlTime))
    flush_outBuf(id)
    return true  

  return false

PRI strEndsWith(str1,str2) | lenmin, len1, len2, pos1, pos2
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


PRI SyncSntpTime | ptr

  netbios.DisconnectSocket
 'Initialize the socket
  sock[MULTIUSE_SOCK].Init(MULTIUSE_SOCK, WIZ#UDP, SNTP_PORT)
  'Initialize the destination paramaters
  'sock[MULTIUSE_SOCK].RemoteIp(64, 147, 116, 229)
  sock[MULTIUSE_SOCK].RemoteIp(sntpIp[0], sntpIp[1], sntpIp[2], sntpIp[3])
  sock[MULTIUSE_SOCK].RemotePort(SNTP_PORT)

  'Setup the buffer
  sntp.CreateUDPtimeheader(@sntpBuff)  
  ptr := SntpSendReceive(@sntpBuff, 48)
  if(ptr == @null)
    return false
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

  netbios.ReInitSocket
  return true
    
PRI SntpSendReceive(buffer, len) | bytesToRead, ptr 
  bytesToRead := 0

  'Open socket and Send Message
  sock[MULTIUSE_SOCK].Open
  sock[MULTIUSE_SOCK].Send(buffer, len)
  pause(500)
  bytesToRead := sock[MULTIUSE_SOCK].Available
   
  'Check for a timeout
  if(bytesToRead =< 0 )
    bytesToRead~
    return @null

  if(bytesToRead > 0) 
    'Get the Rx buffer  
    ptr := sock[MULTIUSE_SOCK].Receive(buffer, bytesToRead)

  sock[MULTIUSE_SOCK].Disconnect
  return ptr
    
PRI Writeline(label, value)
  pst.str(label)
  repeat 25 - strsize(label)
    pst.char(".")
  pst.dec(value)
  pst.char(CR)

PRI OpenFile(filename) | rc
{{
  Verify if the file exists
}}
  ifnot(hasSd)
    return false
    
  rc := sd.listEntry(filename)
  if(rc == IO_OK)
    rc := sd.openFile(filename, IO_READ)
      if(rc == SUCCESS)
        return true
  return false

PRI FileExists(filename) | rc
{{
  Verify if the file exists
}}
  ifnot(hasSd)
    return false
    
  rc := sd.listEntry(filename)
  if(rc == IO_OK)
    rc := sd.openFile(filename, IO_READ)
      if(rc == SUCCESS)
        sd.closeFile
        return true
  return false  

PRI GetContentType(ext)
{{
  Determine the content-type 
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

PRI GetVersion | i
  i := 0
  result := 0
  repeat until result > 0
    result := wiz.GetVersion
    if(i++ > ATTEMPTS*5)
      return 0
    pause(250)

PRI InitNetworkParameters | i

  i := 0 
  'Initialize the DHCP object
  dhcp.Init(@buff, MULTIUSE_SOCK)
  dhcp.SetHostname(@hostname)   ' defined at top of first DAT section

  'Request an IP. The requested IP
  'might not be assigned by DHCP
  'dhcp.SetRequestIp(192,168,1,130)

  'Invoke the SHCP process
  repeat until dhcp.DoDhcp(true)
    if(++i > ATTEMPTS)
      return false
  return true


PRI PrintDhcpError
  if(dhcp.GetErrorCode > 0)
    pst.char(CR) 
    pst.str(string(CR, "Error Code: "))
    pst.dec(dhcp.GetErrorCode)
    pst.char(CR)
    pst.str(dhcp.GetErrorMessage)
    pst.char(CR)

PRI PrintNetworkParams

  pst.str(string("Assigned IP......."))
  PrintIp(dhcp.GetIp)
  
  pst.str(string("Lease Time........"))
  pst.dec(dhcp.GetLeaseTime)
  pst.str(string(" (seconds)"))
  pst.char(CR)
 
  pst.str(string("DNS Server........"))
  PrintIp(wiz.GetDns)

  pst.str(string("DHCP Server......."))
  printIp(dhcp.GetDhcpServer)

  pst.str(string("Router............"))
  printIp(dhcp.GetRouter)

  pst.str(string("Gateway..........."))                                        
  printIp(wiz.GetGatewayIp)

PRI PrintRemoteIp(id)
  pst.str(string("Remote IP........."))
  printIp(wiz.GetRemoteIp(id))
     
PRI OpenListeners | i
  'pst.str(string("Open",CR))
  repeat i from 0 to HTTPSOCKETS
    sock[i].Open
      
PRI StartListners | i
  repeat i from 0 to HTTPSOCKETS
    if(sock[i].Listen)
      pst.str(string("Socket "))
      pst.dec(i)
      pst.str(string(" Port....."))
      pst.dec(sock[i].GetPort)
      pst.str(string("; MTU="))
      pst.dec(sock[i].GetMtu)
      pst.str(string("; TTL="))
      pst.dec(sock[i].GetTtl)
      pst.char(CR)
    else
      pst.str(string("Listener failed ",CR))

PRI SetTranactionTimeout(timeout) | i
  repeat i from 0 to HTTPSOCKETS
    sock[i].SetTransactionTimeout(timeout)

PRI CloseWait | i
  repeat i from 0 to HTTPSOCKETS
    if(sock[i].IsCloseWait) 
      sock[i].Disconnect
      sock[i].Close
      
    if(sock[i].IsClosed)  
      sock[i].Open
      sock[i].Listen

PRI CloseAll | i
  repeat i from 0 to HTTPSOCKETS
    sock[i].Disconnect
    sock[i].Close
        
PRI PrintStatus(id)
  pst.str(string("Status ("))
  pst.dec(id)
  pst.str(string(")......."))
  pst.hex(wiz.GetSocketStatus(id), 2)
  pst.char(13)

PRI PrintAllStatuses | i
  pst.str(string(CR, "Socket Status", CR))
  repeat i from 0 to HTTPSOCKETS
    pst.dec(i)
    pst.str(string("  "))
  pst.char(CR)
  repeat i from 0 to HTTPSOCKETS
    pst.hex(wiz.GetSocketStatus(i), 2)
    pst.char($20)
  pst.char(CR)
      
PRI PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)
      
PRI PrintExtension
  pst.str(req.GetFileNameExtension)
  pst.char(CR)

PRI PrintRequestedFileName
  pst.str(req.GetFileName)
  pst.char(CR)  
    
PRI PrintTokens | i, tcnt   
  't1 := req.GetTokens
  tcnt := req.GetStatusLineTokenCount
  repeat i from 0 to tcnt-1
    pst.str(req.EnumerateHeader(i))
    pst.char(CR)

PUB DisplayUdpHeader(buffer) | i
  pst.char(CR)
  pst.str(string(CR, "Message from:......."))
  PrintIp(buffer)
  pst.char(":")
  pst.dec(DeserializeWord(buffer + 4))
  pst.str(string(" Size:"))
  pst.dec(DeserializeWord(buffer + 6))
  pst.char(CR)
  
  repeat 20
    PrintIp( buffer)
    buffer += 4
    
PUB DisplayHumanTime
    if byte[@MM_DD_YYYY][3]<10
       pst.Char("0")
    pst.dec(byte[@MM_DD_YYYY][3])
    pst.Char("/")
    if byte[@MM_DD_YYYY][2]<10
       pst.Char("0")
    pst.dec(byte[@MM_DD_YYYY][2])
    pst.Char("/")
    pst.dec(word[@MM_DD_YYYY][0])                    
    pst.Char($20)
    if byte[@DW_HH_MM_SS][2]<10
       pst.Char("0")
    pst.dec(byte[@DW_HH_MM_SS][2])
    pst.Char(":")
    if byte[@DW_HH_MM_SS][1]<10
       pst.Char("0")
    pst.dec(byte[@DW_HH_MM_SS][1])
    pst.Char(":")
    if byte[@DW_HH_MM_SS][0]<10
       pst.Char("0")
    pst.dec(byte[@DW_HH_MM_SS][0])
    pst.str(string("(GMT "))
    if Zone<0
       pst.Char("-")
    else
       pst.Char("+")
    pst.str(string(" ",||Zone+48,":00) "))
    pst.Char(13)
    
PRI FillTime(ptr)
 '00/00/0000 00:00:00

  rtc.readTime

  FillTimeHelper(rtc.clockMonth, ptr)
  ptr += 3

  FillTimeHelper(rtc.clockDate, ptr)
  ptr += 3

  FillTimeHelper(rtc.clockYear, ptr)
  ptr += 5

  FillTimeHelper(rtc.clockHour , ptr)
  ptr += 3

  FillTimeHelper(rtc.clockMinute , ptr)
  ptr += 3

  FillTimeHelper(rtc.clockSecond, ptr) 
 
  return ptr-17

PRI FillDay(ptr)
  rtc.readTime
  bytemove(ptr, rtc.getDayString, 3)
  return ptr
  
PRI FillTimeHelper(value, ptr) | t1
  if(value < 10)
    byte[ptr++] := "0"
  
  t1 := Dec(value)
  bytemove(ptr, t1, strsize(t1))


PUB Dec(value) | i, x, j
{{Send value as decimal characters.
  Parameter:
    value - byte, word, or long value to send as decimal characters.

Note: This source came from the Parallax Serial Termianl library
}}

  j := 0
  x := value == NEGX                                                            'Check for max negative
  if value < 0
    value := ||(value+x)                                                        'If negative, make positive; adjust for max negative                                                                  'and output sign

  i := 1_000_000_000                                                            'Initialize divisor

  repeat 10                                                                     'Loop for 10 digits
    if value => i
      workspace[j++] := value / i + "0" + x*(i == 1)                                      'If non-zero digit, output digit; adjust for max negative
      value //= i                                                               'and digit from value
      result~~                                                                  'flag non-zero found
    elseif result or i == 1
      workspace[j++] := "0"                                                                'If zero digit (or only digit) output it
    i /= 10
    
  workspace[j] := 0
  return @workspace

PRI nbDebug(nbs, showdata) | i
  
  if (nbs>0)
    PST.Str(string(CR,"NB size "))
    PST.Dec(netbios.GetLastReadSize)
    case nbs
      1:
        PST.Str(string(" host todo "))
      2:
        PST.Str(string(" group todo "))
      3:
        PST.Str(string(" other "))
      11:
        PST.Str(string(" host PosQueryResp  "))
      12:
        PST.Str(string(" host StatQueryResp "))
      21:
        PST.Str(string(" group PosQueryResp  "))
    netbios.DecodeLastNameInplace
    PST.Str(netbios.GetLastName)
    pst.str(string(" Request from: "))
    PrintIp(@buff)
    
   
    PST.char(":")
    PST.dec(DeserializeWord(@buff + 4))
    PST.str(string(" ("))
    PST.dec(DeserializeWord(@buff + 6))
    PST.str(string(")"))

    if showdata
      DisplayUdpHeader(@Buff)    

PRI DeserializeWord(buffer) : value
  value := byte[buffer++] << 8
  value += byte[buffer]
  
PRI StrToBase(stringptr, base) : value | chr, index
{Converts a zero terminated string representation of a number to a value in the designated base.
Ignores all non-digit characters (except negative (-) when base is decimal (10)).}

  value := index := 0
  repeat until ((chr := byte[stringptr][index++]) == 0)
    chr := -15 + --chr & %11011111 + 39*(chr > 56)                              'Make "0"-"9","A"-"F","a"-"f" be 0 - 15, others out of range     
    if (chr > -1) and (chr < base)                                              'Accumulate valid values into result; ignore others
      value := value * base + chr                                                  
  if (base == 10) and (byte[stringptr] == "-")                                  'If decimal, address negative sign; ignore otherwise
    value := - value
             
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return

DAT
  divider   byte  CR, "-----------------------------------------------", CR, $0