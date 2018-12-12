os_string_length:
	pusha

	mov bx, ax			;Mueve la ubicación de la cadena a Bx

	mov cx, 0			; Mostrador

.more:
	cmp byte [bx], 0		; Cero(Finaliza a cadena) todavia?
	je .done
	inc bx				; Si no, sigue agregando
	inc cx
	jmp .more


.done:
	mov word [.tmp_counter], cx	; Almacenar el conteo antes de restaurr otros registros
	popa

	mov ax, [.tmp_counter]		; Ponga la cuenta nuevamente en AX antes de regresar
	ret


	.tmp_counter	dw 0


; ------------------------------------------------------------------
; os_string_reverse -- Invierte los caracteres en una cadena
; IN: SI = Ubiccion de la cadena

os_string_reverse:
	pusha

	cmp byte [si], 0		; No intentes invertir la cadena vacia
	je .end

	mov ax, si
	call os_string_length

	mov di, si
	add di, ax
	dec di				; DI ahora apunta a la ultima char en cadena

.loop:
	mov byte al, [si]		; Intercambiar bytes
	mov byte bl, [di]

	mov byte [si], bl
	mov byte [di], al

	inc si				; Mover hacia el centro de la 							cadena
	dec di

	cmp di, si			; Ambos llegaron al centro?
	ja .loop

.end:
	popa
	ret


; ------------------------------------------------------------------
; os_find_char_in_string -- Encuentra la ubicacion del 							caracter en una cadena
; IN: SI = ubicacion de al cadena, AL = Caracter para encontrar
; OUT: AX = ubicacion en cadena, or 0 si char no esta presente

os_find_char_in_string:
	pusha

	mov cx, 1			; Contador --comenzar a la primera 						char(contamos 
					; de 1 en caracteres aqui, para 							quepodemos
					; devolver 0 si no se encuentra la 						fuente char )

.more:
	cmp byte [si], al
	je .done
	cmp byte [si], 0
	je .notfound
	inc si
	inc cx
	jmp .more

.done:
	mov [.tmp], cx
	popa
	mov ax, [.tmp]
	ret

.notfound:
	popa
	mov ax, 0
	ret


	.tmp	dw 0


; ------------------------------------------------------------------
; os_string_charchange -- Cambiar instancias de caracteres en 					una cadena
; IN: SI = cadena, AL = char para encontrar, BL = char para reemplazar con

os_string_charchange:
	pusha

	mov cl, al

.loop:
	mov byte al, [si]
	cmp al, 0
	je .finish
	cmp al, cl
	jne .nochange

	mov byte [si], bl

.nochange:
	inc si
	jmp .loop

.finish:
	popa
	ret


; ------------------------------------------------------------------
; os_string_uppercase -- Convierte una cadena terminada en cero a mayusculas
; IN/OUT: AX = ubicacion de la cadena

os_string_uppercase:
	pusha

	mov si, ax			; Usa SI para acceder a la cadena 

.more:
	cmp byte [si], 0		; Cero-terminacion de la cadena?
	je .done			; Si es asi, deja

	cmp byte [si], 'a'		; En el rango de minusculas de la A a Z?
	jb .noatoz
	cmp byte [si], 'z'
	ja .noatoz

	sub byte [si], 20h		; Si es asi, convierta la entrada char a mayusculas

	inc si
	jmp .more

.noatoz:
	inc si
	jmp .more

.done:
	popa
	ret


; ------------------------------------------------------------------
; os_string_lowercase -- Convierte una cadena terminada en cero en minusculas
; IN/OUT: AX = ubicaicon de la cadena

os_string_lowercase:
	pusha

	mov si, ax			; Usa SI para acceder a la cadena

.more:
	cmp byte [si], 0		; Cero-terminacion de la cadena?
	je .done			; Si es asi, sale

	cmp byte [si], 'A'		;En el caso de mayusculas A a Z?
	jb .noatoz
	cmp byte [si], 'Z'
	ja .noatoz

	add byte [si], 20h		;Si es asi, convierte el char de entrada a minusculas

	inc si
	jmp .more

