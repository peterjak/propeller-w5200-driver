CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  HEADER_BUFFER       = $200
  
  CR    = $0D
  LF    = $0A
  
  TOKEN_POINTERS                = $FF
  HEADER_SECTIONS               = 4
  FILE_EXTENSION_LEN            = 3
  MIN_STATUS_LINE_TOKENS        = 3

  #0, STATUS_LINE, QUERYSTRING, HEADER_LINES, BODY

VAR

DAT
  buffer          byte  $0[HEADER_BUFFER]
  index           byte  "index.htm", $0
  isFileReq       byte  $0
  ext             byte  $0[3], $0
  sectionTokenCnt byte  $0[HEADER_SECTIONS]
  tokens          byte  $0 
  null            long  $0
  headerSections  long  $0[HEADER_SECTIONS]
  tokenPtr        long  $0[TOKEN_POINTERS]
  ptr             long  $0
  isToken         long  $0
  t1              long  $0



PUB Get(key) | i, p
  if(sectionTokenCnt[QUERYSTRING] == 0)
    return null

  p :=  PathElements  
  repeat i from p to sectionTokenCnt[STATUS_LINE]-2
    if(strcomp(key, tokenPtr[i]))
      return tokenPtr[i+1]
  return @null

PUB QueryStringElements
  'HTTP path/file.ext?name=value HTTP/1.1
  return sectionTokenCnt[QUERYSTRING]

PUB Header(key) | i
  repeat i from sectionTokenCnt[STATUS_LINE] to sectionTokenCnt[HEADER_LINES]
    if(strcomp(key, tokenPtr[i]))
        return tokenPtr[i+1]
  return @null

PUB Post(key) | i
  repeat i from sectionTokenCnt[HEADER_LINES] to sectionTokenCnt[BODY]
    if(strcomp(key, tokenPtr[i]))
        return tokenPtr[i+1]
  return @null
 
PUB Request(key) | i
  repeat i from 0 to sectionTokenCnt[BODY]-1
    if(strcomp(key, tokenPtr[i]))
      return tokenPtr[i+1]
  return @null

PUB UrlContains(value) | i
  repeat i from 1 to sectionTokenCnt[STATUS_LINE]-3
    if(strcomp(value, tokenPtr[i]))
      return true
  return false

