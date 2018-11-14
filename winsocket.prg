*************************************************************************************************
**************************************************
*-- Class:        CWinSocket
*-- ParentClass:  custom
*-- BaseClass:    custom
*
DEFINE CLASS CWinSocket As Custom

#DEFINE AF_INET       2
#DEFINE SOCK_STREAM   1
#DEFINE IPPROTO_TCP   6
#DEFINE SOCKET_ERROR -1
#DEFINE FD_READ       1

#DEFINE CRLF          chr(13)+chr(10)
  
 host     = ""
 IP       = ""
 Port     = 80
 hSocket  = 0
 cIn      = ""
 WaitForRead = 0
 Time_out	=	1000
 cString = ""

FUNCTION Init()
  THIS.decl
  IF WSAStartup(0x202, Repli(Chr(0),512)) <> 0
    * unable to initialize Winsock on this computer
	RETURN .F.
  ELSE
	=rand(-1)
	RETURN .T.
  ENDIF
ENDFUNC

PROCEDURE Destroy
  = WSACleanup()
ENDPROC
  
PROCEDURE HostAssign( vNewVal )
  THIS.IP = iif(empty(vNewVal),"",THIS.GetIP(vNewVal))
  THIS.Host = iif(empty(THIS.IP),"",vNewVal)
ENDPROC

PROTECTED FUNCTION GetIP( pcHost )
  #DEFINE HOSTENT_SIZE 16
  LOCAL nStruct, nSize, cBuffer, nAddr, cIP
  nStruct = gethostbyname(pcHost)
  IF nStruct = 0
	RETURN ""
  ENDIF
  cBuffer = Repli(Chr(0), HOSTENT_SIZE)
  cIP = Repli(Chr(0), 4)
  = CopyMemory(@cBuffer, nStruct, HOSTENT_SIZE)
  = CopyMemory(@cIP, THIS.buf2dword(SUBS(cBuffer,13,4)),4)
  = CopyMemory(@cIP, THIS.buf2dword(cIP),4)
  RETURN inet_ntoa(THIS.buf2dword(cIP))
ENDFUNC

FUNCTION Connect
  LOCAL cBuffer, cPort, cHost, lResult
  THIS.hSocket = socket(AF_INET, SOCK_STREAM,0) 		&&	IPPROTO_TCP)
  IF THIS.hSocket = SOCKET_ERROR
	RETURN .F.
  ENDIF
    
  cPort = THIS.num2word(htons(THIS.Port))
  nHost = inet_addr(THIS.IP)
  cHost = THIS.num2dword(nHost)
  cBuffer = THIS.num2word(AF_INET) + cPort + cHost + Repli(Chr(0),8)
  lResult = (ws_connect(THIS.hSocket, @cBuffer, Len(cBuffer))=0)
  RETURN lResult
ENDFUNC

FUNCTION Disconnect
  if THIS.hSocket<>SOCKET_ERROR
	= closesocket(THIS.hSocket)
  endif
  THIS.hSocket = SOCKET_ERROR
ENDFUNC

* GET *************************************************************
* pcUrl - string like "HTTP://www.test.com/test.php"
* cHeaders - strings lika '<Name>: <value>'+chr(13)+chr(10)
*
* If cHeaders assgined - assigned headers are send

FUNCTION Get(pcUrl,cHeaders)
  LOCAL lResult
  IF THIS.Connect()
	THIS.snd('GET '+pcURL+' http/1.0'+crlf)
	if	!empty(cHeaders)
		THIS.snd(cHeaders)
	endif
	THIS.snd(crlf,.t.) && End of headers
	lResult = .T.
  ELSE
	lResult = .F.
  ENDIF
  THIS.Disconnect()
ENDFUNC

* POST **************************************************************
* pcUrl - string like "HTTP://www.test.com/test.php"
* cHeaders - strings lika '<Name>: <value>'+chr(13)+chr(10)
* cStr - string like ['<VarName.>=<Var value.>'+'&']+[<VarName. for pcData>]+chr(13)+chr(10)
* pcData - character string with data to pass to the server
* 
* If cHeaders assgined - headers are send before the data.
* If cStr is not assigned - pcData is send and an empty string 
* 	and it supposed pcData contains cStr and datablock already 

FUNCTION Post(pcUrl, cHeaders, cStr, pcData)
  LOCAL lResult, lcB, lcStr, lnCount, lnCnt, lcName, lcValue, lT1, lT2
  this.cIn=""
  IF THIS.Connect()
	lcB="pst"+alltrim(str(1000000*rand(),6))
	THIS.snd('POST '+pcURL+' http/1.0'+crlf)
	if	!empty(cHeaders)
		THIS.snd(cHeaders)
	endif
	if	!empty(cStr)
		THIS.snd('Content-Type: multipart/form-data; boundary='+lcB+crlf)
		lcStr=""
		lnCount=occurs("&",cStr)
		if	lnCount#0
			for	lnCnt=1	to	lnCount	step	1
				lT1=AT("=",cStr,1)-1
				lT2=AT("&",cStr,1)-1
				lcName=substr(cStr,1,lT1)
				lcValue=substr(cStr,lT1+2,lT2-lT1-1)
				lcStr=lcStr+"--"+lcB+crlf+'Content-Disposition: form-data; name="'+lcName+'"'+crlf+crlf+lcValue+crlf
				cStr=substr(cStr,lT2+2,len(cStr)-lT2+1)
			endfor
		endif
		lT1=AT("=",cStr,1)-1
		if	lT1>0
			lcStr=lcStr+"--"+lcB+crlf+'Content-Disposition: form-data; name="'+substr(cStr,1,lT1)+'"'+crlf+crlf
			lcStr=lcStr+alltrim(substr(cStr,lT1+2,len(cStr)-lT1+1))+crlf+'--'+lcB+'--'+crlf
		else
			lcStr=lcStr+"--"+lcB+crlf+'Content-Disposition: form-data; name="'+cStr+'"'+crlf+crlf
			lcStr=lcStr+pcData+crlf+'--'+lcB+'--'+crlf
		endif
		THIS.snd('Content-Length: '+alltrim(str(len(lcStr)))+crlf)
		THIS.snd(crlf) && End of headers
		THIS.snd(lcStr,.t.) && get a response, too.
	else
		if	!empty(pcData)
			THIS.snd(crlf)			&& End of headers
			THIS.snd(pcData,.t.)	&& get a response, too.
		else
			THIS.snd(crlf,.t.)		&& get a response, too.
		endif
	endif
	lResult = .T.
  ELSE
	lResult = .F.
  ENDIF
  THIS.Disconnect()
  This.cString=lcStr
