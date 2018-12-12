os_print_string:
	pusha

	mov ah, 0Eh			; int 10h teletype function

.repeat:
	lodsb				; Obtener tipo de dato char de cadena
	cmp al, 0
	je .done			; si el tipo de dato char es cero, fin de la cadena

	int 10h				; De lo contrario, lo imprime
	jmp .repeat			; y lo mueve al siguiente char

.done:
	popa
	ret


; ------------------------------------------------------------------
; os_clear_screen -- Borra la pantalla de fondo
; IN/OUT: Nada (registros preservados)

os_clear_screen:
	pusha

	mov dx, 0			; Posicion cursor superior izquierda
	call os_move_cursor

	mov ah, 6			; Pantalla completa
	mov al, 0			; Blanco normal sobre negro
	mov bh, 7			;
	mov cx, 0			; Superior izquierda
	mov dh, 140			; Abajo a la derecha
	mov dl, 190
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_move_cursor -- Mueve el cursor en modo texto
; IN: DH, DL = row, column; OUT: Nada (registros preservados)

os_move_cursor:
	pusha

	mov bh, 0
	mov ah, 2
	int 10h			; BIOS interrumpido para mover cursor

	popa
	ret


; ------------------------------------------------------------------
; os_get_cursor_pos -- Return position of text cursor
; OUT: DH, DL = row, column

os_get_cursor_pos:
	pusha

	mov bh, 0
	mov ah, 3
	int 10h	; BIOS interrumpido para mover posicion del cursor

	mov [.tmp], dx
	popa
	mov dx, [.tmp]
	ret


	.tmp dw 0


; ------------------------------------------------------------------
; os_print_horiz_line -- Dibuja una linea horizontal en la pantalla
; IN: AX = tipo de linea (1 para double (-), de lo contrario single (=))
; OUT: Nada (registros preservados)

os_print_horiz_line:
	pusha

	mov cx, ax			; Tipo de linea param
	mov al, 196	; Por default es una linea simple de codigo

	cmp cx, 1		; ¿Se especificó una línea doble en AX?
	jne .ready
	mov al, 205			; Si es así, aquí está el código

.ready:
	mov cx, 0			; mostrador
	mov ah, 0Eh		; BIOS rutina de salida de caracteres

.restart:
	int 10h
	inc cx
	cmp cx, 80			; Ya se ha dibujado 80 caracteres?
	je .done
	jmp .restart

.done:
	popa
	ret


; ------------------------------------------------------------------
; os_show_cursor -- Enciende el cursor en modo texto.
; IN/OUT: Nada

os_show_cursor:
	pusha

	mov ch, 6
	mov cl, 7
	mov ah, 1
	mov al, 3
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_hide_cursor -- Apaga el cursor en modo texto.
; IN/OUT: Nada

os_hide_cursor:
	pusha

	mov ch, 32
	mov ah, 1
	mov al, 3			; Modo de video para BIOS con errores!
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_draw_block -- Bloque de render del color especificado
; IN: BL/DL/DH/SI/DI = color/empieza X pos/empieza Y pos/ancho/termina Y pos

os_draw_block:
	pusha

.more:
	call os_move_cursor	; Mover a la posición inicial de bloqueo

	mov ah, 09h			; Dibujar sección de color
	mov bh, 0
	mov cx, si
	mov al, ' '
	int 10h

	inc dh			; Prepara para la siguiente línea

	mov ax, 0
	mov al, dh			; Obtener posición actual de Y en DL
	cmp ax, di			; Punto de llegada alcanzado (DI)?
	jne .more			; Si no, sigue dibujando

	popa
	ret


; ------------------------------------------------------------------
; os_file_selector -- Mostrar un diálogo de selección de archivos
; IN: Nothing; OUT: AX = ubicación de la cadena de nombre de archivo (o carry set si se presiona Esc)

