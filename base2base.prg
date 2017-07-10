FUNCTION Base2Base  
 *  Base2Base( <cInString>, <nInBase>, <nOutBase> ) --> cNewBaseValue  
 *	Converts number in string representation from one notation 
 *  to another in notations range from 2 to 201

  lPARAMETERS cInString, nInBase, nOutBase  
  T_CHAR		= "C"  
  T_NUM			= "N"  
  T_LOGIC		= "L"  
  T_DATE		= "D"  
  T_TIME		= "T"  
  T_MONEY		= "Y"  
  T_NULL		= "X"  
  T_OBJ			= "O"  
  T_UNKNOWN		= "U"  
  T_GENERAL		= "G"  

 *  Note, that to convert from HEX notation you need to use ONLY upper case letters ABCDEF
  
  LDS_B2B_DIG 	= '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
  
  LOCAL cNewBaseValue, ln_i, ln_len, DecPos, IntValue, FracValue  
  LOCAL FracProduct, FracCounter, IntProdStr, FracOutStr, IntOutString  
  LOCAL IntStr, FracString, FracLimit, Remainder, Quotient, NegSign 
  LOCAL digits_num, tRemainder
   
  cNewBaseValue = ""  
  FracValue = 0.00000000000000000000  
  IntValue = 0  
  
 *  Parameters check    
  IF VARTYPE(cInString) == T_NUM
  	tRemainder = cInString
  	digits_num = 0
  	
  	DO WHILE tRemainder > 0
  		tRemainder = INT(tRemainder / 10)
  		digits_num = digits_num + 1 
  	ENDDO 	
  	
  	cInString = TRANSFORM(STR(cInString, digits_num), '@T')
  ENDIF 
   
  IF VARTYPE(cInString) == T_CHAR AND ALLTRIM(cInString) == ''
  	RETURN ''  		  		
  ENDIF 
  	
  IF VARTYPE(cInString) != T_CHAR
  	cInString = TRANSFORM(cInString)
  	cInString = ALLTRIM(cInString)
  ENDIF 
  
  IF cInString == '0' 
  	RETURN '0'
  ENDIF   
  
  IF EMPTY(cInString) OR LEN(cInString ) > 20  
  	cNewBaseValue = .F.  
  ELSE  
  	STORE ALLTRIM(cInString) TO cInString  
  	IF EMPTY(nInBase)  
  		STORE 10 TO nInBase  
  	ENDIF  
  	IF EMPTY(nOutBase)  
  		STORE 10 TO nOutBase	  
  	endif  
  	IF varTYPE(nInBase) != T_NUM .OR. varTYPE(nOutBase) != T_NUM  
  		cNewBaseValue=.F.  
  	ELSE  
		*  Out of notation range check  		
  		IF nInBase > 62 .OR. nOutBase > 62 .OR. nInBase < 2 .OR. nOutBase < 2  
  			cNewBaseValue = .F.  
  		ELSE  
			*  Check for the correspondence of each digit of the original number to the notation
  			ln_i = 1  
  			STORE LEN(cInString) TO ln_len  
  			DO WHILE ln_i < ln_len .AND. varTYPE(cNewBaseValue) != T_LOGIC  
  				ln_i = ln_i + 1  
  				IF .NOT. UPPER(SUBSTR(cInString , ln_i , 1)) $ UPPER((SUBSTR(LDS_B2B_DIG, 1, nInBase) + "."))
  					cNewBaseValue = .F.  
  				ENDIF  
  			ENDDO  
  		ENDIF  
  	ENDIF  
  ENDIF  
  
  IF VARTYPE(cNewBaseValue) != T_LOGIC    
	*  Check if the converted number is negative
  	NegSign = IIF(Left(cInString, 1) == "-", "-", "")  
  	IF .NOT. EMPTY(NegSign)  
  		cInString = SUBSTR(ALLTRIM(SUBSTR(cInString, 2)), 2)  
  	ENDIF  

	*  Decimal point defifnition
  	DecPos = AT(".", cInString)  
  	IntStr = IIF(DecPos>1, SUBSTR(cInString, 1, DecPos - 1 ), IIF(DecPos = 1, "0", cInString))  
  	FracString = IIF(DecPos>0, SUBSTR(cInString, DecPos + 1 ), "0")  

	*  Conversion of the int part of the string to digital in decimal notation
  	STORE LEN(IntStr) TO ln_len  
  	FOR ln_i = ln_len TO 1 STEP  - 1  
  		IntValue = IntValue + (AT(SUBSTR(IntStr, ln_i, 1), LDS_B2B_DIG) - 1) * (nInBase ** (ln_len - ln_i))  
  	NEXT  

	*  Conversion of the fractional part of the string to digital in decimal notation  	
      STORE LEN(FracString) TO ln_len  
  	FOR ln_i = 1 TO ln_len  
  		FracValue = FracValue + (AT(SUBSTR(FracString, ln_i, 1), LDS_B2B_DIG) - 1) * (nInBase ** ( - ln_i))  
    NEXT  

	*  Calculation of the int part of the input string
  	Quotient = IntValue  
  	IntOutString = ""  
  	DO WHILE Quotient != 0  
  		Remainder = Quotient % nOutBase  
  		Quotient = INT(Quotient / nOutBase)  
  		IntOutString = SUBSTR(LDS_B2B_DIG, Remainder + 1, 1) + IntOutString  
  	ENDDO  
  	
  	IF EMPTY(IntOutstring)  
  		STORE "0" TO IntOutString  
  	endif  
  	
	*  Calculation of the fractional part of the input string
  	FracLimit = 20 - DecPos  
  	FracProduct = FracValue  
  	FracCounter = 1  
  	FracOutStr = ""  
  	DO WHILE FracCounter < FracLimit .AND. FracProduct < 0.00000000000001  
  		FracCounter = FracCounter + 1  
        	IntProdStr = FracProduct * nOutBase  
  		FracOutStr = FracOutStr + SUBSTR(LDS_B2B_DIG, INT(IntProdStr) + 1, 1)  
  		FracProduct = IntProdStr - INT(IntProdStr)  
  	ENDDO  
  ENDIF  
  
  *  Formation of the returning string
  IF varTYPE (cNewBaseValue) != T_LOGIC	
  	cNewBaseValue = IIF(DecPos > 0, NegSign + IntOutString + "." + FracOutStr, IntOutString)  
  ENDIF  
RETURN cNewBaseValue