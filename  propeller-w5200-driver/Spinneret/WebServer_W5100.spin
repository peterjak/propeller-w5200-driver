CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  TCP_MTU       = 1460
  MAIN_BUFFER   = $800
  BUFFER_2K     = $800
  BUFFER_LOG    = $80
  BUFFER_WS     = $20
  
  CR            = $0D
  LF            = $0A

  { Web Server Configuration }
  SOCKETS       = 4
  DHCP_SOCK     = 3
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
              
  {{ USA Daylight Time Zone Abbreviations  }}
  #-9, HDT,AtDT,PDT,MDT,CDT,EDT,AlDT

  Zone = MST 
    
VAR
  long  buttonStack[10]
  long  longHIGH, longLOW, MM_DD_YYYY, DW_HH_MM_SS 'Expected 4-contigous variables for SNTP  
  
DAT
  version       byte  "1.1", $0
  hasSd         byte  $00
  approot       byte  "\", $0
  _404          byte  "HTTP/1.1 404 OK", CR, LF,                                {
}                     "Content-Type: text/html", CR, LF, CR, LF,                {
}                     "<html>",                                                 {
}                     "<head>",                                                 {
}                     "<title>Not Found</title><head>",                         {
}                     "<body>",                                                 {
}                     "Page not found!",                                        {                                                                                                       
}                     "</body>",                                                {
}                     "</html>", CR, LF, $0

  xsltPinState   byte  "<?xml version='1.0' encoding='utf-8'?>", CR, LF, {
  }                   "<?xml-stylesheet type='text/xsl' href='pinstate.xsl'?>", CR , LF, {
  }                   "<root>", CR, LF, "  <pin>" 
  xslPinNum     byte  $30, $30, $30, "</pin>", CR, LF, "  <value>"
  xslPinState   byte  $30, $30, $30, "</value>", CR, LF, "  <dir>" 
  xslPinDir     byte  $30, $30, $30, "</dir>", CR, LF,                               {
}                     "</root>", 0

  xmlPinState   byte  "<?xml version='1.0' encoding='utf-8'?>", CR, LF, {
  }                   "<root>", CR, LF, "  <pin>" 
  pinNum        byte  $30, $30, $30, "</pin>", CR, LF, "  <value>"
  pinState      byte  $30, $30, $30, "</value>", CR, LF, "  <dir>" 
  pinDir        byte  $30, $30, $30, "</dir>", CR, LF,                               {
}                     "</root>", 0

  xmlSint       byte  "<root>", CR, LF, "  <sint>" 
  xsint         byte  "00000</sint>", CR, LF, "</root>", 0
  
  xmlTime       byte  "<root>", CR, LF, "  <time>" 
  xtime         byte  "00/00/0000 00:00:00</time>", CR, LF, "</root>", 0

  _h200         byte  "HTTP/1.1 200 OK", CR, LF, $0
  _h404         byte  "HTTP/1.1 404 Not Found", CR, LF, $0
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
  _contLen      byte  "Content-Length: ", $0   
  _newline      byte  CR, LF, $0
  time          byte  "00/00/0000 00:00:00", 0
  workSpace     byte  $0[BUFFER_WS]
  logBuf        byte  $0[BUFFER_LOG]
  wizver        byte  $00
  buff          byte  $0[MAIN_BUFFER+1]
  null          long  $00
  contentType   long  @_css, @_gif, @_html, @_ico, @_jpg, @_js, @_pdf, @_png, @_txt, @_xml, @_zip, $0
  mtuBuff       long  TCP_MTU
   

OBJ
  pst             : "Parallax Serial Terminal"
  wiz             : "W5100"
  dhcp            : "Dhcp" 
  sock[SOCKETS]   : "Socket"
  req             : "HttpHeader"
  sd              : "S35390A_SD-MMC_FATEngineWrapper"
  sntp            : "SNTP Simple Network Time Protocol v2.01"
  rtc             : "S35390A_RTCEngine"
  'gadget          : "ThermometerGadget"
 