os_file_selector:
	pusha

	mov word [.filename], 0		; Terminar cadena en caso de que el usuario salga sin elegir

	mov ax, .buffer			; Obtener una lista de nombres de archivo separados por comas
	call os_get_file_list

	mov ax, .buffer			; Mostrar esos nombres de archivo en un cuadro de diálogo de lista
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_list_dialog

	jc .esc_pressed

	dec ax				; El resultado de os_list_box comienza desde 1, pero
					; para nuestra lista de archivos de compensación queremos comenzar desde 0

	mov cx, ax
	mov bx, 0

	mov si, .buffer			; Obtenga nuestro nombre de archivo de la lista
.loop1:
	cmp bx, cx
	je .got_our_filename
	lodsb
	cmp al, ','
	je .comma_found
	jmp .loop1

.comma_found:
	inc bx
	jmp .loop1


.got_our_filename:		; Ahora copia la cadena de nombre de archivo
	mov di, .filename
.loop2:
	lodsb
	cmp al, ','
	je .finished_copying
	cmp al, 0
	je .finished_copying
	stosb
	jmp .loop2

.finished_copying:
	mov byte [di], 0		; Cero termina la cadena de nombre de archivo

	popa

	mov ax, .filename

	clc
	ret


.esc_pressed:				; Establecer bandera de acarreo si se presionó escape
	popa
	stc
	ret


	.buffer		times 1024 db 0

	.help_msg1	db 'Seleccion un programa', 0
	.help_msg2	db 'Muevase con las flechas del teclado', 0

	.filename	times 13 db 0


; ------------------------------------------------------------------
; os_list_dialog -- Mostrar un diálogo con una lista de opciones.
; IN: AX = lista de cadenas separadas por comas para mostrar (terminadas en cero),
;     BX = primera cadena de ayuda, CX = segunda cadena de ayuda
; OUT: AX = número (comienza desde 1) de la entrada seleccionada; carry set si se presiona Esc

os_list_dialog:
	pusha

	push ax				; Almacenar lista de cadenas por ahora

	push cx				; Y cadenas de ayuda
	push bx

	call os_hide_cursor


	mov cl, 0			; Cuenta el número de entradas en la lista
	mov si, ax
.count_loop:
	lodsb
	cmp al, 0
	je .done_count
	cmp al, ','
	jne .count_loop
	inc cl
	jmp .count_loop

.done_count:
	inc cl
	mov byte [.num_of_entries], cl


	mov bl, 00011111b		; Blanco en rojo
	mov dl, 20			; empieza en posicion X 
	mov dh, 2			; empieza en posicion Y 
	mov si, 40			; Ancho
	mov di, 23			; Termina en posicion Y
	call os_draw_block	; Dibujar ventana selector de opciones

	mov dl, 21			; Muestra la primera linea en el texto de ayuda...
	mov dh, 3
	call os_move_cursor

	pop si				; vuelve a la primera cadena
	call os_print_string

	inc dh				; ...y a la segunda
	call os_move_cursor

	pop si
	call os_print_string


	pop si				; SI = ubicación de la cadena de la lista de opciones (insertada anteriormente)
	mov word [.list_string], si


	; Ahora que hemos dibujado la lista, resalte el seleccionado actualmente
; Ingrese y deje que el usuario se mueva hacia arriba y hacia abajo con las teclas de cursor

	mov byte [.skip_num], 0		; No saltarse ninguna línea al principio mostrando

	mov dl, 25			; Configurar la posición inicial para el selector
	mov dh, 7

	call os_move_cursor

.more_select:
	pusha
	mov bl, 11110001b		; Negro sobre blanco para el cuadro de lista de opciones
	mov dl, 21
	mov dh, 6
	mov si, 38
	mov di, 22
	call os_draw_block
	popa

	call .draw_black_bar

	mov word si, [.list_string]
	call .draw_list

.another_key:
	call os_wait_for_key		; Mover / seleccionar 
	cmp ah, 48h			; arriba presionado?
	je .go_up
	cmp ah, 50h			; Abajo presionado?
	je .go_down
	cmp al, 13			; Enter presionado?
	je .option_selected
	cmp al, 27			; Esc presionado?
	je .esc_pressed
	jmp .more_select		; Si no, espera por otra tecla


