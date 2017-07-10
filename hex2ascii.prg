FUNCTION hex2ascii
PARAMETERS in_val
LOCAL uncrypt_str, extracted_chars, i
PRIVATE uncrypt_str, extracted_chars, i

	STORE '' TO uncrypt_str, extracted_chars
	
	IF EMPTY(in_val)
		RETURN uncrypt_str
	ENDIF 
	
	IF VARTYPE(in_val) != 'C' 
		in_val = TRANSFORM(in_val)	
	ENDIF 

	FOR i = 1 TO LEN(in_val) STEP 2
		extracted_chars = SUBSTR(in_val, i, 2)

		IF extracted_chars != '' 
			uncrypt_str = uncrypt_str + CHR(VAL(base2base(extracted_chars, 16, 10)))
		ENDIF 

	ENDFOR 

RETURN uncrypt_str 