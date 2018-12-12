;Desde aqui Carolina llanos

	BITS 16
	%INCLUDE "assemblerdev.inc"
	ORG 32768


start:
	call setup_screen

	cmp si, 0				; Pasamos un nombre de archivo?
	je .no_param_passed

	call os_string_tokenize			; Si es asi, lo obtiene desde los parametros

	mov di, filename			; Guarda el archivo para utilizarlo despues
	call os_string_copy


	mov ax, si
	mov cx, 36864
	call os_load_file			; Carga el archivo 4K despues del punto de inicio del programa
	jnc file_load_success

	mov ax, file_load_fail_msg		; Si falla, muestra el mensaje y sale
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	call os_clear_screen
	ret					; Regresa al OS


.no_param_passed:
	call os_file_selector			; Obtiene el nombre del archivo para cargarlo

	jnc near file_chosen

	call os_clear_screen			; Sale si la tecla Esc esta presionada en el selector de archivos
	ret


file_chosen:
	mov si, ax				; Lo guarda para utilizarlo despues
	mov di, filename
	call os_string_copy


	; Ahora tenemos que asegurarnos de que la extension del archivo es .TXT o .BAS...

	mov di, ax
	call os_string_length
	add di, ax

	dec di					; Hace el punto ID para el ultimo caracter del nombre del archivo
	dec di
	dec di

	mov si, txt_extension			; Comprueba la extension .TXT 
	mov cx, 3
	rep cmpsb
	je valid_extension

	dec di

	mov si, bas_extension			; Comprueba la extension .BAS
	mov cx, 3
	rep cmpsb
	je valid_extension

	mov dx, 0
	mov ax, wrong_ext_msg
	mov bx, 0
	mov cx, 0
	call os_dialog_box

	mov si, 0
	jmp start



valid_extension:
	mov ax, filename
	mov cx, 36864				; Carga el archivo 4K despues del punto de inicio del programa
	call os_load_file

file_load_success:
	mov word [filesize], bx


	; Ahora BX contiene el numero de bytes del archivo, entonces le agregamos
	; el desplazamiento de carga para obtener el ultimo byte del archivo en la RAM

	add bx, 36864

	cmp bx, 36864
	jne .not_empty
	mov byte [bx], 10			; Si el archivo esta vacio, inserta una nueva linea de carateres para iniciar

	inc bx
	inc word [filesize]

.not_empty:
	mov word [last_byte], bx		; Posicion del almacenamiento del byte final de datos


	mov cx, 0				; Las lineas para saltar cuando lo realiza (marcador de desplazamiento)
	mov word [skiplines], 0

	mov byte [cursor_x], 0			; La posicion inicial del cursor sera el inico del texto
	mov byte [cursor_y], 2			; El archivo empezara a ser mosrtado en la linea 2 de la pantalla


	; Ahora necesitamos mostrar el texto en la pantalla; el loop siguiente es llamado
	; cada vez que la pantalla se desplaza, pero no cuando el cursor se mueve

render_text:
	call setup_screen

	mov dh, 2				; Mueve el cursor cerca del tope
	mov dl, 0
	call os_move_cursor


	mov si, 36864				; Punto de inicio de los datos del texo
	mov ah, 0Eh				; Rutina de impresion de los caracteres de la BIOS


	mov word cx, [skiplines]		; Ahora vamos a saltar lineas dependiendo del nivel de desplazamiento

redraw:
	cmp cx, 0				; Tenemos algunas lineas para saltar?
	je display_loop				; Si no es asi, empieza la visualizacion
	dec cx					; De otro modo trabaja a traves de las lineas

.skip_loop:
	lodsb					; Lee los bytes hasta una nueva linea, para saltar la linea
	cmp al, 10
	jne .skip_loop				; Pasa a la siguiente linea
	jmp redraw


display_loop:					; Ahora estamos listos para mostrar el texto
	lodsb					; Obtiene los caracteres desde los datos del archivo

	cmp al, 10				; Va al inicio de la linea si es un caracter de retorno
	jne skip_return

	call os_get_cursor_pos
	mov dl, 0				; Coloca DL = 0 (columna = 0)
	call os_move_cursor

skip_return:
	call os_get_cursor_pos			; No envuelve lineas en la pantalla
	cmp dl, 79
	je .no_print

	int 10h					; Imprime el caracter mediante la BIOS