.go_up:
	cmp dh, 7			; Ya en la cima?
	jle .hit_top

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	dec dh				; Fila para seleccionar (aumentando hacia abajo)
	jmp .more_select


.go_down:				; ¿Ya estás al final de la lista?
	cmp dh, 20
	je .hit_bottom

	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	inc dh
	jmp .more_select


.hit_top:
	mov byte cl, [.skip_num]	; ¿Alguna línea para desplazarse hacia arriba?
	cmp cl, 0
	je .another_key			; Si  no, espera por otra tecla

	dec byte [.skip_num]		; Si es así, decrementar líneas para saltar
	jmp .more_select


.hit_bottom:			; A ver si hay más para desplazarse
	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	inc byte [.skip_num]		; Si es así, aumentar líneas para saltar
	jmp .more_select



.option_selected:
	call os_show_cursor

	sub dh, 7

	mov ax, 0
	mov al, dh

	inc al				; Las opciones empiezan en 1
	add byte al, [.skip_num]	; Añadir cualquier línea omitida de desplazamiento

	mov word [.tmp], ax		; Almacena el número de opción antes de restaurar todos los demás registros

	popa

	mov word ax, [.tmp]
	clc				; Borrar carry como si Esc no fue presionado
	ret



.esc_pressed:
	call os_show_cursor
	popa
	stc				; Set carry para Esc
	ret



.draw_list:
	pusha

	mov dl, 23			; Entra en posición para el texto de la lista de opciones
	mov dh, 7
	call os_move_cursor


	mov cx, 0			; Saltar líneas desplazadas desde la parte superior del diálogo
	mov byte cl, [.skip_num]

.skip_loop:
	cmp cx, 0
	je .skip_loop_finished
.more_lodsb:
	lodsb
	cmp al, ','
	jne .more_lodsb
	dec cx
	jmp .skip_loop


.skip_loop_finished:
	mov bx, 0			; Contador para el número total de opciones


.more:
	lodsb				; Obtener el siguiente carácter en el nombre del archivo, puntero de incremento

	cmp al, 0			; Cadena terminada?
	je .done_list

	cmp al, ','			; Siguiente opcion? (La cadena está separada por comas)
	je .newline

	mov ah, 0Eh
	int 10h
	jmp .more

.newline:
	mov dl, 23			; Volver a la posición inicial X
	inc dh			; Pero salta hacia abajo unas líneas
	call os_move_cursor

	inc bx	; Actualizar el contador de número de opciones
	cmp bx, 14			; Limitar a una pantalla de opciones
	jl .more

.done_list:
	popa
	call os_move_cursor

	ret



.draw_black_bar:
	pusha

	mov dl, 22
	call os_move_cursor

	mov ah, 09h	; Dibuja una barra blanca en parte superior
	mov bh, 0
	mov cx, 36
	mov bl, 11100000b	; BARRA SOBRE TEXTO
	mov al, ' '
	int 10h

	popa
	ret



.draw_white_bar:
	pusha

	mov dl, 22
	call os_move_cursor

	mov ah, 09h	; Dibuja una barra blanca en parte superior
	mov bh, 0
	mov cx, 36
	mov bl, 00000000b		; Texto negro sobre fondo blanco
	mov al, ' '
	int 10h

	popa
	ret


	.tmp			dw 0
	.num_of_entries		db 0
	.skip_num		db 0
	.list_string		dw 0


; ------------------------------------------------------------------
; os_draw_background -- Pantalla clara con barras superiores e inferiores blancas
; Contiene texto, y una sección central coloreada.
; IN: AX/BX = top/bottom localizacion cadena, CX = color