.noatoz:
	inc si
	jmp .more

.done:
	popa
	ret


; ------------------------------------------------------------------
; os_string_copy -- Copia una cadena en otra
; IN/OUT: SI = fuente, DI = destino (el programador asegura suficiente espacio)

os_string_copy:
	pusha

.more:
	mov al, [si]			; Transferir contenidos (al menos un terminador de byte)
	mov [di], al
	inc si
	inc di
	cmp byte al, 0			;Si la cadena fuente esta vacia, salga 
	jne .more

.done:
	popa
	ret


; ------------------------------------------------------------------
; os_string_truncate -- Cortar la cadena a un numero especifico de caracteres
; IN: SI = ubicacion de la cadena, AX = numeros de caracteres
; OUT: cadena modificada, registros conservados

os_string_truncate:
	pusha

	add si, ax
	mov byte [si], 0

	popa
	ret


; ------------------------------------------------------------------
; os_string_join --Unir dos cadenas en una tercera cadena
; IN/OUT: AX =cadena uno, BX =cadena dos, CX =cadena de destino

os_string_join:
	pusha

	mov si, ax			; Ponga la primera cadena CX
	mov di, cx
	call os_string_copy

	call os_string_length		;Obtener la longitud de la 								primera cadena

	add cx, ax			;Posicion al final de la primera 						cadena

	mov si, bx			;Añade una segunda cadena
	mov di, cx
	call os_string_copy

	popa
	ret


; ------------------------------------------------------------------
; os_string_chomp -- Pone los espacios iniciales  finales de una cadena
; IN: AX = Ubicacion de la cadena

os_string_chomp:
	pusha

	mov dx, ax			;Guarda ubicacion de cadena

	mov di, ax			; Poner ubicacion en DI
	mov cx, 0			; Contador de espacio

.keepcounting:				;Consigue el numero de espcios 							iniciales en BX
	cmp byte [di], ' '
	jne .counted
	inc cx
	inc di
	jmp .keepcounting

.counted:
	cmp cx, 0			; No hay espacios punteros?
	je .finished_copy

	mov si, di			; Direccion del primer personaje no 						espacial
	mov di, dx			; DI =Inicio de la cadena original

.keep_copying:
	mov al, [si]			; Copia SI en DI
	mov [di], al			; Incluyendo terminador
	cmp al, 0
	je .finished_copy
	inc si
	inc di
	jmp .keep_copying

.finished_copy:
	mov ax, dx			; AX = inicio de la cadena original

	call os_string_length
	cmp ax, 0			;Si esta vacio o todo esta en 							blanco, listo, devuleve 'null'
	je .done

	mov si, dx
	add si, ax			;Mover al final de la cadena

.more:
	dec si
	cmp byte [si], ' '
	jne .done
	mov byte [si], 0		;Rellene los espacios finales con 						0s
	jmp .more			;(El primero 0 sera el terminador 						de cadena)

.done:
	popa
	ret


; ------------------------------------------------------------------
; os_string_strip --elimina el caracter especificado de una cadena(max 255 caracteres)
; IN: SI =ubicacion de la cadena, AL =caracter a eliminar

os_string_strip:
	pusha

	mov di, si

	mov bl, al			;Copie el char en BL ya que LODSB y 						STOSB usan AL
.nextchar:
	lodsb
	stosb
	cmp al, 0			;Compruebe si llegamos al final de 						la cadena
	je .finish			; Si es asi, rescatar
	cmp al, bl			;Comprueba si el personaje que leemos es el personaje interesante
	jne .nextchar			;Si no, salta al siguiente 								caracter

.skip:					;Si es asi,la caida hasta aqui
	dec di				;Disminuimos DI asi que 						sobreescribimos en el proximo paso
	jmp .nextchar

.finish:
	popa
	ret

; ------------------------------------------------------------------
; os_string_compare --ver si dos cadenas coinciden
; IN: SI =cadena uno, DI = cadena dos
; OUT: agarra a si mismo, limpia si es diferente