.no_print:
	mov word bx, [last_byte]
	cmp si, bx				; Hemos imprimido todos los caracteres en el archivo?
	je near get_input

	call os_get_cursor_pos			; Estamos en la parte inferior del area de visualizacion?
	cmp dh, 23
	je get_input				; Espera a que se presione la tecla si es asi

	jmp display_loop			; Si no es asi, sigue renderizando los caracteres



	; Cuando lleguemos aqui, hemos visualizado el texto en la pantalla, y es tiempo
	; de poner el curso en la posicion establecida por el usuario (no donde se ha colocado despues de la representacion del texto)
	; y obtener la entrada

get_input:
;	call showbytepos			; USADO PARA DEPURAR (MUESTRA LA INFORMACION DEL CURSOR EN LA PARTE SUPERIOR DERECHA)

	mov byte dl, [cursor_x]			; Mueve el cursor a la posicion establecida por el usuario
	mov byte dh, [cursor_y]
	call os_move_cursor

	call os_wait_for_key			; Obtiene la entrada

	cmp ah, TECLA_ARRIBA				; La tecla del cursor esta presionada?
	je near go_up
	cmp ah, TECLA_ABAJO
	je near go_down
	cmp ah, TECLA_IZQUIERDA
	je near go_left
	cmp ah, TECLA_DERECHA
	je near go_right

	cmp al, TECLA_ESC				; Sale si la tecla Esc esta presionada
	je near close

	jmp text_entry				; De otro modo probablemente fue una entrada de texto


; ------------------------------------------------------------------
; Mueve el cursor hacia la izquierda en la pantalla, y hacia atras en los bytes de los datos

go_left:
	cmp byte [cursor_x], 0			; Estamos en el inicio de una linea?
	je .cant_move_left
	dec byte [cursor_x]			; Si no es asi, mueve el cursor y la posicion de los datos
	dec word [cursor_byte]

.cant_move_left:
	jmp get_input

; ------------------------------------------------------------------
; Mueve el cursor hacia la derecha en la pantalla, y hacia adelante en los bytes de los datos
	;Traducido por Carolina Llanos
;Hasta aqui Carolina llanos	
;Desde aqui Kevin Reynolds
go_right:
	pusha

	cmp byte [cursor_x], 79			; Extremo derecho de la pantalla?
	je .nothing_to_do			; No hagas nada si es asi

	mov word ax, [cursor_byte]
	mov si, 36864
	add si, ax				; Ahora SI apunta al carácter bajo el cursor.

	inc si

	cmp word si, [last_byte]		; No se puede mover a la derecha si estamos en el último byte de datos
	je .nothing_to_do

	dec si

	cmp byte [si], 0Ah			; No se puede mover a la derecha si estamos en un personaje de nueva línea
	je .nothing_to_do

	inc word [cursor_byte]			; Mueve la posición del byte de datos y la ubicación del cursor hacia adelante
	inc byte [cursor_x]

.nothing_to_do:
	popa
	jmp get_input


; ------------------------------------------------------------------
; Mueva el cursor hacia abajo en la pantalla y avance en bytes de datos

go_down:
	; First up, let's work out which character in the RAM file data
	; the cursor will point to when we try to move down

	pusha

	mov word cx, [cursor_byte]
	mov si, 36864
	add si, cx				; Ahora SI apunta al carácter bajo el cursor.

.loop:
	inc si
	cmp word si, [last_byte]		; ¿Está apuntando al último byte en los datos?
	je .do_nothing				; Salir si es así

	dec si

	lodsb					; De lo contrario coge un personaje de los datos.
	inc cx					; Mover nuestra posición a lo largo
	cmp al, 0Ah				; Buscar nueva linea char
	jne .loop				; Sigue intentando hasta que encontremos una nueva línea de caracteres.

	mov word [cursor_byte], cx
	
.nowhere_to_go:
	popa

	cmp byte [cursor_y], 22			; Si está presionado y el cursor está abajo, desplace la vista hacia abajo
	je .scroll_file_down
	inc byte [cursor_y]			; Si se presiona hacia abajo en otro lugar, simplemente mueva el cursor
	mov byte [cursor_x], 0			; E ir a la primera columna en la siguiente línea
	jmp render_text

.scroll_file_down:
	inc word [skiplines]			; Incrementar las líneas que necesitamos para saltar.
	mov byte [cursor_x], 0			; E ir a la primera columna en la siguiente línea
	jmp render_text				; Redibujar todo el lote


.do_nothing:
	popa

	jmp render_text


; ------------------------------------------------------------------
; Mueva el cursor hacia arriba en la pantalla y retroceda en bytes de datos