os_draw_background:
	pusha

	push ax		; Almacenar params para salir más tarde
	push bx
	push cx

	mov dl, 0
	mov dh, 0
	call os_move_cursor

	mov ah, 09h	; Dibuja una barra blanca en parte superior
	mov bh, 0
	mov cx, 80
	mov bl, 11110000b
	mov al, ' '
	int 10h

	mov dh, 1
	mov dl, 0
	call os_move_cursor

	mov ah, 09h			; Dibuja una seccion de color
	mov cx, 1840
	pop bx				; Obtener color param (originalmente en CX)
	mov bh, 0
	mov al, ' '
	int 10h

	mov dh, 24
	mov dl, 0
	call os_move_cursor

	mov ah, 09h			; Dibuja una barra blanca en la parte inferior
	mov bh, 0
	mov cx, 80
	mov bl, 11110000b
	mov al, ' '
	int 10h

	mov dh, 24
	mov dl, 1
	call os_move_cursor
	pop bx			; Obtener la cadena de abajo param
	mov si, bx
	call os_print_string

	mov dh, 0
	mov dl, 1
	call os_move_cursor
	pop ax			; Obtener param de cadena superior
	mov si, ax
	call os_print_string

	mov dh, 1			; Listo para el texto de la aplicación
	mov dl, 0
	call os_move_cursor

	popa
	ret


; ------------------------------------------------------------------
; os_print_newline -- Reiniciar el cursor para comenzar la siguiente línea
; IN/OUT: Nada (registros preservados)

os_print_newline:
	pusha

	mov ah, 0Eh			; Código de salida de BIOS

	mov al, 13
	int 10h
	mov al, 10
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_dump_registers -- Muestra el contenido del registro en hexadecimal en la pantalla.
; IN/OUT: AX/BX/CX/DX = se registra para mostrar

os_dump_registers:
	pusha

	call os_print_newline

	push di
	push si
	push dx
	push cx
	push bx

	mov si, .ax_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .bx_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .cx_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .dx_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .si_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .di_string
	call os_print_string
	call os_print_4hex

	call os_print_newline

	popa
	ret


	.ax_string		db 'AX:', 0
	.bx_string		db ' BX:', 0
	.cx_string		db ' CX:', 0
	.dx_string		db ' DX:', 0
	.si_string		db ' SI:', 0
	.di_string		db ' DI:', 0


; ------------------------------------------------------------------
; os_input_dialog -- Obtener cadena de texto del usuario a través de un cuadro de diálogo
; IN: AX = string location, BX = mensaje para mostrar; OUT: AX = localizacion de cadena

os_input_dialog:
	pusha

	push ax			; Guarda localizacion de la cadena
	push bx				; Guarda mensaje para mostrar


	mov dh, 10		; Primero, dibuja el cuadro de fondo rojo
	mov dl, 12

.redbox:		; Bucle para dibujar todas las líneas de caja
	call os_move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 55
	mov bl, 00011111b		; Blanco en rojo
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	mov dl, 14
	mov dh, 11
	call os_move_cursor


	pop bx		; Recibe el mensaje de vuelta y lo muestra
	mov si, bx
	call os_print_string

	mov dl, 14
	mov dh, 13
	call os_move_cursor


	pop ax		; Obtener la cadena de entrada de nuevo
	call os_input_string

	popa
	ret


; ------------------------------------------------------------------
; os_dialog_box -- Cuadro de diálogo Imprimir en medio de la pantalla, con botón (s)
; IN: AX, BX, CX = ubicaciones de cadena (establecer registros en 0 para no mostrar)
; IN: DX = 0 para el cuadro de diálogo 'Aceptar', 1 para los dos botones 'Aceptar' y 'Cancelar'
; OUT: Si el modo de dos botones, AX = 0 para OK y 1 para cancelar
; NOTE: Cada cadena está limitada a 40 caracteres

os_dialog_box:
	pusha

	mov [.tmp], dx

	call os_hide_cursor

	mov dh, 9		; Primero, dibuja el cuadro de fondo rojo
	mov dl, 19

.redbox:		; Bucle para dibujar todas las líneas de caja.
	call os_move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 42
	mov bl, 00011111b		; Blanco en rojo
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	cmp ax, 0		; Omitir parámetros de cadena si es cero
	je .no_first_string
	mov dl, 20
	mov dh, 10
	call os_move_cursor

	mov si, ax			; Primera cadena
	call os_print_string

