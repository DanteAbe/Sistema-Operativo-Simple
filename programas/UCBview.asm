;Desde aqui Ruben Dario Gutierrez De Nazaret
	BITS 16
	%INCLUDE "assemblerdev.inc"
	ORG 32768


main_start:
	call draw_background

	call os_file_selector		; Obtener nombre de archivo

	jc near close			; Salir si se presiona Esc en el cuadro de diálogo

	mov bx, ax			; Guardar nombre de archivo por ahora

	mov di, ax

	call os_string_length
	add di, ax			;DI ahora apunta al último carácter en el nombre de archivo
	dec di
	dec di
	dec di				; ... y ahora al primer char de extensión!

	mov si, txt_extension
	mov cx, 3
	rep cmpsb			; ¿La extensión contiene 'TXT'?
	je near valid_txt_extension	; Salte adelante si es así

	dec di

	mov si, bas_extension
	mov cx, 3
	rep cmpsb			; ¿La extensión contiene 'BAS'?
	je near valid_txt_extension	; Salte adelante si es así

	dec di

	mov si, pcx_extension
	mov cx, 3
	rep cmpsb			; ¿La extensión contiene 'PCX'?
	je valid_pcx_extension		; Salte adelante si es así

					; De lo contrario, se mostrará el diálogo de error.
	mov dx, 0			; Un botón para el cuadro de diálogo
	mov ax, err_string
	mov bx, 0
	mov cx, 0
	call os_dialog_box

	jmp main_start			; Y reintentar


valid_pcx_extension:
	mov ax, bx
	mov cx, 36864			; Cargue PCX en 36864 (4 K después del inicio del programa)
	call os_load_file


	mov ah, 0			; Cambiar al modo de gráficos
	mov al, 13h
	int 10h


	mov ax, 0A000h			; ES = memoria de video
	mov es, ax


	mov si, 36864+80h		; Mover la fuente al inicio de los datos de la imagen.
					; (Los primeros 80h bytes son encabezado)

	mov di, 0			; Comience nuestro bucle en la parte superior de la memoria RAM de vídeo

decode:
	mov cx, 1
	lodsb
	cmp al, 192			; ¿Un solo píxel o cadena?
	jb single
	and al, 63			; Cadena, así que 'mod 64' es
	mov cl, al			; Resultado en CL para el siguiente 'rep'
	lodsb				; Obtener byte para poner en pantalla
single:
	rep stosb			; Y mostrarlo (o todos ellos)
	cmp di, 64001
	jb decode


	mov dx, 3c8h			; Registro de índice de paleta
	mov al, 0			; Comenzar en color 0
	out dx, al			; Dile al controlador VGA que ...
	inc dx				; ... 3c9h = registro de datos de paleta

	mov cx, 768			; 256 colores, 3 bytes cada uno
setpal:
	lodsb				; Agarra el siguiente byte.
	shr al, 2			; Paletas divididas por 4, así que deshacer.
	out dx, al			; Enviar al controlador VGA
	loop setpal


	call os_wait_for_key

	mov ax, 3			; Volver al modo de texto
	mov bx, 0
	int 10h
	mov ax, 1003h			; No hay texto parpadeante!
	int 10h

	mov ax, 2000h			; Restablecer ES a su valor original
	mov es, ax
	call os_clear_screen
	jmp main_start


draw_background:
	mov ax, title_msg		; Configurar la pantalla
	mov bx, footer_msg
	mov cx, NEGRO_EN_BLANCO
	call os_draw_background
	ret



	;Mientras tanto, si es un archivo de texto ...

valid_txt_extension:
	mov ax, bx
	mov cx, 36864			; Cargar archivo 4K después del inicio del programa
	call os_load_file


	; Ahora BX contiene el número de bytes en el archivo, así que vamos a agregar
	; el desplazamiento de carga para obtener el último byte del archivo en la RAM

	add bx, 36864


	mov cx, 0			; Líneas a saltar al renderizar
	mov word [skiplines], 0


	pusha
	mov ax, txt_title_msg		; Configurar la pantalla
	mov bx, txt_footer_msg
	mov cx, 11110000b		; Texto negro sobre fondo blanco
	call os_draw_background
	popa



txt_start:
	pusha

	mov bl, 11110000b		; Texto negro sobre fondo blanco
	mov dh, 2
	mov dl, 0
	mov si, 80
	mov di, 23
	call os_draw_block		; Sobrescribir el texto antiguo para el desplazamiento

	mov dh, 2			; Mueve el cursor cerca de la parte superior
	mov dl, 0
	call os_move_cursor

	popa


	mov si, 36864			; Inicio de datos de texto
	mov ah, 0Eh			; Rutina de impresión de caracteres BIOS


redraw:
	cmp cx, 0			; ¿Cuántas líneas para saltar?
	je loopy
	dec cx

skip_loop:
	lodsb				; Leer bytes hasta nueva línea, para saltar una línea.
	cmp al, 10
	jne skip_loop
	jmp redraw


loopy:
	lodsb				; Obtener el carácter de los datos del archivo

	cmp al, 10			; Volver al inicio de línea si el carácter de retorno de carro
	jne skip_return
	call os_get_cursor_pos
	mov dl, 0
	call os_move_cursor

skip_return:
	int 10h				; Imprimir el personaje

	cmp si, bx			; ¿Hemos impreso todo en el archivo?
	je finished

	call os_get_cursor_pos		; ¿Estamos en la parte inferior del área de visualización?
	cmp dh, 23
	je get_input

	jmp loopy


get_input:				; Obtener las teclas del cursor y Q
	call os_wait_for_key
	cmp ah, TECLA_ARRIBA
	je go_up
	cmp ah, TECLA_ABAJO
	je go_down
	cmp al, 'q'
	je main_start
	cmp al, 'Q'
	je main_start
	jmp get_input
;Hasta aqui Ruben Dario Gutierrez
;Desde aqui Omar Mallea

go_up:
	cmp word [skiplines], 0		; No se desplace hacia arriba si estamos en la parte superior
	jle txt_start
	dec word [skiplines]		; De lo contrario decrementaremos las líneas que necesitamos para saltar.
	mov word cx, [skiplines]
	jmp txt_start

go_down:
	inc word [skiplines]		; Incrementar las líneas que necesitamos para saltar.
	mov word cx, [skiplines]
	jmp txt_start


finished:				
	call os_wait_for_key
	cmp ah, 48h
	je go_up			; Solo puede desplazarse hacia arriba en este punto
	cmp al, 'q'
	je main_start
	cmp al, 'Q'
	je main_start
	jmp finished


close:
	call os_clear_screen
	ret


	txt_extension	db 'TXT', 0
	bas_extension	db 'BAS', 0
	pcx_extension	db 'PCX', 0

	err_string	db 'Seleccione un archivo TXT, BAS o PCX ', 0

	title_msg	db 'UCB Viewer', 0
	footer_msg	db 'Seleccione un archivo TXT, BAS o PCX para ver, o ESC para volver al escritorio', 0

	txt_title_msg	db 'UCB Viewer', 0
	txt_footer_msg	db 'Muevase con las flechas o Q para salir del programa', 0

	skiplines	dw 0


; ------------------------------------------------------------------