PUB PathElements
  'return sectionTokenCnt[STATUS_LINE]-3
  '[Status line token count] - [Querystring token count] - [3] 
  return ( (sectionTokenCnt[STATUS_LINE] - sectionTokenCnt[QUERYSTRING] - MIN_STATUS_LINE_TOKENS)  #> 0 )

PUB GetUrlPart(value)
  if(sectionTokenCnt[STATUS_LINE] == 3)
    return string("\")
  if((value >  sectionTokenCnt[STATUS_LINE]-3) OR (++value > sectionTokenCnt[STATUS_LINE]-3))
    return @null
    
  return EnumerateHeader(value)

PUB GetFileName | i, j
  repeat i from 1 to sectionTokenCnt[STATUS_LINE]-2
    t1 := tokenPtr[i]
    repeat j from 0 to strsize(t1)-1
      if(byte[t1][j] == ".")
        return tokenPtr[i]
  return @index

PUB IsFileRequest
  return isFileReq

PRI UrlContainsFileRequest | i, j
  repeat i from 1 to sectionTokenCnt[STATUS_LINE]-2
    t1 := tokenPtr[i]
    repeat j from 0 to strsize(t1)-1
      if(byte[t1][j] == ".")
        return true
  return false

PUB GetFileNameExtension
  return @ext

PRI _GetFileNameExtension | i, j
  repeat i from 1 to sectionTokenCnt[STATUS_LINE]-2
    t1 := tokenPtr[i]
    repeat j from 0 to strsize(t1)-1
      if(byte[t1][j] == ".")
        return tokenPtr[i]+j+1
  return @index + strsize(@index)-FILE_EXTENSION_LEN 
  'return string("xxx")  

PUB Decode(value)
  DecodeString(value)
  return value

PUB GetTokens
  return tokens
  
PUB EnumerateHeader(idx)
  return tokenPtr[idx]

PUB GetSectionCount(idx)
  return sectionTokenCnt[idx]
  
PUB TokenizeHeader(buff, len)

  tokens := 0
  isToken := false

  headerSections[QUERYSTRING] := null
  sectionTokenCnt[QUERYSTRING] := null 
    
  ' Copy the header and clear
  bytemove(@buffer, buff, len)
  ptr := @buffer
  buff := @buffer
  byte[buff][len] := 0

  'Initialize pointer arrays
  'Mark the start of the status line
  tokenPtr[tokens++] := buff
  headerSections[STATUS_LINE] := buff
    
  'Parse the status line 
  repeat until IsEndOfLine(byte[ptr]) 
    if(IsStatusLineToken(byte[ptr]))
      'Set a pointer to the querystring if one exists
      if(byte[ptr] == "?")
        headerSections[QUERYSTRING] := ptr
        sectionTokenCnt[QUERYSTRING] := tokens-1
      byte[ptr++] := 0
      isToken := true
    else
      if(isToken)
        tokenPtr[tokens++] := ptr++
        isToken := false
      else        
        ptr++

  'Terminate the status line CR LF
  isToken := false 
  repeat until NOT IsEndOfLine(byte[ptr])
    byte[ptr++] := 0

  'Save the file type
  bytemove(@ext, _GetFileNameExtension, 3)

  'Mark the start of the header lines
  sectionTokenCnt[STATUS_LINE] := tokens
  
  'Get the query string count
  if(sectionTokenCnt[QUERYSTRING]) 
    sectionTokenCnt[QUERYSTRING] := tokens - sectionTokenCnt[QUERYSTRING] - 3
    
  headerSections[HEADER_LINES] := ptr
  tokenPtr[tokens++] := ptr

  t1 := FindBody(ptr, strsize(tokenPtr[tokens-1]) )
  
  'Tokenize the the header lines
  repeat until ptr > t1-1
    if(IsHeaderToken(byte[ptr], byte[ptr+1]))   
      byte[ptr++] := 0
      isToken := true
    else
      if(isToken)
        if(byte[ptr] == $20)
          ptr++
        tokenPtr[tokens++] := ptr++
        isToken := false
      else        
        ptr++

  sectionTokenCnt[HEADER_LINES] := tokens
  
  'Skip the two end of line chars
  repeat until NOT IsEndOfLine(byte[ptr])
    byte[ptr++] := 0

  'Mark the start of the body
  headerSections[BODY] := ptr

  'Decode the url
  repeat t1 from 1 to sectionTokenCnt[STATUS_LINE]-3
    DecodeString(tokenPtr[t1])

  'Determine if a file is being requested
  'Otherwise this can request can be a RESTful call
  isFileReq := UrlContainsFileRequest
  
  'Return if body does not contain data
  if(ptr == (buff + len))
    sectionTokenCnt[BODY] := sectionTokenCnt[HEADER_LINES] 
    return

  'Decode POST data
  if(strcomp(tokenPtr[0], string("POST")))
    DecodeString(ptr)

  'Tokenize the body
  tokenPtr[tokens++] := ptr++
  repeat until ptr > (buff + len)-1
    if(IsPostToken(byte[ptr]))    
      byte[ptr++] := 0
      isToken := true
    else
      if(isToken)
        if(byte[ptr] == $20)
          ptr++
        tokenPtr[tokens++] := ptr++
        isToken := false
      else        
        ptr++
        
  sectionTokenCnt[BODY] := tokens


PRI FindBody(value, len)
  repeat len
    if(byte[value] == CR AND byte[value+1] == LF AND byte[value+2] == CR AND byte[value+3] == LF)
      return value
    if(byte[value] == LF  AND byte[value+1] == LF)
      return value
    value++ 
  return null
  
PRI IsStatusLineToken(value)
  return lookdown(value & $FF: "/", "?", "=", "+", " ", "&")
  
PRI IsHeaderToken(value1, value2)
  if(value1 == ":" AND NOT value2 == " ")
    return false
  return lookdown(value1: ":", CR, LF)

PRI IsPostToken(value)
  return lookdown(value & $FF: "=", "+", "&")    
  
PRI IsEndOfLine(value)
  return lookdown(value: CR, LF)

PRI DecodeString(source) | char, inPlace, outPlace
  inPlace := outPlace := 0
  repeat
    'TODO: Handle HTML encoing ie &alt;  
    char := byte[source][inPlace++]
    if (char == "%") ' convert %## back into a character
      ' first nibble
      char := byte[source][inPlace++] - 48
      if (char > 9)
        char -= 7
      char := char << 4
      byte[source][outPlace] := char
      ' second nibble
      char := byte[source][inPlace++] - 48
      if (char > 9)
        char -= 7
      byte[source][outPlace++] += char
      ' since we trashed char doing the decode, we need this to keep the loop going
      char := "x"
    elseif (char == "+") ' convert + back to a space
      byte[source][outPlace++] := " "
    else ' no conversion needed, just set the character
      byte[source][outPlace++] := char
  until (char == 0)
    
  byte[source][outPlace-1] := 0 ' terminate the string at it's new shorter size

'-------------[ Debug ]------------------------------------
PUB GetStatusLine
  return headerSections[STATUS_LINE]

PUB GetHeaderLines
  return headerSections[HEADER_LINES]

PUB GetBody
  return headerSections[BODY]

PUB GetStatusLineTokenCount
  return sectionTokenCnt[STATUS_LINE]

PUB GetHeaderLinesTokenCount
  return sectionTokenCnt[HEADER_LINES]  - sectionTokenCnt[STATUS_LINE]

PUB GetBodyTokenCount
  return  sectionTokenCnt[BODY] - sectionTokenCnt[HEADER_LINES]