.no_first_string:
	cmp bx, 0
	je .no_second_string
	mov dl, 20
	mov dh, 11
	call os_move_cursor

	mov si, bx			; Segunda cadena
	call os_print_string

.no_second_string:
	cmp cx, 0
	je .no_third_string
	mov dl, 20
	mov dh, 12
	call os_move_cursor

	mov si, cx			; Tercera cadena
	call os_print_string

.no_third_string:
	mov dx, [.tmp]
	cmp dx, 0
	je .one_button
	cmp dx, 1
	je .two_button


.one_button:
	mov bl, 00001111b		; Negro en blanco
	mov dh, 14
	mov dl, 35
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 38		; Botón OK,centrado en la parte inferior de la caja
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	jmp .one_button_wait


.two_button:
	mov bl, 11110000b		; Negro en blanco
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			; OK buton
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	mov dl, 44			; Cancel button
	mov dh, 14
	call os_move_cursor
	mov si, .cancel_button_string
	call os_print_string

	mov cx, 0			; Default button = 0
	jmp .two_button_wait



.one_button_wait:
	call os_wait_for_key
	cmp al, 13			; Wait for enter key (13) to be pressed
	jne .one_button_wait

	call os_show_cursor

	popa
	ret


.two_button_wait:
	call os_wait_for_key

	cmp ah, 75			; Left cursor key pressed?
	jne .noleft

	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			; OK button
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	mov bl, 01001111b		; AZUL EN CANCEL
	mov dh, 14
	mov dl, 42
	mov si, 9
	mov di, 15
	call os_draw_block

	mov dl, 44			; Cancelar boton
	mov dh, 14
	call os_move_cursor
	mov si, .cancel_button_string
	call os_print_string

	mov cx, 0		; Y actualizaremos el resultado volveremos.
	jmp .two_button_wait


.noleft:
	cmp ah, 77			; ¿Tecla de cursor derecha presionada?
	jne .noright


	mov bl, 01001111b		; Negro en blanco
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			; OK boton
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	mov bl, 11110000b	; Blanco sobre rojo para el botón de cancelar
	mov dh, 14
	mov dl, 43
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 44			; Cancelar boton
	mov dh, 14
	call os_move_cursor
	mov si, .cancel_button_string
	call os_print_string

	mov cx, 1			; Y actualizaremos el resultado volveremos.
	jmp .two_button_wait


.noright:
	cmp al, 13			; Espere a que se presione la tecla enter (13)
	jne .two_button_wait

	call os_show_cursor

	mov [.tmp], cx		; Mantener el resultado después de restaurar allregs
	popa
	mov ax, [.tmp]

	ret


	.ok_button_string	db 'OK', 0
	.cancel_button_string	db 'Cancel', 0
	.ok_button_noselect	db '   OK   ', 0
	.cancel_button_noselect	db '   Cancel   ', 0

	.tmp dw 0


; ------------------------------------------------------------------
; os_print_space -- Print a space to the screen
; IN/OUT: Nothing

os_print_space:
	pusha

	mov ah, 0Eh			; BIOS teletype function
	mov al, 20h			; Space is character 20h
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_dump_string -- Volcar la cadena como bytes hexadecimales y caracteres imprimibles
; IN: SI = apunta a la cuerda para volcar

os_dump_string:
	pusha

	mov bx, si			; Guardar para impresión final

.line:
	mov di, si			; Guardar puntero actual
	mov cx, 0			; Contador de bytes

.more_hex:
	lodsb
	cmp al, 0
	je .chr_print

	call os_print_2hex
	call os_print_space		; Un solo espacio la mayoría de los bytes
	inc cx

	cmp cx, 8
	jne .q_next_line

	call os_print_space		; Doble espacio centro de linea
	jmp .more_hex

.q_next_line:
	cmp cx, 16
	jne .more_hex

.chr_print:
	call os_print_space
	mov ah, 0Eh		; funcion de teletipo BIOS
	mov al, '|'		; Romper entre hex y personaje
	int 10h
	call os_print_space

	mov si, di			; Volver al principio de esta línea.
	mov cx, 0

