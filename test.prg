PROCEDURE test
	SET PROCEDURE TO 'winsocket', 'hex2ascii', 'base2base'
	SET CLASSLIB TO 'mikrotik_sync', 'md5'
	
	MTikAPI   = CREATEOBJECT('mikrotikapi')
	
	MTikAPI.MTikIP   = '192.168.110.114'
	MTikAPI.MTikPort = 8728

	IF !MTikAPI.connectMTik()
		****	write some log info
		RETURN .F.
	ENDIF 

	IF !MTikAPI.logInMTik()
		****	write some log info
		RETURN .F.
	ENDIF 

	MTikAPI.writeMTik('/interface/print', .T.)
	MTikAPI.readMTik()
	MTikAPI.parseResponse()

	FOR i = 1 TO ALEN(MTikAPI.MTikResponseParsedArray, 1)
		MESSAGEBOX(MTikAPI.MTikResponseParsedArray[i, 1] + '  ' + MTikAPI.MTikResponseParsedArray[i, 2])
	ENDFOR 
ENDPROC 