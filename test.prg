PROCEDURE test
	SET PROCEDURE TO 'winsocket', 'hex2ascii', 'base2base'
	SET CLASSLIB TO 'mikrotik_sync', 'md5'
	
	MTikAPI   = CREATEOBJECT('mikrotikapi')
	
	MTikAPI.MTikIP   = '192.168.88.1'
	MTikAPI.MTikPort = 8728
SET STEP ON 
	IF !MTikAPI.connectMTik()
		****	write some log info
		RETURN .F.
	ENDIF 
	
	MTikAPI.MTikLogin = 'admin'
	MTikAPI.MTikPassword = 'admin'
	
	IF !MTikAPI.logInMTik()
		****	write some log info
		RETURN .F.
	ENDIF 
	
	CREATE CURSOR tcurss (param_name C(100), param_val C(100))	
	
	****	simple example

	MTikAPI.composeCommand('/interface/print')
	MTikAPI.parseResponse()

	FOR i = 1 TO ALEN(MTikAPI.MTikResponseParsedArray, 1)
		INSERT INTO tcurss (param_name, param_val) ;
					VALUES (MTikAPI.MTikResponseParsedArray[i, 1], MTikAPI.MTikResponseParsedArray[i, 2])
	ENDFOR 
	
	SELECT tcurss	
	BROWSE NORMAL 
	APPEND BLANK
	APPEND BLANK
	APPEND BLANK
	APPEND BLANK

*!*		MTikAPI.composeCommand('/queue/simple/print')
*!*		MTikAPI.parseResponse()

*!*		FOR i = 1 TO ALEN(MTikAPI.MTikResponseParsedArray, 1)
*!*			INSERT INTO tcurss (param_name, param_val) ;
*!*						VALUES (MTikAPI.MTikResponseParsedArray[i, 1], MTikAPI.MTikResponseParsedArray[i, 2])
*!*		ENDFOR 
*!*		
*!*		SELECT tcurss	
*!*		BROWSE NORMAL 
*!*		APPEND BLANK
*!*		APPEND BLANK
*!*		APPEND BLANK
*!*		APPEND BLANK
*!*		
*!*		
	****	now trying to make some queries to get particular records	
	DIMENSION props [2,2]
	props[1,1] = '.proplist'
	props[1,2] = '.id'
	props[2,1] = '?address'			&& you can put any attribute here, like 'server' or 'comment' - any,
									&& existing in '/ip dhcp-server lease' (like name of a colunm in Winbox)									
	props[2,2] = '10.100.0.120' 		&& put any existing IP here (or whatever you're looking for)

	MTikResult = .F.				
	MTikResult = MTikAPI.composeCommand('/ip/dhcp-server/lease/print', @props)

	IF MTikResult	&& if anything found
		MTikAPI.parseResponse()

		FOR i = 1 TO ALEN(MTikAPI.MTikResponseParsedArray, 1)
			INSERT INTO tcurss (param_name, param_val) ;
						VALUES (MTikAPI.MTikResponseParsedArray[i, 1], MTikAPI.MTikResponseParsedArray[i, 2])
		ENDFOR 
		
		SELECT tcurss	
		BROWSE NORMAL 
		APPEND BLANK
		APPEND BLANK

		****	now, let's try to modify the record we've found 
		DIMENSION props [2,2]
		props[1,1] = '.id'
		props[1,2] = MTikAPI.MTikResponseParsedArray[1,2]	&& the Mikrotik ID of the record we've found
		props[2,1] = 'comment'
		props[2,2] = 'lalalalala' 
		
*		MTikResult = MTikAPI.composeCommand('/ip/dhcp-server/lease/set', @props)
	ENDIF 

	DIMENSION props [4,2]
	props[1,1] = '.proplist'
	props[1,2] = '.id'
	props[2,1] = '?target'			&& you can put any attribute here, like 'name' or 'comment' - any,
									&& existing in '/queue simple' (like name of a colunm in Winbox)
	props[2,2] = '"10.24.4.1/32"' 	&& put any existing IP here (or whatever you're looking for)
	props[3,1] = '?disabled'
	props[3,2] = 'no'
	props[4,1] = '?#'
	props[4,2] = '&'
SET STEP ON 	
	MTikResult = .F.				
	MTikResult = MTikAPI.composeCommand('/queue/simple/print', @props)
	
	IF MTikResult	&& if anything found
		MTikAPI.parseResponse()
		
		FOR i = 1 TO ALEN(MTikAPI.MTikResponseParsedArray, 1)
			INSERT INTO tcurss (param_name, param_val) ;
						VALUES (MTikAPI.MTikResponseParsedArray[i, 1], MTikAPI.MTikResponseParsedArray[i, 2])
		ENDFOR 
		
		SELECT tcurss
		BROWSE NORMAL
		APPEND BLANK
		APPEND BLANK

		****	now, let's try to modify the record we've found 
		DIMENSION props [2,2]
		props[1,1] = '.id'
		props[1,2] = MTikAPI.MTikResponseParsedArray[1,2]	&& the Mikrotik ID of the record we've found
		props[2,1] = 'comment'
		props[2,2] = 'lalalalala'
		
		MTikResult = MTikAPI.composeCommand('/queue/simple/set', @props)
	ENDIF 	
ENDPROC 