os_string_compare:
	pusha

.more:
	mov al, [si]			;Recuperar el contenido de la 							cadena
	mov bl, [di]

	cmp al, bl			; Comparar personajes en la 							ubicación actual
	jne .not_same

	cmp al, 0			; ¿Fin de la primera cuerda? También debe ser el final del segundo.
	je .terminated

	inc si
	inc di
	jmp .more


.not_same:				;Si las longitudes son desiguales 					con el mismo principio, el byte
	popa				;la comparación falla en el 						terminador de cadena más corto
	clc				; Borrar bandera de acarreo
	ret


.terminated:				;Ambas cadenas terminaron en 							la misma posición
	popa
	stc				; Establecer bandera de acarreo
	ret


; ------------------------------------------------------------------
; os_string_strincmp -- ver si dos cadenas coinciden para establecer el número de caracteres
; IN: SI = cadena uno, DI = cadena dos, CL = caracteres a verificar
; OUT: carry set si mismo, claro si diferente
os_string_strincmp:
	pusha

.more:
	mov al, [si]			; Recuperar el contenido de la 							cadena
	mov bl, [di]

	cmp al, bl			; Comparar personajes en la 						ubicación actual
	jne .not_same

	cmp al, 0			;¿Fin de la primera cuerda? También 					debe ser el final del segundo.
	je .terminated

	inc si
	inc di

	dec cl				;Si hemos durado a través de 					nuestro recuento de caracteres
	cmp cl, 0			; Entonces los bits de la cadena 					coinciden!
	je .terminated

	jmp .more


.not_same:				;Si las longitudes son desiguales 					con el mismo principio, el byte
	popa				;la comparación falla en el 						terminador de cadena más corto
	clc				; Borrar bandera de acarreo
	ret


.terminated:				; Ambas cadenas terminaron en 						la misma posición
	popa
	stc				; Establecer bandera de acarreo
	ret


; ------------------------------------------------------------------
; os_string_parse - Toma la cadena (por ejemplo, "ejecuta foo bar baz") y regresa
; punteros a cadenas terminadas en cero (por ejemplo, AX = "run", BX = "foo" etc.)
; IN: SI = cadena; OUT: AX, BX, CX, DX = cadenas individuales
os_string_parse:
	push si

	mov ax, si			; AX = comienzo de la primera 							cadena

	mov bx, 0			;  Por defecto, otras cadenas 						comienzan vacías
	mov cx, 0
	mov dx, 0

	push ax				; Guardar para recuperar al 							final

.loop1:
	lodsb				; Obtener un byte
	cmp al, 0			; Fin de la cuerda?
	je .finish
	cmp al, ' '			; Un espacio?
	jne .loop1
	dec si
	mov byte [si], 0		;Si es asi,termina en cero este bit 						de la cadena

	inc si				;Tiende inicio de la siguiente 							cadena en BX
	mov bx, si

.loop2:					; Repita para CX y DX...
	lodsb
	cmp al, 0
	je .finish
	cmp al, ' '
	jne .loop2
	dec si
	mov byte [si], 0

	inc si
	mov cx, si

.loop3:
	lodsb
	cmp al, 0
	je .finish
	cmp al, ' '
	jne .loop3
	dec si
	mov byte [si], 0

	inc si
	mov dx, si

.finish:
	pop ax

	pop si
	ret


; ------------------------------------------------------------------
; os_string_to_int - Convierte una cadena decimal a un valor entero
; EN: SI = ubicación de la cadena (máx. 5 caracteres, hasta '65536')
; FUERA: AX = número
os_string_to_int:
	pusha

	mov ax, si			; Primero, consigue la longitud de 					la cadena llamada os_string_length

	add si, ax			;Trabaja desde el char la cadena
	dec si

	mov cx, ax			; Usa la longitud de la cadena como 						contador

	mov bx, 0			; BX sera el numero final
	mov ax, 0


