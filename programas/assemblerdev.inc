;Desde aca Joaquin Galean
; ------------------------------------------------------------------
; Incluye archivo para desarrollo del programa AssemblerRules (API versión 16)
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; LOCALIZACIONES IMPORTANTES

os_main	equ	0000h	; Donde comienza el código del sistema operativo


; ------------------------------------------------------------------
; COLORES (por ejemplo para os_draw_background y os_draw_block)

%DEFINE NEGRO_EN_BLANCO		11110000b
%DEFINE BLANCO_EN_NEGRO		00001111b
%DEFINE BLANCO_EN_ROJO_CLARO	11001111b
%DEFINE BLANCO_EN_VERDE		00101111b
%DEFINE ROJO_EN_VERDE_CLARO	10100100b


; ------------------------------------------------------------------
; TECLAS

%DEFINE TECLA_ARRIBA		72
%DEFINE TECLA_ABAJO	80
%DEFINE TECLA_IZQUIERDA	75
%DEFINE TECLA_DERECHA	77

%DEFINE TECLA_ESC		27
%DEFINE TECLA_ENTER	13


; ------------------------------------------------------------------
; LLAMADAS AL SISTEMA

; Control de pantalla

os_clear_screen		equ	0009h	; (Nada usado)
os_print_string		equ	0003h	; SI = ubicación de la cadena terminada en cero
os_move_cursor		equ	0006h	; DH, DL = fila, columna
os_print_horiz_line	equ	000Ch	; AX = 1 para línea doble, otro individual
os_print_newline	equ	000Fh	; (Nada usado)
os_draw_background	equ	002Ah	; AX, BX = cadenas, CX = color
os_draw_block		equ	00B4h	; BL = color, DH/DL/SI/DI = pos
os_input_dialog		equ	00A8h	; AX = cadena de entrada, BX = cadena msg
os_dialog_box		equ	003Ch	; AX, BX, CX = cadenas, DX = tipo
					; FUERA: AX = 0 para OK, 1 para cancel
					; (sólo multi opción para DX = 1)
os_list_dialog		equ	00ABh	; IN: AX = lista separada por comas de
					; cadenas de opción, BX, CX = ayuda a
					; mostrar en la parte superior de la lista
					; FUERA: AX = número (a partir de 1)
					; de la opción seleccionada, o llevar si Esc
os_file_selector	equ	005Ah	; Devuelve el nombre del archivo en AX
os_get_cursor_pos	equ	0069h	; FUERA: DH = fila, DL = columna
os_print_space		equ	006Ch	; (Nada usado)
os_dump_string		equ	006Fh	; SI = ubicación de la cadena
os_print_digit		equ	0072h	; AX = dígito para imprimir
os_print_1hex		equ	0075h	; Nibble bajo pantalla de AL en hex
os_print_2hex		equ	0078h	; Pantalla AL en hex
os_print_4hex		equ	007Bh	; Pantalla AX en hex
os_show_cursor		equ	008Ah	; (Nada usado)
os_hide_cursor		equ	008Dh	; (Nada usado)
os_dump_registers	equ	0090h	; Muestra contenidos de AX, BX, CX, DX


; Manejo del teclado

os_wait_for_key		equ	0012h	; Devuelve AL = tecla presionada
os_check_for_key	equ	0015h	; Returns AL = tecla presionada


; Manejo de archivos

os_get_file_list	equ	0042h	; AX = cadena para almacenar nombres de archivos
os_load_file		equ	0021h	; EN: AX = Ubicación de cadena de nombre de archivo,
					; CX = ubicación para cargar el archivo
					; FUERA: BX = tamaño del archivo en bytes,
					; limpia el acarreo si OK, establecer si falta
os_write_file		equ	0096h	; AX = nombre del archivo, BX = Ubicación de los datos,
					; CX = numero de bytes para guardar
