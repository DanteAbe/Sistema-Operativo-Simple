; DIVERSAS RUTINAS
; ==================================================================

; ------------------------------------------------------------------
; os_get_api_version -- 

; IN: Nothing; OUT: AL = API- VERSION

os_get_api_version:
	mov al, AssemblerOS_API_VER
	ret


; ------------------------------------------------------------------
; os_pause -- Retrasar la ejecución de fragmentos específicos de 110 ms.
; IN: AX = 100 FRAGMENTOS DE MILISEGUNDOS PARA ESPERAR(RETRASO MAXIMO ES DE 32767,
;     EL CUAL ES MULTIPLICADO POR 55ms = 1802 seconds = 30 minutos)

os_pause:
	pusha
	cmp ax, 0
	je .time_up			; Si el retraso es = 0 entonces rescatar

	mov cx, 0
	mov [.counter_var], cx		; Zero ,la variable del contador

	mov bx, ax
	mov ax, 0
	mov al, 2			; 2 * 55ms = 110mS
	mul bx				; MULTIPLICACION POR 110ms FRAGMENTOS REQUERIDO 
	mov [.orig_req_delay], ax	; GUARDAR

	mov ah, 0
	int 1Ah				; OBTENER CONTADOR INSTANTANEO

	mov [.prev_tick_count], dx	; GUARDAR PARA UNA PROXIMA EJECUCION
.checkloop:
	mov ah,0
	int 1Ah				; OBTENER CONTADOR INSTANTANEO OTRA VEZ

	cmp [.prev_tick_count], dx	; COMPARAR CON UN CONTADOR INSTANTANEO PREVIO
	jne .up_date			; SI ESTA CAMBIADO, REVISARLO
	jmp .checkloop			; DE OTRA FORMA, ESPERAR AL SIGUIENTE
.time_up:
	popa
	ret

.up_date:
	mov ax, [.counter_var]		; Incluir counter_var
	inc ax
	mov [.counter_var], ax

	cmp ax, [.orig_req_delay]	; El counter_var = retraso requerido?	jge .time_up; Yes, so bail out

	mov [.prev_tick_count], dx	; No, entonces actualizar .prev_tick_count 

	jmp .checkloop			; E ir a esperar por otro mas


	.orig_req_delay		dw	0
	.counter_var		dw	0
	.prev_tick_count	dw	0


; ------------------------------------------------------------------
; os_fatal_error -- Mostara el mensaje de error Y detendra la ejecucion
; IN: AX = Localizacion del string del mensaje ERROR 

os_fatal_error:
	mov bx, ax			; Almacenar ubicación de cadena por ahora

	mov dh, 0
	mov dl, 0
	call os_move_cursor

	pusha
	mov ah, 09h			; Dibuja una barra roja en la parte superior
	mov bh, 0
	mov cx, 240
	mov bl, 0011111b
	mov al, ' '
	int 10h
	popa

	mov dh, 0
	mov dl, 0
	call os_move_cursor

	mov si, .msg_inform		; INFORMA SOBRE UN ERROR FATAL
	call os_print_string

	mov si, bx			; Mensaje de error proporcionado por el programa
	call os_print_string

	jmp $				; DETENER LA EJECUCION 

	
	.msg_inform		db '>>> FATAL OPERATING SYSTEM ERROR', 13, 10, 0


; ==================================================================