; A medida que nos movemos hacia la izquierda en la cadena, cada carácter es un múltiplo más grande. los
; el carácter que se encuentra más a la derecha es un múltiplo de 1, luego el siguiente
; izquierda) un múltiplo de 10, luego 100, luego 1,000, y la final (y
; el carácter de la izquierda) en un número de cinco caracteres sería un múltiplo de 10,000
	mov word [.multiplier], 1	; Empieza con multiplos de 1

.loop:
	mov ax, 0
	mov byte al, [si]		; Obtener caracter
	sub al, 48			; Convertir de ASCII a numero real

	mul word [.multiplier]		;Multiplica por nuestro multiplicador

	add bx, ax			; Añadelo a  BX

	push ax				; Multiplica nuestro 					multiplicador por 10 para la próxima charla
	mov word ax, [.multiplier]
	mov dx, 10
	mul dx
	mov word [.multiplier], ax
	pop ax

	dec cx				; Mas caracteres?
	cmp cx, 0
	je .finish
	dec si				;Retrocede un personaje en la 							cadena
	jmp .loop

.finish:
	mov word [.tmp], bx
	popa
	mov word ax, [.tmp]

	ret


	.multiplier	dw 0
	.tmp		dw 0


; ------------------------------------------------------------------
; os_int_to_string - Convertir un entero sin signo en una cadena
; EN: AX = int firmado
; OUT: AX = ubicación de la cadena
os_int_to_string:
	pusha

	mov cx, 0
	mov bx, 10			; dar BX 10,para divicion y mod
	mov di, .t			; Prepara nuestro puntero

.push:
	mov dx, 0
	div bx				;  Resto en DX, cociente en 							AX.
	inc cx				; Aumentar el contador de pop 							loop
	push dx				; Empuje el resto, para 						revertir el orden al hacer estallar
	test ax, ax			; Es el cociente cero?
	jnz .push			;Si no, vuelve a bucear
.pop:
	pop dx				; Despliegue los valores en 		orden inverso y agregue 48 para hacerlos dígitos
	add dl, '0'			; Y guárdalos en la cadena, 					aumentando el puntero cada vez.
	mov [di], dl
	inc di
	dec cx
	jnz .pop

	mov byte [di], 0		;Cadena de terminacion cero

	popa
	mov ax, .t			;Ubicacion de retorno de la cadena
	ret


	.t times 7 db 0


; ------------------------------------------------------------------
; os_sint_to_string - Convierte un entero con signo en una cadena
; EN: AX = int firmado
; OUT: AX = ubicación de la cadena
os_sint_to_string:
	pusha

	mov cx, 0
	mov bx, 10			;Set BX 10, para división y mod.
	mov di, .t			; Prepara nuestro puntero

	test ax, ax			; Averigüe si X> 0 o no, 							forzar una señal
	js .neg				;Si negativo...
	jmp .push			; ...o si es positivo
.neg:
	neg ax				; Hace AX positivo
	mov byte [.t], '-'		; Añadir un signo menos a 							nuestra cadena
	inc di				; actualiza el index
.push:
	mov dx, 0
	div bx				; Resto en DX,cociente en AX
	inc cx				; Aumentar el contador de buce 							pop
	push dx				; Empuje el resto para revertir el orden al hacer estallar 
	test ax, ax			; Es el cociente cero?
	jnz .push			; Si no, vuelve a buscar
.pop:
	pop dx				;  Despliegue los valores en 		orden inverso y agregue 48 para hacerlos dígitos
	add dl, '0'			; Y guárdalos en la cadena, 					aumentando el puntero cada vez
	mov [di], dl
	inc di
	dec cx
	jnz .pop

	mov byte [di], 0		;  Cadena de terminación cero

	popa
	mov ax, .t			; Ubicación de retorno de la cadena
	ret


	.t times 7 db 0