go_up:
	pusha

	mov word cx, [cursor_byte]
	mov si, 36864
	add si, cx				; Ahora SI apunta al carácter bajo el cursor.

	cmp si, 36864				; No hagas nada si ya estamos al inicio del archivo.
	je .start_of_file

	mov byte al, [si]			; ¿El cursor ya está en un carácter de nueva línea?
	cmp al, 0Ah
	je .starting_on_newline

	jmp .full_monty				; Si no, vuelve dos caracteres de nueva línea.


.starting_on_newline:
	cmp si, 36865
	je .start_of_file

	cmp byte [si-1], 0Ah			; ¿El personaje anterior a este es un personaje de nueva línea?
	je .another_newline_before
	dec si
	dec cx
	jmp .full_monty


.another_newline_before:			; ¿Y el de antes una nueva línea?
	cmp byte [si-2], 0Ah
	jne .go_to_start_of_line

	; Si es así, significa que el usuario presionó una nueva línea de caracteres con otra línea nueva.
	; Char arriba, así que solo queremos volver a eso, y no hacer nada más.

	dec word [cursor_byte]
	jmp .display_move



.go_to_start_of_line:
	dec si
	dec cx
	cmp si, 36864
	je .start_of_file
	dec si
	dec cx
	cmp si, 36864				; No hagas nada si ya estamos al inicio del archivo.
	je .start_of_file
	jmp .loop2



.full_monty:
	cmp si, 36864
	je .start_of_file

	mov byte al, [si]
	cmp al, 0Ah				; Buscar nueva linea char
	je .found_newline
	dec cx
	dec si
	jmp .full_monty


.found_newline:
	dec si
	dec cx

.loop2:
	cmp si, 36864
	je .start_of_file

	mov byte al, [si]
	cmp al, 0Ah				; Busque la nueva linea de caracteres
	je .found_done
	dec cx
	dec si
	jmp .loop2


.found_done:
	inc cx
	mov word [cursor_byte], cx
	jmp .display_move


.start_of_file:
	mov word [cursor_byte], 0
	mov byte [cursor_x], 0


.display_move:
	popa
	cmp byte [cursor_y], 2			; Si presionó hacia arriba y el cursor en la parte superior, desplace la vista hacia arriba
	je .scroll_file_up
	dec byte [cursor_y]			; Si presionas hacia arriba en otro lugar, simplemente mueve el cursor
	mov byte [cursor_x], 0			; E ir a la primera columna en la línea anterior
	jmp get_input

.scroll_file_up:
	cmp word [skiplines], 0			; No desplace la vista hacia arriba si estamos en la parte superior
	jle get_input
	dec word [skiplines]			; De lo contrario decrementaremos las líneas que necesitamos para saltar.
	jmp render_text


; ------------------------------------------------------------------
; Cuando se presiona una tecla (distinta de las teclas de cursor o Esc) ...

text_entry:
	pusha

	cmp ax, 3B00h				; F1 ¿presionado?
	je near .f1_pressed

	cmp ax, 3C00h				; F2 ¿presionado?
	je near save_file

	cmp ax, 3D00h				; F3 ¿presionado?
	je near new_file

	cmp ax, 3F00h				; F5 ¿presionado?
	je near .f5_pressed

	cmp ax, 4200h				; F8 ¿presionado?
	je near .f8_pressed

	cmp ah, 53h				; ¿Borrar?
	je near .delete_pressed

	cmp al, 8
	je near .backspace_pressed

	cmp al, TECLA_ENTER
	je near .enter_pressed
;Hasta aca kevin Reynolds

;Hasta aqui Sebastian Meguillanes
	cmp al, 32				; solo trate de desplegar el char
	jl near .nothing_to_do

	cmp al, 126
	je near .nothing_to_do

	call os_get_cursor_pos
	cmp dl, 78
	jg near .nothing_to_do


	push ax

	call move_all_chars_forward

	mov word cx, [cursor_byte]
	mov si, 36864
	add si, cx				;Ahora SI señala el char bajo el cursor


	pop ax

	mov byte [si], al
	inc word [cursor_byte]
	inc byte [cursor_x]

.nothing_to_do:
	popa
	jmp render_text



.delete_pressed:
	mov si, 36865
	add si, word [cursor_byte]

	cmp si, word [last_byte]
	je .end_of_file

	cmp byte [si], 0Ah
	jl .at_final_char_in_line

	call move_all_chars_backward
	popa
	jmp render_text

