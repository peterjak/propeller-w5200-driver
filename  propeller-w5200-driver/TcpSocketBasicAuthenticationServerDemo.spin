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
  user_pw       byte  "web:web"
  _null         byte  $0
  authVlaue     byte  "Basic "
  base64auth    byte  $0[64]
  auth          byte  "HTTP/1.1 401 Access Denied", CR, LF,  {
}                     "WWW-Authenticate: Basic realm=", $22, "localhost", $22, CR, LF, {
}                     "Content-Length: 4033", CR, LF, {
}                     "Content-Type: text/html", CR, LF, CR, LF, {
}                     "<h1>401 Access Denied</h1>", CR, LF, $0  
  index         byte  "HTTP/1.1 200 OK", CR, LF, {
}                     "Content-Type: text/html", CR, LF, CR, LF, {
}                     "<h1>Hello World!</h1>", CR, LF, $0
  notFound      byte  "HTTP/1.0 404 Not Found", CR, LF, {
}                     "Content-Type: text/html", CR, LF, CR, LF, { 
}                     "<h1>404 Not Found!</h1>", CR, LF, $0
  statusLine    byte  "++++", $0
  buff          byte  $0[BUFFER_2K]
  resPtr        long  $0[50]
  tokens        long  $0
  t1            long  $0

OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5200" 
  sock          : "Socket"
  b64           : "base64"
 
PUB Main | bytesToRead

  bytesToRead := 0
  pst.Start(115_200)
  pause(500)

  'Encode the username and password used in basic authentication
  repeat t1 from 0 to @_null - @user_pw - 1
    b64.out(user_pw[t1])
  t1 := b64.end
  bytemove(@base64auth, t1, strsize(t1))
  pst.str(@base64auth)
  pst.char(CR)

  wiz.Init 
  wiz.SetIp(192, 168, 1, 107)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  
  pst.str(string("Initialize Socket",CR))
  sock.Init(0, TCP, 8080)

  pst.str(string("Start Socket server",CR))
  repeat
   {
    pst.str(string("Status "))  
    pst.dec(wiz.SocketStatus(0))
    pst.char(CR)
    }
    wiz.SocketStatus(0)
    
    pst.str(string(CR, "---------------------------",CR))
    'pst.str(string("Open",CR))
    sock.Open

    'pst.str(string("Status "))  
    'pst.hex(wiz.SocketStatus(0), 2)
    'pst.char(CR)

    
    if(sock.Listen)
      pst.str(string("Listen",CR))
    else
      pst.str(string("Listener failed!",CR))  
    pst.str(string(CR, "---------------------------",CR))
    
    'Connection?
    repeat until sock.Connected
      pause(100)

    'pst.str(string("Connected",CR))
    
    'Data in the buufer?
    repeat until bytesToRead := sock.Available

    'Check for a timeout
    if(bytesToRead < 0)
      bytesToRead~
      next

   'pst.str(string("Copy Rx Data",CR))
  
    'Get the Rx buffer  
    sock.Receive(@buff, bytesToRead)

    pst.char(CR)
    pst.str(@buff)

    'Tokenize the header
    TokenizeHeader(@buff, bytesToRead)

    'Quit if the browser is looking for favicon.ico
    if(StatusLineContains(string("favicon.ico")))
      pst.str(string("404 Error", CR))
      sock.Send(@notFound, strsize(@notFound))
      sock.Disconnect
      bytesToRead~
      next
    
    {{ Process the Rx data}}
    'Check for Authorization header
    {
    if(IsAuthenticated)
      pst.str(string("Authenticated", CR))
      sock.Send(@index, strsize(@index))
    else
      pst.str(string("Not Authenticated", CR))
      sock.Send(@auth, strsize(@auth))
    }

    sock.Send(@index, strsize(@index))

    
    'pst.str(string("Disconnect",CR))
    sock.Disconnect
    
    bytesToRead~


PUB TokenizeHeader(header, len) | ptr, isToken
  ptr := header
  tokens := 0
  isToken := false
  
  'Parse the status line
  resPtr[tokens++] := header
  repeat until IsEndOfLine(byte[ptr])
    pst.char(byte[ptr])
 
    if(IsStatusLineToken(byte[ptr]))
      byte[ptr++] := 0
      isToken := true
      pst.char("-")
      pst.dec(tokens)
    else
      if(isToken)
        resPtr[tokens++] := ptr++
        isToken := false
        pst.char("*")
        pst.dec(tokens)
      else        
        ptr++
        pst.char("+")
        pst.dec(tokens)
      
    pst.char(CR)

  'Terminate the status line CR LF
  isToken := false 
  byte[ptr++] := 0
  if(byte[ptr] == LF)
    byte[ptr++] := 0

  'Add a null to divide the status line with the headers
  resPtr[tokens++] := @statusLine '@_null '@statusLine
  resPtr[tokens++] := ptr

  t1 := FindBody(ptr, strsize(resPtr[tokens-1]) )

  {
  pst.str(string("Body ptr "))
  pst.dec(t1)
  pst.char(CR)
  pst.str(string("Header Len "))
  pst.dec(t1 - ptr)
  pst.char(CR)
  }
  'Terminate the header to body
  'repeat strsize(resPtr[tokens-1]) - t1
    'byte[ptr++] := 0

  'Parse the rest of the header
  repeat until ptr > t1
    pst.char(byte[ptr]) 
    if(IsHeaderToken(byte[ptr]))    
      byte[ptr++] := 0
      isToken := true
      pst.char("-")
      pst.dec(tokens)
    else
      if(isToken)
        if(byte[ptr] == $20)
          ptr++
        resPtr[tokens++] := ptr++
        isToken := false
        pst.char("*")
        pst.dec(tokens)
      else        
        ptr++
        pst.char("+")
        pst.dec(tokens)
      
    pst.char(CR)

  PrintTokens  
      

PUB FindBody(ptr, len)
  repeat len
    if(byte[ptr] == CR AND byte[ptr+1] == LF AND byte[ptr+2] == CR AND byte[ptr+3] == LF)
      return ptr
    if(byte[ptr] == LF  AND byte[ptr+1] == LF)
      return ptr
    ptr++
    
  return 0

PUB PrintTokens | j
  'Print tokens
  repeat j from 0 to tokens-1
    if(j < 10)
      pst.char($30)
    pst.dec(j)
    pst.char($20)
    'pst.dec(strsize(resPtr[j]))
    'pst.char($20)
    pst.str(resPtr[j])
    pst.char(CR)
    

PUB IsAuthenticated
  return strcomp( @authVlaue, GetHeaderValue( string("Authorization") ) )
    
PUB GetHeaderValue(key) | i
  repeat i from 0 to tokens-1
    if(strcomp(key, resPtr[i]))
      return resPtr[i+1]

  return NULL

PUB GetStatusLineByIndex(idx) | i
  i := 0
  repeat while (strsize(resPtr[i++]) > NULL)

  if(idx > i)
    return @_null

  return resPtr[idx]

PUB StatusLineContains(value) | i
  i := 0
  repeat while (strsize(resPtr[i]) > NULL)
    if(strcomp(value, resPtr[i++]))
      return true

  return false 

PUB IsStatusLineToken(value)
  return lookdown(value & $FF: "/", "?", "=", " ")
  
PUB IsHeaderToken(value)
  return lookdown(value: ":", CR, LF)
  
PUB IsEndOfLine(value)
  return lookdown(value: CR, LF)
       
PUB PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)
  
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return