; ------------------------------------------------------------------
; os_long_int_to_string - Convierte el valor en DX: AX a cadena
; IN: DX: AX = entero sin signo largo, BX = base del número, DI = ubicación de la cadena
; OUT: DI = ubicación de la cadena convertida
os_long_int_to_string:
	pusha

	mov si, di			; Preparar para el posterior 							movimiento de datos

	mov word [di], 0		; Terminar cadena, crea 'null'

	cmp bx, 37			;Base> 37 o <0 no es compatible, 						devuelve nulo
	ja .done

	cmp bx, 0			; Base = 0 produce desbordamiento, 						devuelve nulo
	je .done

.conversion_loop:
	mov cx, 0			;Cero extender entero sin signo, número = CX: DX: AX
					; Si número = 0, recorra el bucle 					una vez y almacene '0'

	xchg ax, cx			; Número de orden DX: AX: CX 				para la división de orden superior
	xchg ax, dx
	div bx				; AX = cociente alto, DX = 								resto alto

	xchg ax, cx			; Número de orden para la 								división de orden bajo
	div bx				; CX = cociente alto, AX = 							cociente bajo, DX = resto
	xchg cx, dx			; CX = dígito para enviar

.save_digit:
	cmp cx, 9			; Eliminar la puntuación entre '9' y 'A'
	jle .convert_digit

	add cx, 'A'-'9'-1

.convert_digit:
	add cx, '0'			; Convertir a ASCII

	push ax				; Cargue este dígito ASCII en 						el principio de la cadena
	push bx
	mov ax, si
	call os_string_length		; AX = longitud de la cuerda, 								menos terminador
	mov di, si
	add di, ax			; DI = final de la cadena
	inc ax				;  AX = nunber de caracteres 					para mover, incluido el terminador

.move_string_up:
	mov bl, [di]			; Pon los dígitos en el orden 							correcto
	mov [di+1], bl
	dec di
	dec ax
	jnz .move_string_up

	pop bx
	pop ax
	mov [si], cl			; El último dígito (LSD) se 					imprimirá primero (a la izquierda)

.test_end:
	mov cx, dx			;  DX = palabra alta, de nuevo
	or cx, ax			; ¿No queda nada?
	jnz .conversion_loop

.done:
	popa
	ret


; ------------------------------------------------------------------
; os_set_time_fmt: establecer el formato de informe de hora (por ejemplo, '10: 25 AM 'o' 2300 horas ')
; EN: AL = bandera de formato, 0 = formato de 12 horas
os_set_time_fmt:
	pusha
	cmp al, 0
	je .store
	mov al, 0FFh
.store:
	mov [fmt_12_24], al
	popa
	ret


; ------------------------------------------------------------------
; os_get_time_string - Obtener la hora actual en una cadena (por ejemplo, '10: 25 ')
; IN / OUT: BX = ubicación de la cadena
os_get_time_string:
	pusha

	mov di, bx			;  Ubicación para colocar la cadena 						de tiempo

	clc				; Para BIOS con errores
	mov ah, 2			;  Obtenga datos de tiempo de BIOS 						en formato BCD
	int 1Ah
	jnc .read

	clc
	mov ah, 2			; BIOS se estaba actualizando (~ 1 		en 500 posibilidades), así que inténtalo de nuevo
	int 1Ah

.read:
	mov al, ch			; Convertir horas a entero para 							prueba de AM / PM
	call os_bcd_to_int
	mov dx, ax			; Guarda

	mov al,	ch			; Hora
	shr al, 4			; Dígito de decenas: mueve el 					número BCD más alto a bits más bajos
	and ch, 0Fh			; Un digito
	test byte [fmt_12_24], 0FFh
	jz .twelve_hr

	call .add_digit			; BCD ya en formato de 24 								horas
	mov al, ch
	call .add_digit
	jmp short .minutes

.twelve_hr:
	cmp dx, 0			; Si 00mm, haz las 12 AM
	je .midnight

	cmp dx, 10			; Si 00mm, haz las 12 AM
	jl .twelve_st1

	cmp dx, 12			;  Entre 1000 y 1300, OK para 							almacenar 2 dígitos.
	jle .twelve_st2

	mov ax, dx			; Cambio de formato de 24 a 12 							horas.
	sub ax, 12
	mov bl, 10
	div bl
	mov ch, ah

	cmp al, 0			; 1-9 PM
	je .twelve_st1

	jmp short .twelve_st2		; 10-11 PM