.at_final_char_in_line:
	call move_all_chars_backward		;El carácter de char y de la línea nueva también
	call move_all_chars_backward		; El carácter de char y de la línea nueva también
	popa
	jmp render_text



.backspace_pressed:
	cmp word [cursor_byte], 0
	je .do_nothing

	cmp byte [cursor_x], 0
	je .do_nothing

	dec word [cursor_byte]
	dec byte [cursor_x]

	mov si, 36864
	add si, word [cursor_byte]

	cmp si, word [last_byte]
	je .end_of_file

	cmp byte [si], 0Ah
	jl .at_final_char_in_line2

	call move_all_chars_backward
	popa
	jmp render_text

.at_final_char_in_line2:
	call move_all_chars_backward		; El carácter de char y de la línea nueva también
	call move_all_chars_backward		;El carácter de char y de la línea nueva también
	popa
	jmp render_text

.do_nothing:
	popa
	jmp render_text





.end_of_file:
	popa
	jmp render_text



.enter_pressed:
	call move_all_chars_forward

	mov word cx, [cursor_byte]
	mov di, 36864
	add di, cx				; Ahora SI señala el caractér  bajo el cursor

	mov byte [di], 0Ah			; se agrega un nuevo char a la linea
	popa
	jmp go_down


.f1_pressed:					; Salga a la vista alguna información de ayuda
	mov dx, 0				;La ventana de diálogo de un botón

	mov ax, .msg_1
	mov bx, .msg_2
	mov cx, .msg_3
	call os_dialog_box

	popa
	jmp render_text


	.msg_1	db	'Use Backspace to remove characters,', 0
	.msg_2	db	'and Delete to remove newline chars.', 0
	.msg_3	db	'Unix-formatted text files only!', 0



.f5_pressed:				; corta la linea 
	cmp byte [cursor_x], 0
	je .done_going_left
	dec byte [cursor_x]
	dec word [cursor_byte]
	jmp .f5_pressed

.done_going_left:
	mov si, 36864
	add si, word [cursor_byte]
	inc si
	cmp si, word [last_byte]
	je .do_nothing_here

	dec si
	cmp byte [si], 10
	je .final_char

	call move_all_chars_backward
	jmp .done_going_left

.final_char:
	call move_all_chars_backward

.do_nothing_here:
	popa
	jmp render_text




.f8_pressed:				; ejecuta el codigo basico
	mov word ax, [filesize]
	cmp ax, 4
	jl .not_big_enough

	call os_clear_screen

	mov ax, 36864
	mov si, 0
	mov word bx, [filesize]

	call os_run_basic

	call os_print_newline
	mov si, .basic_finished_msg
	call os_print_string
	call os_wait_for_key
	call os_show_cursor

	popa
	jmp render_text


.not_big_enough:
	mov ax, .fail1_msg
	mov bx, .fail2_msg
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	popa
	jmp render_text


	.basic_finished_msg	db ">>> BASIC finished - hit a key to return to the editor", 0
	.fail1_msg		db 'Not enough BASIC code to execute!', 0
	.fail2_msg		db 'You need at least an END command.', 0


; ------------------------------------------------------------------
; Active datos de cursor actual un carácter delante

move_all_chars_forward:
	pusha

	mov si, 36864
	add si, word [filesize]			; SI es igual al ultimo byte en el archivo

	mov di, 36864
	add di, word [cursor_byte]

.loop:
	mov byte al, [si]
	mov byte [si+1], al
	dec si
	cmp si, di
	jl .finished
	jmp .loop

.finished:
	inc word [filesize]
	inc word [last_byte]

	popa
	ret
;Hasta aqui Sebastian Meguillanes
;Traductor a continuación Dúrval Córdova Castro
; ------------------------------------------------------------------
; Mover datos desde el cursor actual + 1 al final del archivo de nuevo un char
move_all_chars_backward:
	pusha

	mov si, 36864
	add si, word [cursor_byte]

.loop:
	mov byte al, [si+1]
	mov byte [si], al
	inc si
	cmp word si, [last_byte]
	jne .loop

.finished:
	dec word [filesize]
	dec word [last_byte]

	popa
	ret


; ------------------------------------------------------------------
; Guardar archivo

save_file:
	mov ax, filename			; Eliminar el archivo si ya existe
	call os_remove_file

	mov ax, filename
	mov word cx, [filesize]
	mov bx, 36864
	call os_write_file

	jc .failure				; Si no pudiéramos guardar el archivo...

	mov ax, file_save_succeed_msg
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	popa
	jmp render_text


