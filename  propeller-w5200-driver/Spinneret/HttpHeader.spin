CON
  PATH_BUFFER         = $80
  
  CR    = $0D
  LF    = $0A
  
  TOKEN_POINTERS                = $80
  HEADER_SECTIONS               = 4
  FILE_EXTENSION_LEN            = 3
  MIN_STATUS_LINE_TOKENS        = 3

  #0, STATUS_LINE, QUERYSTRING, HEADER_LINES, BODY

VAR

DAT
  path            byte  $0[PATH_BUFFER]
  ext             byte  $0[3], $0
  tokens          byte  $0
  sectionTokenCnt byte  $0[HEADER_SECTIONS]
  headerSections  long  $0[HEADER_SECTIONS]
  tokenPtr        long  $0[TOKEN_POINTERS]
  'ptr             long  $0
  isToken         long  $0
  null            long  $0 

PUB GetMethod
  return tokenPtr[0]

PUB GetPath
  return @path

PUB Get(key) | i, p
  if(sectionTokenCnt[QUERYSTRING] == 0)
    return null

  p :=  PathElements  
  repeat i from p to sectionTokenCnt[STATUS_LINE]-2
    if(strcomp(key, tokenPtr[i]))
      return tokenPtr[i+1]
  return @null

PUB QueryStringElements
  return headerSections[QUERYSTRING]+1

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

'PUB PostIdx(idx)
  'return tokenPtr[idx+1]   
 
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
  return ( (sectionTokenCnt[STATUS_LINE] - sectionTokenCnt[QUERYSTRING] - MIN_STATUS_LINE_TOKENS)  #> 0 )

PUB GetUrlPartByIndex(value)
  if(sectionTokenCnt[STATUS_LINE] == 3)
    return string("\")
  if((value >  sectionTokenCnt[STATUS_LINE]-3) OR (++value > sectionTokenCnt[STATUS_LINE]-3))
    return @null
    
  return EnumerateHeader(value)

PUB GetFileName | ptr
  'www.google.com/path/to/a/filename.txt
  'www.google.com/path/to/a/filename.js
  'www.google.com/path/to/a/filename.j

  if(byte[@ext] > 0)
    ptr := @path + strsize(@path) - strsize(@ext) - 1
    repeat 9
      if(byte[--ptr] == "/")
        ++ptr
        quit
      
    return ptr 
     

PUB GetFileNameExtension
  return @ext

PUB IsFileRequest
  return strsize(@ext)

PUB GetSectionIndex(value)
  return sectionTokenCnt[value]
  
PUB Decode(value)
  DecodeString(value)
  return value

PUB GetTokens
  return tokens
  
PUB EnumerateHeader(idx)
  return tokenPtr[idx]

PUB GetSectionCount(idx)
  return sectionTokenCnt[idx]

PRI CopyFullPath(buff) | start, end, char
  path[0] := "/"
  path[1] := 0
  ext[0] := 0
  
  'Filter for a root request by checked the byte after the first "/"
  start := buff
  repeat until byte[start++] == "/"
  if(byte[start] == " " or byte[start] == "?" or byte[start] == "1")
    return

  'Mark the start 
  end := start--
    
  'find the end of the request
  char~
  repeat until char == " " or char == "?"
    char := byte[end++]

  end--

  'move the request
  bytemove(@path, start, end-start)
  byte[@path][end-start] := 0
  end :=  @byte[@path][end-start]
  
  'Save the file extension if we have a file request
  'default.htm0
  repeat 4
    if(byte[--end] == ".")
      bytemove(@ext, end+1, strsize(end) <# FILE_EXTENSION_LEN)
  
  DecodeString(@path)


PUB TokenizeHeader(buff, len) | bodyPtr, t1, ptr

  tokens := 0
  isToken := false

  headerSections[QUERYSTRING] := null
  sectionTokenCnt[QUERYSTRING] := null 

  ptr := buff
  byte[buff][len] := 0

  CopyFullPath(buff)

  'Initialize pointer arrays
  'Mark the start of the status line
  tokenPtr[tokens++] := buff
  headerSections[STATUS_LINE] := buff
  
  
  'Process the status line
  repeat until IsEndOfLine(byte[ptr]) 
    if(IsStatusLineToken(byte[ptr]))
      'Set a pointer to the querystring if we find a "?"
      if(byte[ptr] == "?")
        headerSections[QUERYSTRING] := ptr+1
        sectionTokenCnt[QUERYSTRING] := tokens-1
      byte[ptr++] := 0
      isToken := true
    else
      if(isToken)
        tokenPtr[tokens++] := ptr++
        isToken := false
      else        
        ptr++

  'Goto the status line end (CR LF)
  isToken := false 
  repeat until NOT IsEndOfLine(byte[ptr])
    byte[ptr++] := 0

  'Mark the start of the header lines
  sectionTokenCnt[STATUS_LINE] := tokens
  
  'Get the query string count
  if(sectionTokenCnt[QUERYSTRING]) 
    sectionTokenCnt[QUERYSTRING] := tokens - sectionTokenCnt[QUERYSTRING] - 3
    
  headerSections[HEADER_LINES] := ptr
  tokenPtr[tokens++] := ptr


  'Process the the header lines untill we reach the message body
  t1 := FindBody(ptr, strsize(tokenPtr[tokens-1]) )
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
  
  'Skip the two end of line chars which mark the end of the header
  repeat until NOT IsEndOfLine(byte[ptr])
    byte[ptr++] := 0

  'Mark the start of the body
  headerSections[BODY] := ptr

  'Decode the url
  repeat t1 from 1 to sectionTokenCnt[STATUS_LINE]-2
    DecodeString(tokenPtr[t1])
  
  'Return if body does not contain data
  if(ptr == (buff + len))
    sectionTokenCnt[BODY] := sectionTokenCnt[HEADER_LINES] 
    return

  'Process the body 
  bodyPtr := ptr
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

  'Decode POST data
  if(strcomp(tokenPtr[0], string("POST")))
    repeat t1 from sectionTokenCnt[HEADER_LINES] to sectionTokenCnt[BODY]
      DecodeString(tokenPtr[t1])
      

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
  return lookdown(value & $FF: "=", "&")    
  
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