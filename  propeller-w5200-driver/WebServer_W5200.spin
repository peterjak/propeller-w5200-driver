CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  TCP_MTU       = 1460
  BUFFER_2K     = $800
  BUFFER_WS     = $20
  
  CR            = $0D
  LF            = $0A

  { Web Server Configuration }
  SOCKETS       = 6       
  HTTP_PORT     = 80
  DHCP_SOCK     = 3
  ATTEMPTS      = 5
  DISK_PARTION  = 0

  { SD IO }
  SUCCESS       = -1
  IO_OK         = 0
  IO_READ       = "r"
  IO_WRITE      = "w"
  

  { Serial IO PINs } 
  USB_Rx        = 31
  USB_Tx        = 30

  {{ Content Types }}
  #0, CSS, GIF, HTML, ICO, JPG, JS, PDF, PNG, TXT, XML, ZIP
    
VAR
  'long  t1
  long  buttonStack[10]
  long  dummyStack[10]
  
DAT
  version       byte  "1.1", $0
  
  _404          byte  "HTTP/1.1 404 Not Found", CR, LF,                         {
}                     "Content-Type: text/html", CR, LF, CR, LF,                {
}                     "<html>",                                                 {
}                     "<head>",                                                 {
}                     "<title>Not Found</title><head>",                         {
}                     "<body>",                                                 {
}                     "Page not found!",                                        {                                                                                                       
}                     "</body>",                                                {
}                     "</html>", CR, LF, $0

  touch         byte  "<?xml version='1.0' encoding='utf-8'?>",CR,LF,"<root>",CR,LF,"<t7>"
  _t7           byte  "#333333</t7>", CR, LF,"<t6>"
  _t6           byte  "#333333</t6>", CR, LF,"<t5>"
  _t5           byte  "#333333</t5>", CR, LF,"<t4>"
  _t4           byte  "#333333</t4>", CR, LF,"<t3>"
  _t3           byte  "#333333</t3>", CR, LF,"<t2>"
  _t2           byte  "#333333</t2>", CR, LF,"<t1>"
  _t1           byte  "#333333</t1>", CR, LF,"<t0>"
  _t0           byte  "#333333</t0>",CR,LF,"</root>", $0 
  touchcolor    long  @_t0, @_t1, @_t2, @_t3, @_t4, @_t5, @_t6, @_t7

  _gray         byte  "#666666", $0
  _blue         byte  "#0000FF", $0
  _red          byte  "#FF0000", $0

  
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
  _ext          byte  $00
  workSpace     byte  $0[BUFFER_WS]
  wizver        byte  $00
  buff          byte  $0[BUFFER_2K+1]
  null          long  $00
  contentType   long  @_css, @_gif, @_html, @_ico, @_jpg, @_js, @_pdf, @_png, @_txt, @_xml, @_zip, $0
  mtuBuff      long  TCP_MTU
   

OBJ
  pst             : "Parallax Serial Terminal"
  wiz             : "W5200"
  dhcp            : "Dhcp" 
  sock[SOCKETS]   : "Socket"
  req             : "HttpHeader"
  sd              : "S35390A_SD-MMC_FATEngineWrapper"
  buttons         : "Touch Buttons"  
 