.midnight:
	mov al, 1
	mov ch, 2

.twelve_st2:
	call .add_digit			; BCD modificado, hora de 2 							dígitos
.twelve_st1:
	mov al, ch
	call .add_digit

	mov al, ':'			; Separador de tiempo (formato 							de 12 horas)
	stosb

.minutes:
	mov al, cl			; Minuto
	shr al, 4			; Dígito de decenas: mueve el 					número BCD más alto a bits más bajos
	and cl, 0Fh			; un digito
	call .add_digit
	mov al, cl
	call .add_digit

	mov al, ' '			; Designación de tiempo 								separado
	stosb

	mov si, .hours_string		; Asumir formato de 24 horas
	test byte [fmt_12_24], 0FFh
	jnz .copy

	mov si, .pm_string		; Supongamos PM
	cmp dx, 12			; Prueba de AM / PM
	jg .copy

	mov si, .am_string		;  Era en realidad AM

.copy:
	lodsb				; Copia de designación, incluyendo terminadorterminator
	stosb
	cmp al, 0
	jne .copy

	popa
	ret


.add_digit:
	add al, '0'			; Convertir a ASCII
	stosb				; Poner en cadena de búfer
	ret


	.hours_string	db 'hours', 0
	.am_string 	db 'AM', 0
	.pm_string 	db 'PM', 0


; ------------------------------------------------------------------
; os_set_date_fmt - Configurar formato de informe de fecha (M / D / Y, D / M / Y o Y / M / D - 0, 1, 2)
; EN: AX = bandera de formato, 0-2
; Si AX bit 7 = 1 = usa nombre por meses
; Si AX bit 7 = 0, byte alto = carácter separador
os_set_date_fmt:
	pusha
	test al, 80h			;  ¿Meses ASCII (bit 7)?
	jnz .fmt_clear

	and ax, 7F03h			; Separador ASCII de 7 bits y 							número de formato
	jmp short .fmt_test

.fmt_clear:
	and ax, 0003			; Asegúrese de que el 							separador esté limpio

.fmt_test:
	cmp al, 3			; Solo se permiten 0, 1 y 2.
	jae .leave
	mov [fmt_date], ax

.leave:
	popa
	ret


; ------------------------------------------------------------------
; os_get_date_string - Obtener la fecha actual en una cadena (por ejemplo, '12 / 31/2007 ')
; IN / OUT: BX = ubicación de la cadena
os_get_date_string:
	pusha

	mov di, bx			; Almacenar ubicación de cadena por 							ahora
	mov bx, [fmt_date]		; BL = código de formato
	and bx, 7F03h			; BH = separador, 0 = usar 								nombres de mes

	clc				; Para BIOS con errores
	mov ah, 4			; Obtenga datos de fecha de BIOS en 						formato BCD
	int 1Ah
	jnc .read

	clc
	mov ah, 4			; BIOS se estaba actualizando (~ 1 		en 500 posibilidades), así que inténtalo de nuevo
	int 1Ah

.read:
	cmp bl, 2			;Formato YYYY / MM / DD, adecuado 				para la clasificación
	jne .try_fmt1

	mov ah, ch			; Proporcionar siempre año de 4 							dígitos
	call .add_2digits
	mov ah, cl
	call .add_2digits		; Y '/' como separador
	mov al, '/'
	stosb

	mov ah, dh			; Siempre mes de 2 dígitos
	call .add_2digits
	mov al, '/'			; And '/' as separator
	stosb

	mov ah, dl			;  Y '/' como separador
	call .add_2digits
	jmp short .done

.try_fmt1:
	cmp bl, 1			;Formato D / M / Y (militar y 							europeo)
	jne .do_fmt0

	mov ah, dl			; Dia
	call .add_1or2digits

	mov al, bh
	cmp bh, 0
	jne .fmt1_day

	mov al, ' '			; Si son meses ASCII, usar el 						espacio como separador.

