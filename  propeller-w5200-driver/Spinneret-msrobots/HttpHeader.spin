'':::::::[ HttpHeader ]:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
{{
''
''AUTHORS           Mike Gebhard / Michael Sommer
''COPYRIGHT:        Parallax Inc. - See LICENCE (MIT)
''LAST MODIFIED:    10/04/2013
''VERSION:          1.0
''LICENSE:          MIT (see end of file)
''
''
''DESCRIPTION:   
''                  The HttpHeader object
''
''MODIFICATIONS:
'' 8/31/2013        this version DOES NOT tokenize the Filename inside TokenizeHeader
''                  so '/' is allowed in Filename and in POST/GET parameters
''                  for RESTful Interfaces you can call TokenizeFilename after TokenizeHeader
''                  to provide url_parts as values
''                  So before calling TokenizeFilename
''                  - GetFileName will return the path and filename
''                  And after calling TokenizeFilename
''                  - GetFileName will just return the filename without path
''                  - GetUrlPart(index) will work as desired and will
''                    enumerate each part of the path & filename
''10/04/2013        added minimal spindoc comments
''                  Michael Sommer (MSrobots)
}}                                           
CON                                                     
''
''=======[ Global CONstants ... ]=========================================================
  
  CR    = $0D
  LF    = $0A
  
  TOKEN_PTR_LEN       = $FF
  HEADER_SECTIONS_LEN = 4
  FILE_EXTENSION_LEN  = 3

  #0, STATUS_LINE, HEADER_LINES, BODY, URL_PARTS

''     
''=======[ Global DATa ]==================================================================
DAT
  ext             long
                  byte  $0[3], $0               ' needs to be long alignt

  index           byte  "/index.htm", $0
  sectionTokenCnt byte  $0[HEADER_SECTIONS_LEN]
  tokens          byte  $0 
  null            long  $0
  headerSections  long  $0[HEADER_SECTIONS_LEN]
  tokenPtr        long  $0[TOKEN_PTR_LEN]
  ptr             long  $0
  isToken         long  $0
  t1              long  $0

''
''=======[ PUBlic Spin Methods]===========================================================
PUB Get(key) | i
  repeat i from 0 to sectionTokenCnt[STATUS_LINE]-1
    if(strcomp(key, tokenPtr[i]))
      return tokenPtr[i+1]
  return @null

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

PUB UrlContains(value) | i, j, adr, size
  ifnot sectionTokenCnt[URL_PARTS] == sectionTokenCnt[BODY]' Filename already tokenized
    repeat i from sectionTokenCnt[BODY] to sectionTokenCnt[URL_PARTS]
      if(strcomp(value, tokenPtr[i]))                   ' check URL_PARTS
        return true
        
  repeat i from 1 to sectionTokenCnt[STATUS_LINE]-3
    adr := tokenPtr[i]                                  ' get token
    size := strsize(t1) - strsize(value)                ' compare length
    if size=>0                                          ' if ok
      repeat j from 0 to size                           '   check all possible positions
        if(strcomp(value, adr + j))                     '   in token.
          return true
          
  return false

PUB GetUrlPart(value) 
  if(sectionTokenCnt[STATUS_LINE] == 3)                 ' why that?
    return string("/")                                  ' ??? MSrobots
    
  ifnot sectionTokenCnt[URL_PARTS] == sectionTokenCnt[BODY]' Filename already tokenized
    if value > (sectionTokenCnt[URL_PARTS] - sectionTokenCnt[BODY])
      return @null
    if value<1
      return tokenPtr[0] 
    return tokenPtr[sectionTokenCnt[BODY] + value-1]   
  else
    if((value >  sectionTokenCnt[STATUS_LINE]-3) OR (++value > sectionTokenCnt[STATUS_LINE]-3))
      return @null
      
    return EnumerateHeader(value)
     
PUB GetFileName
  if sectionTokenCnt[URL_PARTS] == sectionTokenCnt[BODY]' complete request Path & File
    if strsize(tokenPtr[1])>1
      return tokenPtr[1]                                ' without get-params (?&...)
    else
      return @index
  else                                                  ' Filename already tokenized
    return tokenPtr[sectionTokenCnt[URL_PARTS]-1]         ' last URL token ? one less?
{  
  repeat i from 1 to sectionTokenCnt[STATUS_LINE]-2
    t1 := tokenPtr[i]
    repeat j from 0 to strsize(t1)-1
      if(byte[t1][j] == ".")
        return tokenPtr[i]
  return @index
}
PUB GetFileNameExtension
  return @ext