.more_chr:
	lodsb
	cmp al, 0
	je .done

	cmp al, ' '
	jae .tst_high

	jmp short .not_printable

.tst_high:
	cmp al, '~'
	jbe .output

.not_printable:
	mov al, '.'

.output:
	mov ah, 0Eh
	int 10h

	inc cx
	cmp cx, 16
	jl .more_chr

	call os_print_newline		; va a la siguiente linea
	jmp .line

.done:
	call os_print_newline		; va a la siguiente linea

	popa
	ret


; ------------------------------------------------------------------
; os_print_digit -- Muestra los contenidos de AX como un solo dígito.
; Trabaja hasta la base 37, ie digitos 0-Z
; IN: AX = "digit" para format y imprimir

os_print_digit:
	pusha

	cmp ax, 9		; Hay una ruptura en la tabla ASCII entre 9 y A
	jle .digit_format

	add ax, 'A'-'9'-1	; Corregir por la puntuación omitida.

.digit_format:
	add ax, '0'				

	mov ah, 0Eh		; Puede modificar otros registros.
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_print_1hex -- Muestra nibble bajo de AL en formato hexadecimal
; IN: AL = numero para el formato e imprimir

os_print_1hex:
	pusha

	and ax, 0Fh		; Enmascara los datos para mostrar
	call os_print_digit

	popa
	ret


; ------------------------------------------------------------------
; os_print_2hex -- Displays AL in hex format
; IN: AL = number to format and print

os_print_2hex:
	pusha

	push ax				; Output high nibble
	shr ax, 4
	call os_print_1hex

	pop ax				; Output low nibble
	call os_print_1hex

	popa
	ret


; ------------------------------------------------------------------
; os_print_4hex -- Displays AX in hex format
; IN: AX = number to format and print

os_print_4hex:
	pusha

	push ax				; Output high byte
	mov al, ah
	call os_print_2hex

	pop ax				; Output low byte
	call os_print_2hex

	popa
	ret


; ------------------------------------------------------------------
; os_input_string -- Take string from keyboard entry
; IN/OUT: AX = location of string, other regs preserved
; (Location will contain up to 255 characters, zero-terminated)

os_input_string:
	pusha

	mov di, ax			; DI is where we'll store input (buffer)
	mov cx, 0			; Character received counter for backspace


.more:					; Now onto string getting
	call os_wait_for_key

	cmp al, 13			; If Enter key pressed, finish
	je .done

	cmp al, 8			; Backspace pressed?
	je .backspace			; If not, skip following checks

	cmp al, ' '			; In ASCII range (32 - 126)?
	jb .more			; Ignore most non-printing characters

	cmp al, '~'
	ja .more

	jmp .nobackspace


.backspace:
	cmp cx, 0			; Backspace at start of string?
	je .more			; Ignore it if so

	call os_get_cursor_pos		; Backspace at start of screen line?
	cmp dl, 0
	je .backspace_linestart

	pusha
	mov ah, 0Eh			; If not, write space and move cursor back
	mov al, 8
	int 10h				; Backspace twice, to clear space
	mov al, 32
	int 10h
	mov al, 8
	int 10h
	popa

	dec di				; Character position will be overwritten by new
					; character or terminator at end

	dec cx				; Step back counter

	jmp .more


.backspace_linestart:
	dec dh				; Jump back to end of previous line
	mov dl, 79
	call os_move_cursor

	mov al, ' '			; Print space there
	mov ah, 0Eh
	int 10h

	mov dl, 79			; And jump back before the space
	call os_move_cursor

	dec di				; Step back position in string
	dec cx				; Step back counter

	jmp .more


.nobackspace:
	pusha
	mov ah, 0Eh			; Output entered, printable character
	int 10h
	popa

	stosb				; Store character in designated buffer
	inc cx				; Characters processed += 1
	cmp cx, 254			; Make sure we don't exhaust buffer
	jae near .done

	jmp near .more			; Still room for more


.done:
	mov ax, 0
	stosb

	popa
	ret


; ==================================================================