os_file_exists		equ	0099h	; AX = nombre del archivo, limpia el acarreo si existe
os_create_file		equ	009Ch	; AX = nombre del archivo
os_remove_file		equ	009Fh	; AX = nombre del archivo
os_rename_file		equ	00A2h	; AX = nombre del archivo, BX = nuevo nombre del archivo
os_get_file_size	equ	00A5h	; AX = nombre del archivo, FUERA: BX = bytes
					; (64K max)


; Sonido

os_speaker_tone		equ	001Bh	; AX = frecuencia de la nota
os_speaker_off		equ	001Eh	; (Nada usado)


; Manejo de cadenas

os_int_to_string	equ	0018h	; AX = entero sin signo, fuera AX = cadena
os_sint_to_string	equ	00C0h	; AX = entero sin signo, fuera AX = cadena
os_string_reverse	equ	00AEh	; SI = ubicación de la cadena
os_string_length	equ	002Dh	; AX = ubicación de la cadena, devuelve AX = tamaño
os_string_uppercase	equ	0030h	; AX = cadena terminada en cero
os_string_lowercase	equ	0033h	; AX = cadena terminada en cero
os_input_string		equ	0036h	; AX = ubicación de la cadena
os_string_copy		equ	0039h	; SI = fuente, DI = cadena de destino
os_string_join		equ	003Fh	; AX, BX = cadenas fuente, CX = destino
os_string_compare	equ	0045h	; SI, DI = cadenas, acarrea si es el mismo
os_string_strincmp	equ	0093h	; Como anteriormente, pero con CL = caracteres para comprobar
os_string_chomp		equ	0048h	; AX = ubicación de la cadena
os_string_strip		equ	004Bh	; SI = cadena, AX = caracter para eliminar
os_string_truncate	equ	004Eh	; SI = cadena, AX = número de caracteres
os_set_time_fmt		equ	0084h	; AL = formato
os_set_date_fmt		equ	0087h	; AX = formato
os_get_time_string	equ	0054h	; BX = ubicación de la cadena por ejemplo '20:41'
os_get_date_string	equ	005Dh	; BX = ubicación de la cadena por ejemplo '12/31/2007'
os_find_char_in_string	equ	0066h	; EN: SI = cadena, AL = caracter para buscar
os_long_int_to_string	equ	007Eh	; DX:AX = número, BX = base, DI = cadena
os_string_to_int	equ	00B1h	; SI = cadena (encima de 65535), AX = entero
os_string_charchange	equ	00BAh	; SI = cadena, AL = viejo caracter, BL = nuevo
os_string_parse		equ	00C3h	; SI = cadena; salida: AX/BX/CX/DX =
					; subcadenas (o 0 si no está presente)
os_string_tokenize	equ	00CFh	; SI = cadena, AL = sep char; devuelve
					; DI = ficha siguiente


; Rutinas matematicas

os_get_random		equ	00B7h	; EN: AX, BX = bajo, alto; OUT: CX = número
os_bcd_to_int		equ	0051h	; AL = BCD número, devuelve AX = entero
os_long_int_negate	equ	0081h	; DX:AX = número


; Puertos

os_port_byte_out	equ	00C9h	; EN: DX = puerto, AL = byte
os_port_byte_in		equ	00CCh	; EN: DX = puerto; FUERA: AL = byte
os_serial_port_enable	equ	00BDh	; AX = 0 para 9600 baudios, 1 para 1200
os_send_via_serial	equ	0060h	; AL = byte para enviar
os_get_via_serial	equ	0063h	; Devuelve AL = byte recibido
					; OUT: AX = localización, o 0 si no se encuentra


; Misc OS funciones

os_run_basic		equ	00C6h	; AX = ubicación del código en RAM, BX = tamaño,
					; SI = cadena de parámetros (o 0 si ninguno)
os_get_api_version	equ	0057h	; Retorna API en la version en AL
os_pause		equ	0024h	; AX = 10mo segundo para esperar
os_fatal_error		equ	0027h	; AX = ubicación de la cadena de error

;Continuara...
; ------------------------------------------------------------------