.failure:
	mov ax, file_save_fail_msg1
	mov bx, file_save_fail_msg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	popa
	jmp render_text


; ------------------------------------------------------------------
; Nuevo archivo

new_file:
	mov ax, confirm_msg
	mov bx, 0
	mov cx, 0
	mov dx, 1
	call os_dialog_box
	cmp ax, 1
	je .do_nothing

	mov di, 36864			; Borrar todo el buffer de texto
	mov al, 0
	mov cx, 28672
	rep stosb

	mov word [filesize], 1

	mov bx, 36864		; Almacene un solo carácter de nueva línea
	mov byte [bx], 10
	inc bx
	mov word [last_byte], bx

	mov cx, 0			; Restablecer otros valores
	mov word [skiplines], 0

	mov byte [cursor_x], 0
	mov byte [cursor_y], 2

	mov word [cursor_byte], 0


.retry_filename:
	mov ax, filename
	mov bx, new_file_msg
	call os_input_dialog


	mov ax, filename			; Elimine el archivo si ya existe
	call os_remove_file

	mov ax, filename
	mov word cx, [filesize]
	mov bx, 36864
	call os_write_file
	jc .failure				; Elimine el archivo si ya existe

.do_nothing:
	popa
	jmp render_text


.failure:
	mov ax, file_save_fail_msg1
	mov bx, file_save_fail_msg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp .retry_filename


; ------------------------------------------------------------------
; Salir

close:
	call os_clear_screen
	ret


; ------------------------------------------------------------------
; Pantalla Configuración con colores, títulos y líneas horizontales

setup_screen:
	pusha

	mov ax, txt_title_msg		; Configurar la pantalla con información en la parte superior e inferior
	mov bx, txt_footer_msg
	mov cx, NEGRO_EN_BLANCO
	call os_draw_background

	mov dh, 1				; Dibujar líneas en la parte superior e inferior
	mov dl, 0				; (Diferenciarlo del visor de archivos de texto)
	call os_move_cursor
	mov ax, 0				; Usar una sola línea de carácter
	call os_print_horiz_line

	mov dh, 23
	mov dl, 0
	call os_move_cursor
	call os_print_horiz_line

	popa
	ret


; ------------------------------------------------------------------
; DEBUGGING -- MOSTRAR POSICIÓN DE BYTE EN ARCHIVO Y CARACTER DEBAJO DEL CURSOR
; Habilitar ESTO EN get_input SECCIÓN ANTERIOR SI ES NECESARIO

showbytepos:
	pusha

	mov word ax, [cursor_byte]
	call os_int_to_string
	mov si, ax

	mov dh, 0
	mov dl, 60
	call os_move_cursor

	call os_print_string
	call os_print_space

	mov si, 36864
	add si, word [cursor_byte]
	lodsb

	call os_print_2hex
	call os_print_space

	mov ah, 0Eh
	int 10h

	call os_print_space

	popa
	ret


; ------------------------------------------------------------------
; Sección de datos

	txt_title_msg	db 'UCB Editor de Texto', 0
	txt_footer_msg	db '[Esc] Salir  [F1] Ayuda  [F2] Guardad  [F3] New  [F5] Elimina linea  [F8] corre BASIC', 0

	txt_extension	db 'TXT', 0
	bas_extension	db 'BAS', 0
	wrong_ext_msg	db 'Solo puedes cargar archivos tipo .TXT o .BAS!', 0
	confirm_msg	db '¿Estás seguro? ¡Los datos no guardados se perderán!', 0

	file_load_fail_msg	db 'No se pudo cargar el archivo! ¿Existe?', 0
	new_file_msg		db 'Introduzca un nuevo nombre de archivo:', 0
	file_save_fail_msg1	db 'No se pudo guardar el archivo!', 0
	file_save_fail_msg2	db '(Archivos multimedia de sólo escritura o mal nombre de archivo?)', 0
	file_save_succeed_msg	db 'Archivo guardado.', 0

	skiplines	dw 0

	cursor_x	db 0			; Posición del cursor fijada por el usuario
	cursor_y	db 0

	cursor_byte	dw 0		; Byte en los datos de archivo donde el cursor es

	last_byte	dw 0			; Ubicación en la memoria RAM del byte final en el archivo

	filename	times 32 db 0	
						; podría entrar en algo Daft
	filesize	dw 0
;Traducción Dúrval Córdova

; ------------------------------------------------------------------