.fmt1_day:
	stosb				; Separador dia-mes

	mov ah,	dh			; Mes
	cmp bh, 0			; ASCII?
	jne .fmt1_month

	call .add_month			; Sí, agregar a la cadena
	mov ax, ', '
	stosw
	jmp short .fmt1_century

.fmt1_month:
	call .add_1or2digits		;  No, usa dígitos y separador
	mov al, bh
	stosb

.fmt1_century:
	mov ah,	ch			; Siglo presente?
	cmp ah, 0
	je .fmt1_year

	call .add_1or2digits		; Sí, agregarlo a la cadena 				(más probable es que 2 dígitos)

.fmt1_year:
	mov ah, cl			; año
	call .add_2digits		; Al menos 2 dígitos por año, 						siempre.

	jmp short .done

.do_fmt0:				; Formato predeterminado, M / D / Y 					(EE. UU. Y otros)
	mov ah,	dh			; Mes
	cmp bh, 0			; ASCII?
	jne .fmt0_month

	call .add_month			; Sí, agregar a la cadena y el 							espacio
	mov al, ' '
	stosb
	jmp short .fmt0_day

.fmt0_month:
	call .add_1or2digits		; No, usa dígitos y separador
	mov al, bh
	stosb

.fmt0_day:
	mov ah, dl			; Dia
	call .add_1or2digits

	mov al, bh
	cmp bh, 0			; ASCII?
	jne .fmt0_day2

	mov al, ','			; Sí, separador = espacio de 							coma
	stosb
	mov al, ' '

.fmt0_day2:
	stosb

.fmt0_century:
	mov ah,	ch			; Siglo presente?
	cmp ah, 0
	je .fmt0_year

	call .add_1or2digits		; Sí, agregarlo a la cadena 				(más probable es que 2 dígitos)

.fmt0_year:
	mov ah, cl			; Año
	call .add_2digits		; Al menos 2 dígitos por año, 							siempre.


.done:
	mov ax, 0			;  Cadena de fecha de terminación
	stosw

	popa
	ret


.add_1or2digits:
	test ah, 0F0h
	jz .only_one
	call .add_2digits
	jmp short .two_done
.only_one:
	mov al, ah
	and al, 0Fh
	call .add_digit
.two_done:
	ret

.add_2digits:
	mov al, ah			; Convertir AH a 2 dígitos ASCII
	shr al, 4
	call .add_digit
	mov al, ah
	and al, 0Fh
	call .add_digit
	ret

.add_digit:
	add al, '0'			;  Convertir AL a ASCII
	stosb				; Poner en cadena de búfer
	ret

.add_month:
	push bx
	push cx
	mov al, ah			; Convertir mes a entero para indexar tablade impresión
	call os_bcd_to_int
	dec al				; January = 0
	mov bl, 4			;Multiplica mes por 4 caracteres / mes.
	mov si, .months
	add si, ax
	mov cx, 4
	rep movsb
	cmp byte [di-1], ' '		; May?
	jne .done_month			;  Sí, eliminar el espacio extra
	dec di
.done_month:
	pop cx
	pop bx
	ret


	.months db 'Jan.Feb.Mar.Apr.May JuneJulyAug.SeptOct.Nov.Dec.'


; ------------------------------------------------------------------
; os_string_tokenize - Lee tokens separados por caracteres especificados de
; una cuerda. Devuelve el puntero al siguiente token o 0 si no queda ninguno.
; IN: AL = separador char, SI = inicio; OUT: DI = siguiente token o 0 si no hay
os_string_tokenize:
	push si

.next_char:
	cmp byte [si], al
	je .return_token
	cmp byte [si], 0
	jz .no_more
	inc si
	jmp .next_char

.return_token:
	mov byte [si], 0
	inc si
	mov di, si
	pop si
	ret

.no_more:
	mov di, 0
	pop si
	ret


; ==================================================================