PUB Init | i

  i := 0
  wiz.HardReset(WIZ#WIZ_RESET)
  
  if(ina[USB_Rx] == 0)      '' Check to see if USB port is powered
    outa[USB_Tx] := 0       '' Force Propeller Tx line LOW if USB not connected
  else                      '' Initialize normal serial communication to the PC here                              
    pst.Start(115_200)      '' http://forums.parallax.com/showthread.php?135067-Serial-Quirk&p=1043169&viewfull=1#post1043169
    pause(500)
    
  '---------------------------------------------------
  'Main COG
  '--------------------------------------------------- 
  pst.str(string("COG[0]: QuickStart Web Server v"))
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
    pst.str(string(CR, "Failed to start SD driver"))
  else
    pst.str(string(CR, "COG["))
    i := sd.GetCogId
    pst.dec(i)
    pst.str(string("]: Starting SD Driver"))  
  pause(500)

  pst.str(string(CR,"        Mount SD Card - "))
  pst.str(sd.mount(DISK_PARTION))


  '--------------------------------------------------- 
  'Start the WizNet SPI driver
  '--------------------------------------------------- 
  wiz.Start(WIZ#SPI_CS, WIZ#SPI_SCK, WIZ#SPI_MOSI, WIZ#SPI_MISO)
  pst.str(string(CR, "COG["))
  i := wiz.GetCogId
  pst.dec(i)
  pst.str(string("]: Started W5200 SPI Driver"))

  'Verify SPI connectivity by reading the WizNet 5200 version register 
  wizver := GetVersion
  if(wizver == 0)
    pst.str(string(CR, CR, "SPI communication failed!", CR, "Check connections", CR))
    return
  else
    pst.str(string(CR, "        WizNet 5200 Firmware v") )
    pst.dec(wizver)
  
  '--------------------------------------------------- 
  'Start up the quick start touch buttons
  'LED demo in a new COG
  '--------------------------------------------------- 
  pst.str(string(CR, "COG["))
  i := cognew(ButtonProcess, @buttonStack)
  pst.dec(i) 
  pst.str(string("]: Started Touch Demo"))

  pst.str(string(CR, "COG["))
  i := buttons.GetCogId
  pst.dec(i)
  pst.str(string("]: Loaded Touch Demo PASM"))

  pst.str(string(CR, "COG[n]: "))
  pst.dec(i~ +1)
  pst.str(string(" COGs in Use"))

  pst.str(@divider)
  
  'MAC (Source Hardware Address) must be unique
  'on the local network
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)

  '--------------------------------------------------- 
  'Invoke DHCP to retrived network parameters
  'This assumes the WizNet 5200 is connected 
  'to a router with DHCP support
  '--------------------------------------------------- 
  pst.str(string(CR,"Retrieving Network Parameters...Please Wait"))
  pst.str(@divider)
  if(InitNetworkParameters)
    PrintNetworkParams
  else
    PrintDhcpError
    return     

  pst.str(string(CR, "Initialize Sockets"))
  pst.str(@divider)
  repeat i from 0 to SOCKETS-1
    sock[i].Init(i, WIZ#TCP, HTTP_PORT)

  OpenListeners
  StartListners

  '---------------------------------------------------
  'Debug start/stop COGs
  '---------------------------------------------------
  {
  pst.str(string(CR, "Stopping COG.."))
  pst.dec(wiz.GetCogId)
  wiz.Stop

  pst.str(string(CR, "Starting COG.."))
  wiz.ReStart
  pst.dec(wiz.GetCogId) 

  pst.char(CR)
  } 
  pst.str(string(CR, "Start Socket Services", CR))
  MultiSocketService
  pause(5000)

  
PRI MultiSocketService | bytesToRead, sockId, fn
  bytesToRead := sockId := 0
  repeat
    bytesToRead~ 
    CloseWait
    
    'Cycle through the sockets one at a time
    'looking for a connections
    repeat until sock[sockId].Connected
      sockId := ++sockId // SOCKETS

    'Repeat until we have data in the buffer
    repeat until bytesToRead := sock[sockId].Available

    'PrintAllStatuses
    
    'Check for a timeout error
    if(bytesToRead < 0)
      pst.str(string(CR, "Timeout",CR))
      PrintStatus(sockId)
      PrintAllStatuses 
      next
      
    'Move the Rx buffer into HUB memory
    sock[sockId].Receive(@buff, bytesToRead)

    'Display the request header
    'pst.str(@buff)

    'Tokenize and index the header
    req.TokenizeHeader(@buff, bytesToRead)
 
    fn := req.GetFileName
    if(FileExists(fn))
      RenderFile(sockId, fn)
    else
      ifnot(RenderDynamic(sockId))
        sock[sockId].Send(@_404, strsize(@_404))

    'Close the socket and reset the
    'interupt register
    sock[sockId].Disconnect
    sock[sockId].SetSocketIR($FF)

    sockId := ++sockId // SOCKETS

PRI DummyCog
  return true

PRI ButtonProcess
  Buttons.start(clkfreq / 200)        ' Launch the touch buttons driver sampling 100 times a second
  dira[23..16]~~                      ' Set the LEDs as outputs
  repeat
    outa[23..16] := Buttons.State     ' Light the LEDs when touching the corresponding buttons
 
PRI BuildAndSendHeader(id, contentLength) | dest, src
  dest := @buff
  bytemove(dest, @_h200, strsize(@_h200))
  dest += strsize(@_h200)

  src := GetContentType(req.GetFileNameExtension)
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


PRI RenderDynamic(id)
  if(  strcomp(req.GetFileName, string("touch.xml")) )
    'Read touch QS touch pads and update xml
    BuildXml
    BuildAndSendHeader(id, -1)
    sock[id].Send(@touch, strsize(@touch))
    return true

  return false   

PRI BuildXml | i, state
  state := Buttons.State
  repeat i from 0 to 7
    if( state & (1 << i) )
      bytemove(@@touchcolor[i], @_blue, strsize(@_blue))
    else
      bytemove(@@touchcolor[i], @_gray, strsize(@_gray))   
    

PRI RenderFile(id, fn) | fs, bytes
{{
  Render a static file from the SD Card
}}
  mtuBuff := sock[id].GetMtu

  OpenFile(fn)
  fs := sd.getFileSize 
  BuildAndSendHeader(id, fs)

  'pst.str(string(cr,"Render File",cr))
  repeat until fs =< 0
   ' Writeline(string("Bytes Left"), fs)

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

PRI FileExists(filename) | rc
{{
  Verify if the file exists
}}
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
    else
      pst.str(string("Listener failed ",CR))
    pst.dec(i)
    pst.str(string(" Port....."))
    pst.dec(sock[i].GetPort)
    pst.str(string("; MTU="))
    pst.dec(sock[i].GetMtu)
    pst.str(string("; TTL="))
    pst.dec(sock[i].GetTtl)
    pst.char(CR)

PRI CloseWait | i
  repeat i from 0 to SOCKETS-1
    if(sock[i].IsCloseWait) 
      sock[i].Disconnect
      sock[i].Close
      
    if(sock[i].IsClosed)  
      sock[i].Open
      sock[i].Listen

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
         
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return

DAT
  divider   byte  CR, "-----------------------------------------------", CR, $0