PRI _GetFileNameExtension | j
  t1 := tokenPtr[1]  
  repeat j from strsize(t1)-6 to strsize(t1)-1
    if(byte[t1][j] == ".")
      return tokenPtr[1]+j+1
      
  return @index + strsize(@index)-FILE_EXTENSION_LEN 
{      
  repeat i from 1 to sectionTokenCnt[STATUS_LINE]-2
    t1 := tokenPtr[i]
    repeat j from 0 to strsize(t1)-1
      if(byte[t1][j] == ".")
        return tokenPtr[i]+j+1
  return @index + strsize(@index)-FILE_EXTENSION_LEN   
}
PUB Decode(value)
  DecodeString(value)
  return value

PUB GetTokens
  return tokens
  
PUB EnumerateHeader(idx)
  return tokenPtr[idx]

PUB TokenizeHeader(buff, len)
  ptr := buff
  tokens := 0
  isToken := false

  'Initialize pointer arrays
  'Mark the start of the status line
  tokenPtr[tokens++] := buff
  headerSections[STATUS_LINE] := buff
    
  'Parse the status line 
  repeat until IsEndOfLine(byte[ptr]) 
    if(IsStatusLineToken(byte[ptr]))
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

  'Return if body does not contain data                 
  if(ptr == (buff + len))                              
    sectionTokenCnt[URL_PARTS] := sectionTokenCnt[BODY] := sectionTokenCnt[HEADER_LINES] 
    return 0

  'Decode POST data
  if(strcomp(tokenPtr[0], string("POST")))
    result := ptr
    DecodeString(ptr)
                                                        ' just tokenize Body on POST
    'Tokenize the body
    tokenPtr[tokens++] := ptr++
    repeat until ptr > (buff + len)-1
      if(IsPostToken(byte[ptr]))    
        byte[ptr++] := 0
        if(IsPostToken(byte[ptr]))
          tokenPtr[tokens++] := ptr -1
        else
          isToken := true
      else
        if(isToken)
'          if(byte[ptr] == $20)
'            ptr++
          tokenPtr[tokens++] := ptr++
          isToken := false
        else        
          ptr++
          
    sectionTokenCnt[URL_PARTS] := sectionTokenCnt[BODY] := tokens
    'return 1
    
PUB TokenizeFilename 
  ifnot sectionTokenCnt[URL_PARTS] == sectionTokenCnt[BODY]' Filename already tokenized
    ptr := tokenPtr[1]
    
    if byte[ptr] == "/"                                 ' if /                          '
      ifnot byte[ptr+1] == 0                            ' but not just /
        ptr++                                           ' ignore /
    headerSections[URL_PARTS] := ptr
    tokenPtr[tokens++] := ptr
    ifnot byte[ptr]==0                                  ' if not done already
      repeat until byte[ptr]==0
        if byte[ptr] == "/"                             ' if / found next token
          byte[ptr] := 0
          tokenPtr[tokens++] := ptr+1 
        ptr++        
    
    sectionTokenCnt[URL_PARTS] := tokens
    

''
''=======[ PRIvate Spin Methods ... ]=====================================================
PRI FindBody(value, len)
  repeat len
    if(byte[value] == CR AND byte[value+1] == LF AND byte[value+2] == CR AND byte[value+3] == LF)
      return value
    if(byte[value] == LF  AND byte[value+1] == LF)
      return value
    value++ 
  return null
  
PRI IsStatusLineToken(value)
  'return lookdown(value & $FF: "/", "?", "=", "+", " ", "&")
  return lookdown(value & $FF:  "?", "=", "+", " ", "&")
  
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


''
''=======[ PUB Debug Stuff ... ]==========================================================
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

''
''=======[ Documentation ]================================================================
CON                                                  
{{{
This .spin file supports PhiPi's great Spin Code Documenter found at
http://www.phipi.com/spin2html/

You can at any time create a .htm Documentation out of the .spin source.

If you change the .spin file you can (re)create the .htm file by uploading your .spin file
to http://www.phipi.com/spin2html/ and then saving the the created .htm page. 
}}

''
''=======[ MIT License ]==================================================================
CON                                                 
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