ENDFUNC

  FUNCTION sendSocket(cData, lResponse)
    LOCAL cBuffer, nResult, cResponse
    cBuffer = cData && + CrLf
    nResult = send(THIS.hSocket, @cBuffer, Len(cBuffer), 0)
    IF nResult = SOCKET_ERROR
        RETURN .F.
    ENDIF
    IF Not lResponse
        RETURN .T.
    ENDIF

    LOCAL hEventRead, nWait, cRead
    DO WHILE .T.
        * creating event, linking it to the socket and wait
        hEventRead = WSACreateEvent()
        = WSAEventSelect(THIS.hSocket, hEventRead, FD_READ)

        * 1000 milliseconds can be not enough
        THIS.WaitForRead = WSAWaitForMultipleEvents(1, @hEventRead, 0, THIS.Time_out, 0)
        = WSACloseEvent(hEventRead)

        IF THIS.WaitForRead <> 0 && error or timeout
            EXIT
        ENDIF
        
        * reading data from connected socket
        THIS.cIn = THIS.cIn+THIS.Rd()
    ENDDO
  RETURN .T.
  ENDFUNC

  FUNCTION readSocket
  #DEFINE READ_SIZE 65536
    LOCAL cRecv, nRecv, nFlags
    cRecv = Repli(Chr(0), READ_SIZE)
    nFlags = 0
    nRecv = recv(THIS.hSocket, @cRecv, READ_SIZE, nFlags)
    RETURN Iif(nRecv<=0, "", LEFT(cRecv, nRecv))
  ENDFUNC

  PROCEDURE decl
    DECLARE INTEGER gethostbyname IN ws2_32 STRING host
    DECLARE STRING inet_ntoa IN ws2_32 INTEGER in_addr
    DECLARE INTEGER socket IN ws2_32 INTEGER af, INTEGER tp, INTEGER pt
    DECLARE INTEGER closesocket IN ws2_32 INTEGER s
    DECLARE INTEGER WSACreateEvent IN ws2_32
    DECLARE INTEGER WSACloseEvent IN ws2_32 INTEGER hEvent
    DECLARE GetSystemTime IN kernel32 STRING @lpSystemTime
    DECLARE INTEGER inet_addr IN ws2_32 STRING cp
    DECLARE INTEGER htons IN ws2_32 INTEGER hostshort
    DECLARE INTEGER WSAStartup IN ws2_32 INTEGER wVerRq, STRING lpWSAData
    DECLARE INTEGER WSACleanup IN ws2_32

    DECLARE INTEGER connect IN ws2_32 AS ws_connect ;
        INTEGER s, STRING @sname, INTEGER namelen

    DECLARE INTEGER send IN ws2_32;
        INTEGER s, STRING @buf, INTEGER buflen, INTEGER flags

    DECLARE INTEGER recv IN ws2_32;
        INTEGER s, STRING @buf, INTEGER buflen, INTEGER flags

    DECLARE INTEGER WSAEventSelect IN ws2_32;
        INTEGER s, INTEGER hEventObject, INTEGER lNetworkEvents

    DECLARE INTEGER WSAWaitForMultipleEvents IN ws2_32;
        INTEGER cEvents, INTEGER @lphEvents, INTEGER fWaitAll,;
        INTEGER dwTimeout, INTEGER fAlertable

    DECLARE RtlMoveMemory IN kernel32 As CopyMemory;
        STRING @Dest, INTEGER Src, INTEGER nLength
  ENDPROC

  FUNCTION buf2dword(lcBuffer)
    RETURN Asc(SUBSTR(lcBuffer, 1,1)) + ;
        BitLShift(Asc(SUBSTR(lcBuffer, 2,1)), 8) +;
        BitLShift(Asc(SUBSTR(lcBuffer, 3,1)), 16) +;
        BitLShift(Asc(SUBSTR(lcBuffer, 4,1)), 24)
  ENDFUNC
  
  FUNCTION num2dword(lnValue)
  #DEFINE m0 256
  #DEFINE m1 65536
  #DEFINE m2 16777216
      IF lnValue < 0
          lnValue = 0x100000000 + lnValue
      ENDIF
      LOCAL b0, b1, b2, b3
      b3 = Int(lnValue/m2)
      b2 = Int((lnValue - b3*m2)/m1)
      b1 = Int((lnValue - b3*m2 - b2*m1)/m0)
      b0 = Mod(lnValue, m0)
  RETURN Chr(b0)+Chr(b1)+Chr(b2)+Chr(b3)
  ENDFUNC
  
  FUNCTION num2word(lnValue)
    RETURN Chr(MOD(m.lnValue,256)) + CHR(INT(m.lnValue/256))
  ENDFUNC

ENDDEFINE
*
*-- EndDefine: CWinSocket
**************************************************