PUB Init | i, t1

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
  {
  pst.str(string(CR, "COG["))
  i := pst.GetCogId
  pst.dec(i)
  pst.str(string("]: Parallax Serial Terminal"))
  }
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
  wiz.SetMac($00, $08, $DC, $16, $F1, $32)

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
  'Start up the web server
  '---------------------------------------------------
  pst.str(string(CR, "Initialize Sockets"))
  pst.str(@divider)
  repeat i from 0 to SOCKETS-1
    sock[i].Init(i, WIZ#TCP, HTTP_PORT)

  OpenListeners
  StartListners

  pst.str(string(CR, "Start Socket Services", CR))
  MultiSocketService

  pst.str(string("Fatal Error!!!"))  
  CloseAll
  pst.str(string(CR, "Rebooting..."))
  pause(1000) 
  reboot
  
PRI MultiSocketService | bytesToRead, sockId, fn, i, pathElements
  bytesToRead := sockId := 0
  i := 0
  repeat
     
    bytesToRead~ 
    CloseWait
    
    'Cycle through the sockets one at a time
    'looking for a connections
    'pst.str(string(CR, "Waiting for a connection", CR))
    'PrintAllStatuses 
    repeat until sock[sockId].Connected
      sockId := ++sockId // SOCKETS

    'pause(20)
    
    'Repeat until we have data in the buffer
    repeat until bytesToRead := sock[sockId].Available

    'PrintAllStatuses

    'Check for a timeout error
    if(bytesToRead =< 0)
      pst.str(string(CR, "Timeout: "))
      pst.dec(bytesToRead) 
      PrintAllStatuses
      if(i++ == 1)
        sock[sockId].Disconnect
        i := 0    
      next
       
    'Move the Rx buffer into HUB memory
    sock[sockId].Receive(@buff, bytesToRead)

    'Display the request header
    'pst.str(@buff)

    'Tokenize and index the header
    req.TokenizeHeader(@buff, bytesToRead)
    fn := req.GetFileName
    
    'http://192.168.1.110/xslpin.xml?led=23&value=-1
    {
    pst.str(string("Status Line #..."))
    pst.dec(req.GetSectionCount(REQ#STATUS_LINE))
    pst.char(CR)

    pst.str(string("QS #............"))
    pst.dec(req.GetSectionCount(REQ#QUERYSTRING))
    pst.char(CR)
    
    PrintTokens(0, 5)
     }  
    'PrintRequestedFileName
    pathElements := req.PathElements

    {
    pst.str(string("Path Elements..."))
    pst.dec(pathElements)
    pst.char(CR)
    }
     
    if(FileExists(fn, pathElements))
      RenderFile(sockId, fn)
    else
      ifnot(RenderDynamic(sockId))
        sock[sockId].Send(@_404, strsize(@_404))

    'Close the socket and reset the
    'interupt register
    sock[sockId].Disconnect
    sock[sockId].SetSocketIR($FF)

    sockId := ++sockId // SOCKETS
    
 
PRI BuildAndSendHeader(id, contentLength, ext) | dest, src
  dest := @buff
  bytemove(dest, @_h200, strsize(@_h200))
  dest += strsize(@_h200)

  src := GetContentType(GetExtension(ext))
  bytemove(dest, src, strsize(src))
  dest += strsize(src)

  'Add content-length : value CR, LF
  if(contentLength > 0)
    bytemove(dest, @_contLen, strsize(@_contLen))
    dest += strsize(@_contLen)
    src := Dec(contentLength)
    bytemove(dest, src, strsize(src))
    dest += strsize(src)
    bytemove(dest, @_newline, strsize(@_newline))
    dest += strsize(@_newline)

  'End the header with a new line
  bytemove(dest, @_newline, strsize(@_newline))
  dest += strsize(@_newline)
  byte[dest] := 0

  sock[id].send(@buff, strsize(@buff))  


PRI GetExtension(fn)  
  return fn + (strsize(fn) - 3)

PRI RenderDynamic(id) | value

  'Process pinstate
  if(strcomp(req.GetFileName, string("pinstate.xml")))
    BuildPinStateXml( req.Get(string("led")), req.Get(string("value")) )
    BuildAndSendHeader(id, -1, string("xml"))
    sock[id].Send(@xmlPinState, strsize(@xmlPinState))
    return true

  if(strcomp(req.GetFileName, string("p_encode.xml")))
    BuildPinEndcodeStateXml( req.Get(string("value")) )
    BuildAndSendHeader(id, -1, string("xml"))
    sock[id].Send(@xmlPinState, strsize(@xmlPinState))
    return true

  if(strcomp(req.GetFileName, string("xslpin.xml")))
    BuildXslPinStateXml( req.Get(string("led")), req.Get(string("value")) )
    BuildAndSendHeader(id, -1, string("xml"))
    sock[id].Send(@xsltPinState, strsize(@xsltPinState))
    return true

  if(strcomp(req.GetFileName, string("sint.xml")))
    value := -123
    WriteInt(value)
    BuildAndSendHeader(id, -1, string("xml"))
    sock[id].Send(@xmlSint, strsize(@xmlSint))
    return true

  return false

PRI WriteInt(theInt) | ptr, len
  'Clear the element value
  bytefill(@xsint, "0", 5)

  'Integer to string and get the length  
  ptr :=  Dec(theInt)
  len := strsize(ptr)

  'Write the element value
  'Add a "-" if the number is negative 
  if(theInt < 0 )
    xsint[0] := "-"
    bytemove(@xsint+1 + (4-len), ptr, len)
  else
    bytemove(@xsint + (5-len), ptr, len)
   

PRI BuildPinStateXml(strpin, strvalue) | pin, value, state, dir
  pin := StrToBase(strpin, 10)
  value := StrToBase(strvalue, 10)  

  SetPinState(pin, value)
  state := ReadPinState(pin)

  'Write the pin number to the XML doc
  PadLeft(@pinNum, strpin, 3, "0")

  'Write the pin value
  value := Dec(ReadPinState(pin))
  PadLeft(@pinState, value, 3, "0")

  'Write Pin direction
  dir := Dec(ReadDirState(pin))
  PadLeft(@pinDir, dir, 3, "0")

PRI PadLeft(dest, source, len, padChar)
  'Fill the destination buffer with the padding char
  if(strsize(source) < len)
    bytefill(dest, padChar,  len)

  'Write the string offset from the start of the destination buffer
  bytemove(dest+len-strsize(source), source, strsize(source))

PRI PadRight(dest, source, len, padChar)
  'Fill the destination buffer with the padding char 
  if(strsize(source) < len)
    bytefill(dest, padChar,  len)
    
  'Write to the start of the destination buffer
  bytemove(dest, source, strsize(source))



PRI BuildXslPinStateXml(strpin, strvalue) | pin, value, state, dir
  pin := StrToBase(strpin, 10)
  value := StrToBase(strvalue, 10)


  pst.str(string("Pin: "))
  pst.dec(pin)
  pst.char(CR)
  
  pst.str(string("Value: "))
  pst.dec(value)
  pst.char(CR)  

  SetPinState(pin, value)
  state := ReadPinState(pin)

  'Write the pin number to the XML doc
  PadLeft(@xslPinNum, strPin, 3, "0")
  {
  if(strsize(strpin) > 1)
    bytemove(@xslPinNum,strpin, 2)
  else
    byte[@xslPinNum] := $30
    byte[@xslPinNum][1] := byte[strpin]
  }
  'Write the pin value
  value := Dec(ReadPinState(pin))
  PadLeft(@xslPinState, value, 3, "0")
  {
  if(strsize(value) > 1)
    bytemove(@xslPinState, value, 2)
  else
    byte[@xslPinState] := $30
    byte[@xslPinState][1] := byte[value]
  }
  'Write Pin direction
  dir := Dec(ReadDirState(pin))
  PadLeft(@xslPinDir, dir, 3, "0")
  {
  if(strsize(dir) > 1)
    bytemove(@xslPinDir, value, 2)
  else
    byte[@xslPinDir] := $30
    byte[@xslPinDir][1] := byte[dir]
 }
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
  'bytemove(@pinNum,string("$F"), 2)

  PadLeft(@pinNum, string("$F"), 3, "0") 

  'Write the pin value
  value := Dec(ReadEncodedPinState)
  PadLeft(@pinState, value, 3, "0")
  {
  if(strsize(value) > 1)
    bytemove(@pinState, value, 2)
  else
    byte[@pinState] := $30
    byte[@pinState][1] := byte[value]
  }
  'Write Pin direction
  dir := Dec(ReadEncodedDirState)
  PadLeft(@dir, dir, 3, "0")
  {
  if(strsize(dir) > 1)
    bytemove(@pinDir, value, 2)
  else
    byte[@pinDir] := $30
    byte[@pinDir][1] := byte[dir]
 }
    
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

  
PRI RenderFile(id, fn) | fs, bytes
{{
  Render a static file from the SD Card
}}
  mtuBuff := sock[id].GetMtu

  OpenFile(fn)
  fs := sd.getFileSize 
  BuildAndSendHeader(id, fs, fn)

  'pst.str(string(cr,"Render File",cr))
  repeat until fs =< 0
    'Writeline(string("Bytes Left"), fs)

    if(fs < mtuBuff)
      bytes := fs
    else
      bytes := mtuBuff

    sd.readFromFile(@buff, bytes)
    fs -= sock[id].Send(@buff, bytes)
  
  sd.closeFile
  return

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
  rc := sd.listEntry(filename)
  if(rc == IO_OK)
    rc := sd.openFile(filename, IO_READ)
      if(rc == SUCCESS)
        return true
  return false

PRI FileExists(filename, pathElements) | rc
{{
  Verify if the file exists
}}
  ifnot(hasSd)
    return false

  ChangeDirectory(pathElements)
    
  rc := sd.listEntry(filename)
  if(rc == IO_OK)
    rc := sd.openFile(filename, IO_READ)
      if(rc == SUCCESS)
        sd.closeFile
        return true
  return false  

PRI ChangeDirectory(pathElements) | i
  sd.changeDirectory(@approot)
  if(req.IsFileRequest)
    pathElements--  
  'Path elements include a file name
  ' req.IsFileRequest = true if a file is explictly requested
  if(pathElements =< 0)
    'pst.str(string("Root request", CR, CR))
    return
  else
    'pst.str(string("Sub dir request", CR, CR))
    repeat i from 0 to pathElements-1
      'pst.str( req.GetUrlPart(i) )
      'pst.char(CR)
      sd.changeDirectory(req.GetUrlPart(i))
      
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

  if(strcomp(ext, string("xsl")) OR strcomp(ext, string("XSL")))
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
  dhcp.Init(@buff, DHCP_SOCK)

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
  repeat i from 0 to SOCKETS-1  
    sock[i].Open
      
PRI StartListners | i
  repeat i from 0 to SOCKETS-1
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
  repeat i from 0 to SOCKETS-1
    sock[i].SetTransactionTimeout(timeout)

PRI CloseWait | i
  repeat i from 0 to SOCKETS-1
    if(sock[i].IsCloseWait) 
      sock[i].Disconnect
      sock[i].Close
      
    if(sock[i].IsClosed)  
      sock[i].Open
      sock[i].Listen

PRI CloseAll | i
  repeat i from 0 to SOCKETS-1
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
  repeat i from 0 to SOCKETS-1
    pst.dec(i)
    pst.str(string("  "))
  pst.char(CR)
  repeat i from 0 to SOCKETS-1
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
{      
PRI PrintExtension
  pst.str(req.GetFileNameExtension)
  pst.char(CR)
}
PRI PrintRequestedFileName
  pst.str(req.GetFileName)
  pst.char(CR)  
    
PRI PrintTokens(start, end) | i   
  'tcnt := req.GetTokens
  'tcnt := req.GetStatusLineTokenCount
  'pst.str(string("Status line count: "))
  'pst.dec(tcnt)
  'pst.char(CR)
  repeat i from start to end
    pst.str(req.EnumerateHeader(i))
    pst.char(CR)

PUB DisplayUdpHeader(buffer)
  pst.char(CR)
  pst.str(string(CR, "Message from......."))
  PrintIp(buffer)
  pst.char(":")
  pst.dec(DeserializeWord(buffer + 4))
  pst.str(string(" ("))
  pst.dec(DeserializeWord(buffer + 6))
  pst.str(string(")", CR))
    
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
    
PRI FillTime(ptr) | num
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
 
  return @time

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
      workspace[j++] := value / i + "0" + x*(i == 1)                            'If non-zero digit, output digit; adjust for max negative
      value //= i                                                               'and digit from value
      result~~                                                                  'flag non-zero found
    elseif result or i == 1
      workspace[j++] := "0"                                                     'If zero digit (or only digit) output it
    i /= 10
    
  workspace[j] := 0
  return @workspace

PRI DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value
  
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