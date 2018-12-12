
%DEFINE VARIABLE 1
%DEFINE STRING_VAR 2
%DEFINE NUMBER 3
%DEFINE STRING 4
%DEFINE QUOTE 5
%DEFINE CHAR 6
%DEFINE UNKNOWN 7
%DEFINE LABEL 8


; ------------------------------------------------------------------
; 
;La ejecución del intérprete BASIC comienza aquí - una cadena de parámetros
; se pasa en SI y se copia en la primera cadena, a menos que SI = 0

os_run_basic:
	mov word [orig_stack], sp		; Guardar el puntero de la pila - podríamos saltar a la
						; Error al imprimir código y salir en el medio
						; Algunos bucles anidados, y queremos preservar
						; la pila

	mov word [load_point], ax		; AX se pasó como ubicación de inicio del código

	mov word [prog], ax			; prog = puntero al punto de ejecución actual en el código

	add bx, ax				; Se nos pasó el tamaño de byte .BAS en BX
	dec bx
	dec bx
	mov word [prog_end], bx			; Tome nota del punto final del programa


	call clear_ram				; Borrar variables, etc. de la ejecución anterior
						; de un programa basico

	cmp si, 0				; Pasó una cadena de parámetros?
	je mainloop

	mov di, string_vars			; Si es así, cópialo en $ 1
	call os_string_copy



mainloop:
	call get_token				; Consigue un token desde el inicio de la línea.

	cmp ax, STRING				; ¿Es el tipo una cadena de caracteres?
	je .keyword				; Si es así, vamos a ver si es una palabra clave para procesar

	cmp ax, VARIABLE			; Si es una variable al comienzo de la línea,
	je near assign				; esto es una asignación (por ejemplo, "X = Y + 5")

	cmp ax, STRING_VAR			; Lo mismo para una variable de cadena (por ejemplo, $ 1)
	je near assign

	cmp ax, LABEL				; No necesito hacer nada aquí - saltar
	je mainloop

	mov si, err_syntax			; De lo contrario, muestre un error y salga.
	jmp error


.keyword:
	mov si, token				; Comience tratando de hacer coincidir los comandos

	mov di, alert_cmd
	call os_string_compare
	jc near do_alert

	mov di, askfile_cmd
	call os_string_compare
	jc near do_askfile

	mov di, break_cmd
	call os_string_compare
	jc near do_break

	mov di, case_cmd
	call os_string_compare
	jc near do_case

	mov di, call_cmd
	call os_string_compare
	jc near do_call

	mov di, cls_cmd
	call os_string_compare
	jc near do_cls

	mov di, cursor_cmd
	call os_string_compare
	jc near do_cursor

	mov di, curschar_cmd
	call os_string_compare
	jc near do_curschar

	mov di, curscol_cmd
	call os_string_compare
	jc near do_curscol

	mov di, curspos_cmd
	call os_string_compare
	jc near do_curspos
	
	mov di, delete_cmd
	call os_string_compare
	jc near do_delete
	
	mov di, do_cmd
	call os_string_compare
	jc near do_do

	mov di, end_cmd
	call os_string_compare
	jc near do_end

	mov di, else_cmd
	call os_string_compare
	jc near do_else

	mov di, files_cmd
	call os_string_compare
	jc near do_files

	mov di, for_cmd
	call os_string_compare
	jc near do_for

	mov di, getkey_cmd
	call os_string_compare
	jc near do_getkey

	mov di, gosub_cmd
	call os_string_compare
	jc near do_gosub

	mov di, goto_cmd
	call os_string_compare
	jc near do_goto

	mov di, if_cmd
	call os_string_compare
	jc near do_if

	mov di, include_cmd
	call os_string_compare
	jc near do_include

	mov di, ink_cmd
	call os_string_compare
	jc near do_ink

	mov di, input_cmd
	call os_string_compare
	jc near do_input
	
	mov di, len_cmd
	call os_string_compare
	jc near do_len

	mov di, listbox_cmd
	call os_string_compare
	jc near do_listbox

	mov di, load_cmd
	call os_string_compare
	jc near do_load

	mov di, loop_cmd
	call os_string_compare
	jc near do_loop

	mov di, move_cmd
	call os_string_compare
	jc near do_move

	mov di, next_cmd
	call os_string_compare
	jc near do_next

	mov di, number_cmd
	call os_string_compare
	jc near do_number

	mov di, page_cmd
	call os_string_compare
	jc near do_page

	mov di, pause_cmd
	call os_string_compare
	jc near do_pause

	mov di, peek_cmd
	call os_string_compare
	jc near do_peek

	mov di, peekint_cmd
	call os_string_compare
	jc near do_peekint
	
	mov di, poke_cmd
	call os_string_compare
	jc near do_poke
	
	mov di, pokeint_cmd
	call os_string_compare
	jc near do_pokeint

	mov di, port_cmd
	call os_string_compare
	jc near do_port

	mov di, print_cmd
	call os_string_compare
	jc near do_print

	mov di, rand_cmd
	call os_string_compare
	jc near do_rand

	mov di, read_cmd
	call os_string_compare
	jc near do_read

	mov di, rem_cmd
	call os_string_compare
	jc near do_rem

	mov di, rename_cmd
	call os_string_compare
	jc near do_rename

	mov di, return_cmd
	call os_string_compare
	jc near do_return

	mov di, save_cmd
	call os_string_compare
	jc near do_save

	mov di, serial_cmd
	call os_string_compare
	jc near do_serial

	mov di, size_cmd
	call os_string_compare
	jc near do_size

	mov di, sound_cmd
	call os_string_compare
	jc near do_sound
	
	mov di, string_cmd
	call os_string_compare
	jc near do_string

	mov di, waitkey_cmd
	call os_string_compare
	jc near do_waitkey

	mov si, err_cmd_unknown			; ¿Comando no encontrado?
	jmp error


; ------------------------------------------------------------------
; Borrar la memoria

clear_ram:
	pusha
	mov al, 0

	mov di, variables
	mov cx, 52
	rep stosb

	mov di, for_variables
	mov cx, 52
	rep stosb

	mov di, for_code_points
	mov cx, 52
	rep stosb
	
	mov di, do_loop_store
	mov cx, 10
	rep stosb

	mov byte [gosub_depth], 0
	mov byte [loop_in], 0

	mov di, gosub_points
	mov cx, 20
	rep stosb

	mov di, string_vars
	mov cx, 1024
	rep stosb

	mov byte [ink_colour], 7		; Tinta blanca

	popa
	ret


; ------------------------------------------------------------------
; ASIGNACIÓN

assign:
	cmp ax, VARIABLE			; ¿Estamos empezando con un número var?
	je .do_num_var

	mov di, string_vars			; De lo contrario es una cadena var
	mov ax, 128
	mul bx					; (BX = número de cadena, devuelto desde get_token)
	add di, ax

	push di

	call get_token
	mov byte al, [token]
	cmp al, '='
	jne near .error

	call get_token				; A ver si segundo es una cita
	cmp ax, QUOTE
	je .second_is_quote

	cmp ax, STRING_VAR
	jne near .error

	mov si, string_vars			; De lo contrario es una cadena var
	mov ax, 128
	mul bx					; (BX = número de cadena, devuelto desde get_token)
	add si, ax

	pop di
	call os_string_copy

	jmp .string_check_for_more


.second_is_quote:
	mov si, token
	pop di
	call os_string_copy


.string_check_for_more:
	push di
	mov word ax, [prog]			; Guardar la ubicación del código en caso de que no haya delimitador
	mov word [.tmp_loc], ax

	call get_token				; ¿Alguna más para tratar en esta tarea?
	mov byte al, [token]
	cmp al, '+'
	je .string_theres_more

	mov word ax, [.tmp_loc]			; No es un delimitador, así que retrocede ante el token
	mov word [prog], ax			; que acabamos de agarrar

	pop di
	jmp mainloop				; ¡Y vuelve al intérprete de códigos!


.string_theres_more:
	call get_token
	cmp ax, STRING_VAR
	je .another_string_var
	cmp ax, QUOTE
	je .another_quote
	cmp ax, VARIABLE
	je .add_number_var
	jmp .error


.another_string_var:
	pop di

	mov si, string_vars
	mov ax, 128
	mul bx					; (BX = número de cadena, devuelto desde get_token)
	add si, ax

	mov ax, di
	mov cx, di
	mov bx, si
	call os_string_join

	jmp .string_check_for_more



.another_quote:
	pop di

	mov ax, di
	mov cx, di
	mov bx, token
	call os_string_join

	jmp .string_check_for_more


.add_number_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	call os_int_to_string

	mov bx, ax
	pop di
	mov ax, di
	mov cx, di
	call os_string_join

	jmp .string_check_for_more
	



.do_num_var:
	mov ax, 0
	mov byte al, [token]
	mov byte [.tmp], al

	call get_token
	mov byte al, [token]
	cmp al, '='
	jne near .error

	call get_token
	cmp ax, NUMBER
	je .second_is_num

	cmp ax, VARIABLE
	je .second_is_variable

	cmp ax, STRING
	je near .second_is_string

	cmp ax, UNKNOWN
	jne near .error

	mov byte al, [token]			; Dirección de la cadena var?
	cmp al, '&'
	jne near .error

	call get_token				; A ver si hay una cadena var
	cmp ax, STRING_VAR
	jne near .error

	mov di, string_vars
	mov ax, 128
	mul bx
	add di, ax

	mov bx, di

	mov byte al, [.tmp]
	call set_var

	jmp mainloop


.second_is_variable:
	mov ax, 0
	mov byte al, [token]

	call get_var
	mov bx, ax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more


.second_is_num:
	mov si, token
	call os_string_to_int

	mov bx, ax				; Número a insertar en tabla variable

	mov ax, 0
	mov byte al, [.tmp]

	call set_var


	; La asignación podría ser simplemente "X = 5", etc. O podría ser
	; "X = Y + 5" - es decir, más complicado. Así que aquí comprobamos si
	; hay un delimitador ...

.check_for_more:
	mov word ax, [prog]			; Guardar la ubicación del código en caso de que no haya delimitador
	mov word [.tmp_loc], ax

	call get_token				; ¿Alguna más para tratar en esta tarea?
	mov byte al, [token]
	cmp al, '+'
	je .theres_more
	cmp al, '-'
	je .theres_more
	cmp al, '*'
	je .theres_more
	cmp al, '/'
	je .theres_more
	cmp al, '%'
	je .theres_more

	mov word ax, [.tmp_loc]			; No es un delimitador, así que retrocede ante el token
	mov word [prog], ax			; que acabamos de agarrar

	jmp mainloop				; ¡Y vuelve al intérprete de códigos!


.theres_more:
	mov byte [.delim], al

	call get_token
	cmp ax, VARIABLE
	je .handle_variable

	mov si, token
	call os_string_to_int
	mov bx, ax

	mov ax, 0
	mov byte al, [.tmp]

	call get_var				; Esto también apunta a SI en el lugar correcto en la tabla variable

	cmp byte [.delim], '+'
	jne .not_plus

	add ax, bx
	jmp .finish

.not_plus:
	cmp byte [.delim], '-'
	jne .not_minus

	sub ax, bx
	jmp .finish

.not_minus:
	cmp byte [.delim], '*'
	jne .not_times

	mul bx
	jmp .finish

.not_times:
	cmp byte [.delim], '/'
	jne .not_divide

	cmp bx, 0
	je .divide_zero
	
	mov dx, 0
	div bx
	jmp .finish

.not_divide:
	mov dx, 0
	div bx
	mov ax, dx				; Obtener el resto

.finish:
	mov bx, ax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more

.divide_zero:
	mov si, err_divide_by_zero
	jmp error
	
.handle_variable:
	mov ax, 0
	mov byte al, [token]

	call get_var

	mov bx, ax

	mov ax, 0
	mov byte al, [.tmp]

	call get_var

	cmp byte [.delim], '+'
	jne .vnot_plus

	add ax, bx
	jmp .vfinish

.vnot_plus:
	cmp byte [.delim], '-'
	jne .vnot_minus

	sub ax, bx
	jmp .vfinish

.vnot_minus:
	cmp byte [.delim], '*'
	jne .vnot_times

	mul bx
	jmp .vfinish

.vnot_times:
	cmp byte [.delim], '/'
	jne .vnot_divide

	mov dx, 0
	div bx
	jmp .finish

.vnot_divide:
	mov dx, 0
	div bx
	mov ax, dx				; Obtener el resto
.vfinish:
	mov bx, ax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more


.second_is_string:				; Estas son funciones de "X = palabra"
	mov di, token
	
	mov si, ink_keyword
	call os_string_compare
	je .is_ink
	
	mov si, progstart_keyword
	call os_string_compare
	je .is_progstart

	mov si, ramstart_keyword
	call os_string_compare
	je .is_ramstart

	mov si, timer_keyword
	call os_string_compare
	je .is_timer
	
	mov si, variables_keyword
	call os_string_compare
	je .is_variables
	
	mov si, version_keyword
	call os_string_compare
	je .is_version

	jmp .error


.is_ink:
	mov ax, 0
	mov byte al, [.tmp]
	
	mov bx, 0
	mov byte bl, [ink_colour]
	call set_var
	
	jmp mainloop


.is_progstart:
	mov ax, 0
	mov byte al, [.tmp]

	mov word bx, [load_point]
	call set_var

	jmp mainloop


.is_ramstart:
	mov ax, 0
	mov byte al, [.tmp]

	mov word bx, [prog_end]
	inc bx
	inc bx
	inc bx
	call set_var

	jmp mainloop


.is_timer:
	mov ah, 0
	int 1Ah
	mov bx, dx

	mov ax, 0
	mov byte al, [.tmp]
	call set_var

	jmp mainloop


.is_variables:
	mov bx, vars_loc
	mov ax, 0
	mov byte al, [.tmp]
	call set_var

	jmp mainloop


.is_version:
	call os_get_api_version
	
	mov bh, 0
	mov bl, al
	mov al, [.tmp]
	call set_var
	
	jmp mainloop 


.error:
	mov si, err_syntax
	jmp error


	.tmp		db 0
	.tmp_loc	dw 0
	.delim		db 0


; ==================================================================
; EL CÓDIGO DE COMANDO ESPECÍFICO COMIENZA AQUÍ

; ------------------------------------------------------------------
; ALERTA
do_alert:
	mov bh, [work_page]			; Almacenar la posición del cursor
	mov ah, 03h
	int 10h

	call get_token

	cmp ax, QUOTE
	je .is_quote
	
	cmp ax, STRING_VAR
	je .is_string

	mov si, err_syntax
	jmp error

.is_string:
	mov si, string_vars
	mov ax, 128
	mul bx
	add ax, si
	jmp .display_message
	
.is_quote:
	mov ax, token				; Primera cadena para el cuadro de alerta
	
.display_message:
	mov bx, 0				; Otros estan en blanco
	mov cx, 0
	mov dx, 0				; Caja de una eleccion
	call os_dialog_box
	
	mov bh, [work_page]			; Mover el cursor hacia atras
	mov ah, 02h
	int 10h
	
	jmp mainloop


;-------------------------------------------------------------------
; ASKFILE

do_askfile:
	mov bh, [work_page]			; Almacenar la posición del cursor
	mov ah, 03h
	int 10h
	
	call get_token
	
	cmp ax, STRING_VAR
	jne .error
	
	mov si, string_vars			; Obtener la ubicación de la cadena
	mov ax, 128
	mul bx
	add ax, si
	mov word [.tmp], ax
	
	call os_file_selector			; Presentar el selector
	
	mov word di, [.tmp]			; Copia la cadena
	mov si, ax
	call os_string_copy

	mov bh, [work_page]			; Mover el cursor hacia atras
	mov ah, 02h
	int 10h
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error

.data:
	.tmp					dw 0


; ------------------------------------------------------------------
; DESCANSO

do_break:
	mov si, err_break
	jmp error


; ------------------------------------------------------------------
; LLAMADA

do_call:
	call get_token
	cmp ax, NUMBER
	je .is_number

	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .execute_call

.is_number:
	mov si, token
	call os_string_to_int

.execute_call:
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov di, 0
	mov si, 0

	call ax

	jmp mainloop


; ------------------------------------------------------------------
; CASO

do_case:
	call get_token
	cmp ax, STRING
	jne .error
	
	mov si, token

	mov di, upper_keyword
	call os_string_compare
	jc .uppercase
	
	mov di, lower_keyword
	call os_string_compare
	jc .lowercase
	
	jmp .error
	
.uppercase:
	call get_token
	cmp ax, STRING_VAR
	jne .error
	
	mov si, string_vars
	mov ax, 128
	mul bx
	add ax, si
	
	call os_string_uppercase
	
	jmp mainloop
	
.lowercase:
	call get_token
	cmp ax, STRING_VAR
	jne .error
	
	mov si, string_vars
	mov ax, 128
	mul bx
	add ax, si
	
	call os_string_lowercase
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; CLS

do_cls:
	mov ah, 5
	mov byte al, [work_page]
	int 10h

	call os_clear_screen

	mov ah, 5
	mov byte al, [disp_page]
	int 10h

	jmp mainloop



; ------------------------------------------------------------------
; CURSOR

do_cursor:
	call get_token

	mov si, token
	mov di, .on_str
	call os_string_compare
	jc .turn_on

	mov si, token
	mov di, .off_str
	call os_string_compare
	jc .turn_off

	mov si, err_syntax
	jmp error

.turn_on:
	call os_show_cursor
	jmp mainloop

.turn_off:
	call os_hide_cursor
	jmp mainloop


	.on_str db "ON", 0
	.off_str db "OFF", 0


; ------------------------------------------------------------------
; CURSCHAR

do_curschar:
	call get_token

	cmp ax, VARIABLE
	je .is_variable

	mov si, err_syntax
	jmp error

.is_variable:
	mov ax, 0
	mov byte al, [token]

	push ax				; Store variable we're going to use

	mov ah, 08h
	mov bx, 0
	mov byte bh, [work_page]
	int 10h				; Get char at current cursor location

	mov bx, 0			; We only want the lower byte (the char, not attribute)
	mov bl, al

	pop ax				; Get the variable back

	call set_var			; And store the value

	jmp mainloop


; ------------------------------------------------------------------
; CURSCOL

do_curscol:
	call get_token

	cmp ax, VARIABLE
	jne .error

	mov ah, 0
	mov byte al, [token]
	push ax

	mov ah, 8
	mov bx, 0
	mov byte bh, [work_page]
	int 10h
	mov bh, 0
	mov bl, ah			; Get colour for higher byte; ignore lower byte (char)

	pop ax
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; CURSPOS

do_curspos:
	mov byte bh, [work_page]
	mov ah, 3
	int 10h

	call get_token
	cmp ax, VARIABLE
	jne .error

	mov ah, 0			; Get the column in the first variable
	mov byte al, [token]
	mov bx, 0
	mov bl, dl
	call set_var

	call get_token
	cmp ax, VARIABLE
	jne .error

	mov ah, 0			; Get the row to the second
	mov byte al, [token]
	mov bx, 0
	mov bl, dh
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; BORRAR

do_delete:
	call get_token
	cmp ax, QUOTE
	je .is_quote

	cmp ax, STRING_VAR
	jne near .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	jmp .get_filename

.is_quote:
	mov si, token

.get_filename:
	mov ax, si
	call os_file_exists
	jc .no_file

	call os_remove_file
	jc .del_fail

	jmp .returngood

.no_file:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 2
	call set_var
	jmp mainloop

.returngood:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 0
	call set_var
	jmp mainloop

.del_fail:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 1
	call set_var
	jmp mainloop

.error:
	mov si, err_syntax
	jmp error
	

; ------------------------------------------------------------------
; DO

do_do:
	cmp byte [loop_in], 20
	je .loop_max
	mov word di, do_loop_store
	mov byte al, [loop_in]
	mov ah, 0
	add di, ax
	mov word ax, [prog]
	sub ax, 3
	stosw
	inc byte [loop_in]
	inc byte [loop_in]
	jmp mainloop

.loop_max:
	mov si, err_doloop_maximum
	jmp error

	
;-------------------------------------------------------------------
; MÁS

do_else:
	cmp byte [last_if_true], 1
	je .last_true
	
	inc word [prog]
	jmp mainloop
	
.last_true:
	mov word si, [prog]
	
.next_line:
	lodsb
	cmp al, 10
	jne .next_line
	
	dec si
	mov word [prog], si
	
	jmp mainloop


; ------------------------------------------------------------------
; FIN

do_end:
	mov ah, 5				; Restaurar página activa
	mov al, 0
	int 10h

	mov byte [work_page], 0
	mov byte [disp_page], 0

	mov word sp, [orig_stack]
	ret


; ------------------------------------------------------------------
; FILES

do_files:
	mov ax, .filelist			; obtener una copia de la lista de archivos
	call os_get_file_list
	
	mov si, ax

	call os_get_cursor_pos			; mover el cursor al inicio de linea
	mov dl, 0
	call os_move_cursor
	
	mov ah, 9				; función de imprimir caracteres
	mov bh, [work_page]			; Definir parámetros (página, color, tiempos).
	mov bl, [ink_colour]
	mov cx, 1
.file_list_loop:
	lodsb					; obtener un byte de la lista
	cmp al, ','				; una coma significa el siguiente archivo, así que cree una nueva línea para él
	je .nextfile
	
	cmp al, 0				; la lista está terminada en nulo
	je .end_of_list
	
	int 10h					; está bien, no es una coma o un nulo, así que imprímelo

	call os_get_cursor_pos			; encontrar la ubicación del cursor
	inc dl					; mover el cursor hacia adelante
	call os_move_cursor

	jmp .file_list_loop			; sigue hasta que la lista termine
	
.nextfile:
	call os_get_cursor_pos			; Si la columna es más de 60 necesitamos una nueva línea.
	cmp dl, 60
	jge .newline

.next_column:					; imprimir espacios hasta la siguiente columna
	mov al, ' '
	int 10h
	
	inc dl
	call os_move_cursor
	
	cmp dl, 15
	je .file_list_loop
	
	cmp dl, 30
	je .file_list_loop
	
	cmp dl, 45
	je .file_list_loop
	
	cmp dl, 60
	je .file_list_loop
	
	jmp .next_column
	
.newline:
	call os_print_newline			; crear una nueva línea
	jmp .file_list_loop
	
.end_of_list:
	call os_print_newline
	jmp mainloop				; preforma siguiente comando
.data:
	.filelist		times 256	db 0
	


; ------------------------------------------------------------------
; FOR

do_for:
	call get_token				; Obtén la variable que estamos usando en este bucle

	cmp ax, VARIABLE
	jne near .error

	mov ax, 0
	mov byte al, [token]
	mov byte [.tmp_var], al			; Guárdalo en un lugar temporal por ahora.

	call get_token

	mov ax, 0				; Comprueba que está seguido con '='
	mov byte al, [token]
	cmp al, '='
	jne .error

	call get_token				; A continuación queremos un número.

	cmp ax, VARIABLE
	je .first_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token				; Convertirlo
	call os_string_to_int
	jmp .continue

.first_is_var:
	mov ax, 0				; Es una variable, así que consigue su valor.
	mov al, [token]
	call get_var
	
	; En esta etapa, hemos leído algo como "PARA X = 1"
	; Así que vamos a almacenar ese 1 en la tabla de variables

.continue:
	mov bx, ax
	mov ax, 0
	mov byte al, [.tmp_var]
	call set_var


	call get_token				; A continuación estamos buscando "A"

	cmp ax, STRING
	jne .error

	mov ax, token
	call os_string_uppercase

	mov si, token
	mov di, .to_string
	call os_string_compare
	jnc .error


	; So now we're at "FOR X = 1 TO"

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

.second_is_number:
	mov si, token					; Obtener el número de destino
	call os_string_to_int
	jmp .continue2

.second_is_var:
	mov ax, 0				; Es una variable, así que consigue su valor.
	mov al, [token]
	call get_var

.continue2:
	mov bx, ax

	mov ax, 0
	mov byte al, [.tmp_var]

	sub al, 65					; Almacenar el número de destino en la tabla
	mov di, for_variables
	add di, ax
	add di, ax
	mov ax, bx
	stosw


	; Así que tenemos la variable, le asignamos el número inicial y la colocamos en
	; Nuestra mesa el límite que debe alcanzar. Pero también tenemos que almacenar el punto en
	; código después de la línea FOR a la que deberíamos volver si NEXT X no completa el ciclo ...

	mov ax, 0
	mov byte al, [.tmp_var]

	sub al, 65					; Guarde la posición del código para volver a la tabla.
	mov di, for_code_points
	add di, ax
	add di, ax
	mov word ax, [prog]
	stosw

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


	.tmp_var	db 0
	.to_string	db 'TO', 0


; ------------------------------------------------------------------
; OBTENER LA CLAVE

do_getkey:
	call get_token
	cmp ax, VARIABLE
	je .is_variable

	mov si, err_syntax
	jmp error

.is_variable:
	mov ax, 0
	mov byte al, [token]

	push ax

	call os_check_for_key

	cmp ax, 48E0h
	je .up_pressed

	cmp ax, 50E0h
	je .down_pressed

	cmp ax, 4BE0h
	je .left_pressed

	cmp ax, 4DE0h
	je .right_pressed

.store:	
	mov bx, 0
	mov bl, al
	
	pop ax

	call set_var

	jmp mainloop

.up_pressed:
	mov ax, 1
	jmp .store

.down_pressed:
	mov ax, 2
	jmp .store

.left_pressed:
	mov ax, 3
	jmp .store

.right_pressed:
	mov ax, 4
	jmp .store

; ------------------------------------------------------------------
; GOSUB

do_gosub:
	call get_token				; Obtener el número (etiqueta)

	cmp ax, STRING
	je .is_ok

	mov si, err_goto_notlabel
	jmp error

.is_ok:
	mov si, token				; Copia de seguridad de esta etiqueta
	mov di, .tmp_token
	call os_string_copy

	mov ax, .tmp_token
	call os_string_length

	mov di, .tmp_token			; Agregue ':' char para finalizar la búsqueda
	add di, ax
	mov al, ':'
	stosb
	mov al, 0
	stosb	


	inc byte [gosub_depth]

	mov ax, 0
	mov byte al, [gosub_depth]		; Obtener el nivel de nido GOSUB actual

	cmp al, 9
	jle .within_limit

	mov si, err_nest_limit
	jmp error


.within_limit:
	mov di, gosub_points			; Pasa a nuestra tabla de punteros.
	add di, ax				; Tabla es palabras (no bytes)
	add di, ax
	mov word ax, [prog]
	stosw					; Almacena la ubicación actual antes de saltar


	mov word ax, [load_point]
	mov word [prog], ax			; Volver al inicio del programa para encontrar la etiqueta.

.loop:
	call get_token

	cmp ax, LABEL
	jne .line_loop

	mov si, token
	mov di, .tmp_token
	call os_string_compare
	jc mainloop


.line_loop:					; Ir al final de la línea
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	cmp al, 10
	jne .line_loop

	mov word ax, [prog]
	mov word bx, [prog_end]
	cmp ax, bx
	jg .past_end

	jmp .loop


.past_end:
	mov si, err_label_notfound
	jmp error


	.tmp_token	times 30 db 0


; ------------------------------------------------------------------
; GOTO

do_goto:
	call get_token				; Consigue el siguiente token

	cmp ax, STRING
	je .is_ok

	mov si, err_goto_notlabel
	jmp error

.is_ok:
	mov si, token				; Copia de seguridad de esta etiqueta
	mov di, .tmp_token
	call os_string_copy

	mov ax, .tmp_token
	call os_string_length

	mov di, .tmp_token			; Agregue ':' char para finalizar la búsqueda
	add di, ax
	mov al, ':'
	stosb
	mov al, 0
	stosb	

	mov word ax, [load_point]
	mov word [prog], ax			; Volver al inicio del programa para encontrar la etiqueta.

.loop:
	call get_token

	cmp ax, LABEL
	jne .line_loop

	mov si, token
	mov di, .tmp_token
	call os_string_compare
	jc mainloop

.line_loop:					; Ir al final de la línea
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]

	cmp al, 10
	jne .line_loop

	mov word ax, [prog]
	mov word bx, [prog_end]
	cmp ax, bx
	jg .past_end

	jmp .loop

.past_end:
	mov si, err_label_notfound
	jmp error


	.tmp_token 	times 30 db 0


; ------------------------------------------------------------------
; IF

do_if:
	call get_token

	cmp ax, VARIABLE			; Si solo puede ser seguido por una variable
	je .num_var

	cmp ax, STRING_VAR
	je near .string_var

	mov si, err_syntax
	jmp error

.num_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	mov dx, ax				; Almacenar el valor de la primera parte de la comparación.

	call get_token				; Conseguir el delimitador
	mov byte al, [token]
	cmp al, '='
	je .equals
	cmp al, '>'
	je .greater
	cmp al, '<'
	je .less

	mov si, err_syntax			; Si no es uno de los anteriores, error de salida.
	jmp error

.equals:
	call get_token				; ¿Es esto 'X = Y' (es igual a otra variable?)

	cmp ax, CHAR
	je .equals_char

	mov byte al, [token]
	call is_letter
	jc .equals_var

	mov si, token				; De lo contrario es, por ejemplo, 'X = 1' (un número)
	call os_string_to_int

	cmp ax, dx				; En el bit THEN si 'X = num' coincide
	je near .on_to_then

	jmp .finish_line			; De lo contrario salta el resto de la línea.


.equals_char:
	mov ax, 0
	mov byte al, [token]

	cmp ax, dx
	je near .on_to_then

	jmp .finish_line


.equals_var:
	mov ax, 0
	mov byte al, [token]

	call get_var

	cmp ax, dx				; ¿Las variables coinciden?
	je near .on_to_then				; En la parte posterior, si es así

	jmp .finish_line			; De lo contrario salta el resto de la línea.


.greater:
	call get_token				; ¿Mayor que una variable o un número?
	mov byte al, [token]
	call is_letter
	jc .greater_var

	mov si, token				; Debe ser un número aquí ...
	call os_string_to_int

	cmp ax, dx
	jl near .on_to_then

	jmp .finish_line

.greater_var:					; Variable en este caso
	mov ax, 0
	mov byte al, [token]

	call get_var

	cmp ax, dx				; ¡Haz la comparación!
	jl .on_to_then

	jmp .finish_line

.less:
	call get_token
	mov byte al, [token]
	call is_letter
	jc .less_var

	mov si, token
	call os_string_to_int

	cmp ax, dx
	jg .on_to_then

	jmp .finish_line

.less_var:
	mov ax, 0
	mov byte al, [token]

	call get_var

	cmp ax, dx
	jg .on_to_then

	jmp .finish_line



.string_var:
	mov byte [.tmp_string_var], bl

	call get_token

	mov byte al, [token]
	cmp al, '='
	jne .error

	call get_token
	cmp ax, STRING_VAR
	je .second_is_string_var

	cmp ax, QUOTE
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	mov di, token
	call os_string_compare
	je .on_to_then

	jmp .finish_line


.second_is_string_var:
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov di, string_vars
	mov bx, 0
	mov byte bl, [.tmp_string_var]
	mov ax, 128
	mul bx
	add di, ax

	call os_string_compare
	jc .on_to_then

	jmp .finish_line


.on_to_then:
	call get_token

	mov si, token			; Busque Y para más comparación
	mov di, and_keyword
	call os_string_compare
	jc do_if

	mov si, token			; Busca ENTONCES para realizar más operaciones
	mov di, then_keyword
	call os_string_compare
	jc .then_present

	mov si, err_syntax
	jmp error

.then_present:				; ¡Continúa el resto de la línea como cualquier otro comando!
	mov byte [last_if_true], 1
	jmp mainloop


.finish_line:				; SI no se cumplió, así que salta el resto de la línea
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	cmp al, 10
	jne .finish_line

	mov byte [last_if_true], 0
	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


	.tmp_string_var		db 0


; ------------------------------------------------------------------
; INCLUDE

do_include:
	call get_token
	cmp ax, QUOTE
	je .is_ok

	mov si, err_syntax
	jmp error

.is_ok:
	mov ax, token
	mov word cx, [prog_end]
	inc cx				; Agrega un poco de espacio después del código original
	inc cx
	inc cx
	push cx
	call os_load_file
	jc .load_fail

	pop cx
	add cx, bx
	mov word [prog_end], cx

	jmp mainloop


.load_fail:
	pop cx
	mov si, err_file_notfound
	jmp error


; ------------------------------------------------------------------
; INK

do_ink:
	call get_token				; Obtener columna

	cmp ax, VARIABLE
	je .first_is_var

	mov si, token
	call os_string_to_int
	mov byte [ink_colour], al
	jmp mainloop

.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	mov byte [ink_colour], al
	jmp mainloop


; ------------------------------------------------------------------
; INPUT

do_input:
	mov al, 0				; Borrar cadena de uso anterior
	mov di, .tmpstring
	mov cx, 128
	rep stosb

	call get_token

	cmp ax, VARIABLE			; Solo podemos ENTRAR a variables!
	je .number_var

	cmp ax, STRING_VAR
	je .string_var

	mov si, err_syntax
	jmp error

.number_var:
	mov ax, .tmpstring			; Obtener información del usuario.
	call os_input_string

	mov ax, .tmpstring
	call os_string_length
	cmp ax, 0
	jne .char_entered

	mov byte [.tmpstring], '0'		; Si ingresa hit, complete la variable con cero
	mov byte [.tmpstring + 1], 0

.char_entered:
	mov si, .tmpstring			; Convertir a formato entero
	call os_string_to_int
	mov bx, ax

	mov ax, 0
	mov byte al, [token]			; Obtén la variable donde la estamos almacenando ...
	call set_var				; ... y guárdalo!

	call os_print_newline

	jmp mainloop


.string_var:
	push bx

	mov ax, .tmpstring
	call os_input_string

	mov si, .tmpstring
	mov di, string_vars

	pop bx

	mov ax, 128
	mul bx

	add di, ax
	call os_string_copy

	call os_print_newline

	jmp mainloop


	.tmpstring	times 128 db 0


; -----------------------------------------------------------
; LEN

do_len:
	call get_token
	cmp ax, STRING_VAR
	jne .error
 
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov ax, si
	call os_string_length
	mov word [.num1], ax

	call get_token
	cmp ax, VARIABLE
	je .is_ok
	
	mov si, err_syntax
	jmp error

.is_ok:
	mov ax, 0
	mov byte al, [token]
	mov bl, al
	jmp .finish

.finish:	
	mov bx, [.num1]
	mov byte al, [token]
	call set_var
	mov ax, 0
	jmp mainloop
 
.error:
	mov si, err_syntax
	jmp error


	.num1 dw 0


; ------------------------------------------------------------------
; LISTBOX

do_listbox:
	mov bh, [work_page]			; Almacenar la posición del cursor
	mov ah, 03h
	int 10h
	
	call get_token
	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov word [.s1], si

	call get_token
	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov word [.s2], si

	call get_token
	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov word [.s3], si


	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte al, [token]
	mov byte [.var], al

	mov word ax, [.s1]
	mov word bx, [.s2]
	mov word cx, [.s3]

	call os_list_dialog
	jc .esc_pressed

	pusha
	mov bh, [work_page]			; Mover el cursor hacia atras
	mov ah, 02h
	int 10h
	popa

	mov bx, ax
	mov ax, 0
	mov byte al, [.var]
	call set_var

	jmp mainloop


.esc_pressed:
	mov ax, 0
	mov byte al, [.var]
	mov bx, 0
	call set_var
	jmp mainloop


.error:
	mov si, err_syntax
	jmp error

	.s1 dw 0
	.s2 dw 0
	.s3 dw 0
	.var db 0


; ------------------------------------------------------------------
; LOAD

do_load:
	call get_token
	cmp ax, QUOTE
	je .is_quote

	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	jmp .get_position

.is_quote:
	mov si, token

.get_position:
	mov ax, si
	call os_file_exists
	jc .file_not_exists

	mov dx, ax			; Tienda por ahora

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.load_part:
	mov cx, ax

	mov ax, dx

	call os_load_file

	mov ax, 0
	mov byte al, 'S'
	call set_var

	mov ax, 0
	mov byte al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop


.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .load_part


.file_not_exists:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 1
	call set_var

	call get_token				; Saltar más allá del punto de carga - innecesario ahora

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; LOOP

do_loop:
	cmp byte [loop_in], 0
	je .no_do

	dec byte [loop_in]
	dec byte [loop_in]

	mov dx, 0

	call get_token
	mov di, token
	
	mov si, .endless_word
	call os_string_compare
	jc .loop_back
	
	mov si, .while_word
	call os_string_compare
	jc .while_set
	
	mov si, .until_word
	call os_string_compare
	jnc .error
	
.get_first_var:
	call get_token
	cmp ax, VARIABLE
	jne .error
	
	mov al, [token]
	call get_var
	mov cx, ax
	
.check_equals:
	call get_token
	cmp ax, UNKNOWN
	jne .error

	mov ax, [token]
	cmp al, '='
	je .sign_ok
	cmp al, '>'
	je .sign_ok
	cmp al, '<'
	je .sign_ok
	jmp .error
	.sign_ok:
	mov byte [.sign], al
	
.get_second_var:
 	call get_token

	cmp ax, NUMBER
	je .second_is_num

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, CHAR
	jne .error

.second_is_char:
	mov ah, 0
	mov al, [token]
	jmp .check_true
	
.second_is_var:
	mov al, [token]
	call get_var
	jmp .check_true
	
.second_is_num:
	mov si, token
	call os_string_to_int
	
.check_true:
	mov byte bl, [.sign]
	cmp bl, '='
	je .sign_equals
	
	cmp bl, '>'
	je .sign_greater
	
	jmp .sign_lesser
	
.sign_equals:
	cmp ax, cx
	jne .false
	jmp .true
	
.sign_greater:
	cmp ax, cx
	jge .false
	jmp .true
	
.sign_lesser:
	cmp ax, cx
	jle .false
	jmp .true
.true:
	cmp dx, 1
	je .loop_back
	jmp mainloop
.false:
	cmp dx, 1
	je mainloop
	
.loop_back:	
	mov word si, do_loop_store
	mov byte al, [loop_in]
	mov ah, 0
	add si, ax
	lodsw
	mov word [prog], ax
	jmp mainloop
	
.while_set:
	mov dx, 1
	jmp .get_first_var
	
.no_do:
	mov si, err_loop
	jmp error

.error:
	mov si, err_syntax
	jmp error
	
.data:
	.while_word			db "WHILE", 0
	.until_word			db "UNTIL", 0
	.endless_word			db "ENDLESS", 0
	.sign				db 0
	
	
; ------------------------------------------------------------------
; MOVE

do_move:
	call get_token

	cmp ax, VARIABLE
	je .first_is_var

	mov si, token
	call os_string_to_int
	mov dl, al
	jmp .onto_second

.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	mov dl, al

.onto_second:
	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	mov si, token
	call os_string_to_int
	mov dh, al
	jmp .finish

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	mov dh, al

.finish:
	mov byte bh, [work_page]
	mov ah, 2
	int 10h

	jmp mainloop


; ------------------------------------------------------------------
; NEXT

do_next:
	call get_token

	cmp ax, VARIABLE			; SIGUIENTE debe ir seguido de una variable
	jne .error

	mov ax, 0
	mov byte al, [token]
	call get_var

	inc ax					; SIGUIENTE incrementa la variable, por supuesto!

	mov bx, ax

	mov ax, 0
	mov byte al, [token]

	sub al, 65
	mov si, for_variables
	add si, ax
	add si, ax
	lodsw					; Obtener el número de destino de la tabla

	inc ax					; (Hacer el bucle incluido el número de destino)
	cmp ax, bx				; ¿Coinciden la variable y el objetivo?
	je .loop_finished

	mov ax, 0				; Si no, almacena la variable actualizada
	mov byte al, [token]
	call set_var

	mov ax, 0				; Encuentra el punto de código y vuelve
	mov byte al, [token]
	sub al, 65
	mov si, for_code_points
	add si, ax
	add si, ax
	lodsw

	mov word [prog], ax
	jmp mainloop


.loop_finished:
	jmp mainloop

.error:
	mov si, err_syntax
	jmp error



;-------------------------------------------------------------------
; NUMBER

do_number:
	call get_token			; Compruebe si es cadena a número, o número a cadena

	cmp ax, STRING_VAR
	je .is_string

	cmp ax, VARIABLE
	je .is_variable

	jmp .error

.is_string:

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	mov [.tmp], si

	call get_token

	mov si, [.tmp]

	cmp ax, VARIABLE
	jne .error

	call os_string_to_int
	mov bx, ax

	mov ax, 0
	mov byte al, [token]
	call set_var

	jmp mainloop

.is_variable:

	mov ax, 0			; Obtener el valor del número
	mov byte al, [token]
	call get_var

	call os_int_to_string		; Convertir a una cadena
	mov [.tmp], ax

	call get_token			; Consigue el segundo parámetro

	mov si, [.tmp]

	cmp ax, STRING_VAR		; Asegúrate de que sea una variable de cadena
	jne .error

	mov di, string_vars		; Localizar variable de cadena
	mov ax, 128
	mul bx
	add di, ax

	call os_string_copy		; Guardar cadena convertida

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error


	.tmp		dw 	0


;-------------------------------------------------------------------
; PAGE

do_page:
	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov byte [work_page], al	; Establecer la variable de la página de trabajo

	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov byte [disp_page], al	; Establecer la variable de la página de visualización

	; Change display page -- AL should already be present from the os_string_to_int
	mov ah, 5
	int 10h

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; PAUSE

do_pause:
	call get_token

	cmp ax, VARIABLE
	je .is_var

	mov si, token
	call os_string_to_int
	jmp .finish

.is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

.finish:
	call os_pause
	jmp mainloop


; ------------------------------------------------------------------
; PEEK

do_peek:
	call get_token

	cmp ax, VARIABLE
	jne .error

	mov ax, 0
	mov byte al, [token]
	mov byte [.tmp_var], al

	call get_token

	cmp ax, VARIABLE
	je .dereference

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.store:
	mov si, ax
	mov bx, 0
	mov byte bl, [si]
	mov ax, 0
	mov byte al, [.tmp_var]
	call set_var

	jmp mainloop

.dereference:
	mov byte al, [token]
	call get_var
	jmp .store

.error:
	mov si, err_syntax
	jmp error


	.tmp_var	db 0
	
	
	
; ------------------------------------------------------------------
; PEEKINT

do_peekint:
	call get_token
	
	cmp ax, VARIABLE
	jne .error

.get_second:
	mov al, [token]
	mov cx, ax
	
	call get_token
	
	cmp ax, VARIABLE
	je .address_is_var
	
	cmp ax, NUMBER
	jne .error
	
.address_is_number:
	mov si, token
	call os_string_to_int
	jmp .load_data
	
.address_is_var:
	mov al, [token]
	call get_var
	
.load_data:
	mov si, ax
	mov bx, [si]
	mov ax, cx
	call set_var
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error



; ------------------------------------------------------------------
; POKE

do_poke:
	call get_token

	cmp ax, VARIABLE
	je .first_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

	cmp ax, 255
	jg .error

	mov byte [.first_value], al
	jmp .onto_second


.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	mov byte [.first_value], al

.onto_second:
	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.got_value:
	mov di, ax
	mov ax, 0
	mov byte al, [.first_value]
	mov byte [di], al

	jmp mainloop

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .got_value

.error:
	mov si, err_syntax
	jmp error


	.first_value	db 0




; ------------------------------------------------------------------
; POKEINT

do_pokeint:
	call get_token
	
	cmp ax, VARIABLE
	je .data_is_var
	
	cmp ax, NUMBER
	jne .error

.data_is_num:
	mov si, token
	call os_string_to_int
	jmp .get_second
	
.data_is_var:
	mov al, [token]
	call get_var
	
.get_second:
	mov cx, ax
	
	call get_token
	
	cmp ax, VARIABLE
	je .address_is_var
	
	cmp ax, NUMBER
	jne .error
	
.address_is_num:
	mov si, token
	call os_string_to_int
	jmp .save_data
	
.address_is_var:
	mov al, [token]
	call get_var
	
.save_data:
	mov si, ax
	mov [si], cx
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error




; ------------------------------------------------------------------
; PORT

do_port:
	call get_token
	mov si, token

	mov di, .out_cmd
	call os_string_compare
	jc .do_out_cmd

	mov di, .in_cmd
	call os_string_compare
	jc .do_in_cmd

	jmp .error


.do_out_cmd:
	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int		; Ahora AX = número de puerto
	mov dx, ax

	call get_token
	cmp ax, NUMBER
	je .out_is_num

	cmp ax, VARIABLE
	je .out_is_var

	jmp .error

.out_is_num:
	mov si, token
	call os_string_to_int
	call os_port_byte_out
	jmp mainloop

.out_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	call os_port_byte_out
	jmp mainloop


.do_in_cmd:
	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov dx, ax

	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte cl, [token]

	call os_port_byte_in
	mov bx, 0
	mov bl, al

	mov al, cl
	call set_var

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


	.out_cmd	db "OUT", 0
	.in_cmd		db "IN", 0


; ------------------------------------------------------------------
; PRINT

do_print:
	call get_token				; Obtener parte después de IMPRIMIR
	cmp ax, QUOTE				; De que tipo es
	je .print_quote

	cmp ax, VARIABLE			; Variable numérica (ej. X)
	je .print_var

	cmp ax, STRING_VAR			; Variable de cadena (por ejemplo, $ 1)
	je .print_string_var

	cmp ax, STRING				; Palabra clave especial (por ejemplo, CHR o HEX)
	je .print_keyword

	mov si, err_print_type			; Sólo imprimimos cadenas y vars entre comillas!
	jmp error


.print_var:
	mov ax, 0
	mov byte al, [token]
	call get_var				; Obtener su valor

	call os_int_to_string			; Convertir a cadena
	mov si, ax
	call os_print_string

	jmp .newline_or_not


.print_quote:					; Si es texto citado, imprímelo.
	mov si, token
.print_quote_loop:
	lodsb
	cmp al, 0
	je .newline_or_not

	mov ah, 09h
	mov byte bl, [ink_colour]
	mov byte bh, [work_page]
	mov cx, 1
	int 10h

	mov ah, 3
	int 10h

	cmp dl, 79
	jge .quote_newline
	inc dl

.move_cur_quote:
	mov byte bh, [work_page]
	mov ah, 02h
	int 10h
	jmp .print_quote_loop


.quote_newline:
	cmp dh, 24
	je .move_cur_quote
	mov dl, 0
	inc dh
	jmp .move_cur_quote

.print_string_var:
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	jmp .print_quote_loop


.print_keyword:
	mov si, token
	mov di, chr_keyword
	call os_string_compare
	jc .is_chr

	mov di, hex_keyword
	call os_string_compare
	jc .is_hex

	mov si, err_syntax
	jmp error

.is_chr:
	call get_token

	cmp ax, VARIABLE
	je .is_chr_variable
	
	cmp ax, NUMBER
	je .is_chr_number

.is_chr_variable:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .print_chr
	
.is_chr_number:
	mov si, token
	call os_string_to_int

.print_chr:
	mov ah, 09h
	mov byte bl, [ink_colour]
	mov byte bh, [work_page]
	mov cx, 1
	int 10h

	mov ah, 3		; Mover el cursor hacia adelante
	int 10h
	inc dl
	cmp dl, 79
	jg .end_line		; Si está sobre el final de la línea
.move_cur:
	mov ah, 2
	int 10h

	jmp .newline_or_not


.is_hex:
	call get_token

	cmp ax, VARIABLE
	jne .error

	mov ax, 0
	mov byte al, [token]
	call get_var

	call os_print_2hex

	jmp .newline_or_not

.end_line:
	mov dl, 0
	inc dh
	cmp dh, 25
	jl .move_cur
	mov dh, 24
	mov dl, 79
	jmp .move_cur

.error:
	mov si, err_syntax
	jmp error
	


.newline_or_not:
	; Queremos ver si el comando termina con ';' -- Lo que significa que
	; No debemos imprimir una nueva línea después de que termine. Así que almacenamos el
	; la ubicación actual del programa para saltar por delante y ver si hay el ';'
	; personaje - de lo contrario, volvemos a poner la ubicación del programa y reanudamos
	; el bucle principal
	mov word ax, [prog]
	mov word [.tmp_loc], ax

	call get_token
	cmp ax, UNKNOWN
	jne .ignore

	mov ax, 0
	mov al, [token]
	cmp al, ';'
	jne .ignore

	jmp mainloop				; ¡Y vuelve a interpretar el código!

.ignore:
	mov ah, 5
	mov al, [work_page]
	int 10h

	mov bh, [work_page]
	call os_print_newline

	mov ah, 5
	mov al, [disp_page]

	mov word ax, [.tmp_loc]
	mov word [prog], ax

	jmp mainloop


	.tmp_loc	dw 0


; ------------------------------------------------------------------
; RAND

do_rand:
	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte al, [token]
	mov byte [.tmp], al

	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov word [.num1], ax

	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov word [.num2], ax

	mov word ax, [.num1]
	mov word bx, [.num2]
	call os_get_random

	mov bx, cx
	mov ax, 0
	mov byte al, [.tmp]
	call set_var

	jmp mainloop


	.tmp	db 0
	.num1	dw 0
	.num2	dw 0


.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; READ

do_read:
	call get_token				; Consigue el siguiente token

	cmp ax, STRING				; Buscar una etiqueta
	je .is_ok

	mov si, err_goto_notlabel
	jmp error

.is_ok:
	mov si, token				; Copia de seguridad de esta etiqueta
	mov di, .tmp_token
	call os_string_copy

	mov ax, .tmp_token
	call os_string_length

	mov di, .tmp_token			; Agregue ':' char para finalizar la búsqueda
	add di, ax
	mov al, ':'
	stosb
	mov al, 0
	stosb

	call get_token				; Ahora consigue la variable de desplazamiento
	cmp ax, VARIABLE
	je .second_part_is_var

	mov si, err_syntax
	jmp error


.second_part_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	cmp ax, 0				; ¿Quieres estar buscando al menos el primer byte!
	jg .var_bigger_than_zero

	mov si, err_syntax
	jmp error


.var_bigger_than_zero:
	mov word [.to_skip], ax


	call get_token				; Y ahora la var para almacenar el resultado en
	cmp ax, VARIABLE
	je .third_part_is_var

	mov si, err_syntax
	jmp error


.third_part_is_var:				; Guárdalo para más tarde
	mov ax, 0
	mov byte al, [token]
	mov byte [.var_to_use], al



	; OK, ahora tenemos todas las cosas que necesitamos. Busquemos la etiqueta

	mov word ax, [prog]			; Almacenar ubicación actual
	mov word [.curr_location], ax

	mov word ax, [load_point]
	mov word [prog], ax			; Volver al inicio del programa para encontrar la etiqueta.

.loop:
	call get_token

	cmp ax, LABEL
	jne .line_loop

	mov si, token
	mov di, .tmp_token
	call os_string_compare
	jc .found_label

.line_loop:					; Ir al final de la línea
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]

	cmp al, 10
	jne .line_loop

	mov word ax, [prog]
	mov word bx, [prog_end]
	cmp ax, bx
	jg .past_end

	jmp .loop

.past_end:
	mov si, err_label_notfound
	jmp error


.found_label:
	mov word cx, [.to_skip]			; Omitir el número solicitado de entradas de datos

.data_skip_loop:
	push cx
	call get_token
	pop cx
	loop .data_skip_loop

	cmp ax, NUMBER
	je .data_is_num

	mov si, err_syntax
	jmp error

.data_is_num:
	mov si, token
	call os_string_to_int

	mov bx, ax
	mov ax, 0
	mov byte al, [.var_to_use]
	call set_var

	mov word ax, [.curr_location]
	mov word [prog], ax

	jmp mainloop


	.curr_location	dw 0

	.to_skip	dw 0
	.var_to_use	db 0
	.tmp_token 	times 30 db 0


; ------------------------------------------------------------------
; REM

do_rem:
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	cmp al, 10			; Encuentra el final de la línea después de REM
	jne do_rem

	jmp mainloop


; ------------------------------------------------------------------
; RENAME

do_rename:
	call get_token

	cmp ax, STRING_VAR		; ¿Es una cadena o una cita?
	je .first_is_string

	cmp ax, QUOTE
	je .first_is_quote

	jmp .error

.first_is_string:
	mov si, string_vars		; Localizar cadena
	mov ax, 128
	mul bx
	add si, ax

	jmp .save_file1

.first_is_quote:
	mov si, token			; Se proporciona la ubicación de las citas.

.save_file1:
	mov word di, .file1		; El nombre del archivo se guarda en cadenas temporales porque
	call os_string_copy		; obtener una segunda cita sobrescribirá la anterior
	
.get_second:
	call get_token

	cmp ax, STRING_VAR
	je .second_is_string

	cmp ax, QUOTE
	je .second_is_quote

	jmp .error

.second_is_string:
	mov si, string_vars		; Localiza la segunda cadena
	mov ax, 128
	mul bx
	add si, ax

	jmp .save_file2

.second_is_quote:
	mov si, token

.save_file2:
	mov word di, .file2
	call os_string_copy
	
.check_exists:
	mov word ax, .file1		; Compruebe si el archivo fuente existe
	call os_file_exists
	jc .file_not_found		; Si no existe establece "R = 1"

	clc
	mov ax, .file2			; El segundo archivo es el destino y no debería existir.
	call os_file_exists
	jnc .file_exists		; Si existe establece "R = 3"
	
.rename:
	mov word ax, .file1		; Parece estar bien, vamos a renombrar
	mov word bx, .file2
	call os_rename_file

	jc .rename_failed		; Si falla, configura "R = 2", generalmente causado por un disco de solo lectura

	mov ax, 0			; Funcionó correctamente, así que configure "R = 0" para indicar que no hay error
	mov byte al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

.file_not_found:
	mov ax, 0			; Establecer la variable R en 1
	mov byte al, 'R'
	mov bx, 1
	call set_var

	jmp mainloop

.rename_failed:
	mov ax, 0			; Establecer la variable R en 2
	mov byte al, 'R'
	mov bx, 2
	call set_var

	jmp mainloop

.file_exists:
	mov ax, 0
	mov byte al, 'R'		; Establecer la variable R en 3
	mov bx, 3
	call set_var

	jmp mainloop

.data:
	.file1				times 12 db 0
	.file2				times 12 db 0


; ------------------------------------------------------------------
; RETURN

do_return:
	mov ax, 0
	mov byte al, [gosub_depth]
	cmp al, 0
	jne .is_ok

	mov si, err_return
	jmp error

.is_ok:
	mov si, gosub_points
	add si, ax				; Tabla es palabras (no bytes)
	add si, ax
	lodsw
	mov word [prog], ax
	dec byte [gosub_depth]

	jmp mainloop	


; ------------------------------------------------------------------
; SAVE

do_save:
	call get_token
	cmp ax, QUOTE
	je .is_quote

	cmp ax, STRING_VAR
	jne near .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	jmp .get_position

.is_quote:
	mov si, token

.get_position:
	mov di, .tmp_filename
	call os_string_copy

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.set_data_loc:
	mov word [.data_loc], ax

	call get_token

	cmp ax, VARIABLE
	je .third_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.check_exists:
	mov word [.data_size], ax
	mov word ax, .tmp_filename
	call os_file_exists
	jc .write_file
	jmp .file_exists_fail
	
.write_file:

	mov word ax, .tmp_filename
	mov word bx, [.data_loc]
	mov word cx, [.data_size]
	
	call os_write_file
	jc .save_failure

	mov ax, 0
	mov byte al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop


.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .set_data_loc


.third_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .check_exists

.file_exists_fail:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 2
	call set_var
	jmp mainloop
	
.save_failure:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 1
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error


	.filename_loc	dw 0
	.data_loc	dw 0
	.data_size	dw 0

	.tmp_filename	times 15 db 0


; ------------------------------------------------------------------
; SERIAL

do_serial:
	call get_token
	mov si, token

	mov di, .on_cmd
	call os_string_compare
	jc .do_on_cmd

	mov di, .send_cmd
	call os_string_compare
	jc .do_send_cmd

	mov di, .rec_cmd
	call os_string_compare
	jc .do_rec_cmd

	jmp .error

.do_on_cmd:
	call get_token
	cmp ax, NUMBER
	je .do_on_cmd_ok
	jmp .error

.do_on_cmd_ok:
	mov si, token
	call os_string_to_int
	cmp ax, 1200
	je .on_cmd_slow_mode
	cmp ax, 9600
	je .on_cmd_fast_mode

	jmp .error

.on_cmd_fast_mode:
	mov ax, 0
	call os_serial_port_enable
	jmp mainloop

.on_cmd_slow_mode:
	mov ax, 1
	call os_serial_port_enable
	jmp mainloop


.do_send_cmd:
	call get_token
	cmp ax, NUMBER
	je .send_number

	cmp ax, VARIABLE
	je .send_variable

	jmp .error

.send_number:
	mov si, token
	call os_string_to_int
	call os_send_via_serial
	jmp mainloop

.send_variable:
	mov ax, 0
	mov byte al, [token]
	call get_var
	call os_send_via_serial
	jmp mainloop


.do_rec_cmd:
	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte al, [token]

	mov cx, 0
	mov cl, al
	call os_get_via_serial

	mov bx, 0
	mov bl, al
	mov al, cl
	call set_var

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


	.on_cmd		db "ON", 0
	.send_cmd	db "SEND", 0
	.rec_cmd	db "REC", 0


; ------------------------------------------------------------------
; SIZE

do_size:
	call get_token

	cmp ax, STRING_VAR
	je .is_string

	cmp ax, QUOTE
	je .is_quote

	jmp .error

.is_string:
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov ax, si
	jmp .get_size

.is_quote:
	mov ax, token

.get_size:
	call os_get_file_size
	jc .file_not_found

	mov ax, 0
	mov al, 'S'
	call set_var

	mov ax, 0
	mov al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

.file_not_found:
	mov ax, 0
	mov al, [token]
	mov bx, 0
	call set_var

	mov ax, 0
	mov al, 'R'
	mov bx, 1
 	call set_var
 	
	jmp mainloop



; ------------------------------------------------------------------
; SOUND

do_sound:
	call get_token

	cmp ax, VARIABLE
	je .first_is_var

	mov si, token
	call os_string_to_int
	jmp .done_first

.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

.done_first:

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	mov si, token
	call os_string_to_int
	jmp .finish

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

.finish:
	call os_pause

	jmp mainloop


;-------------------------------------------------------------------
; STRING
do_string:
	call get_token			; El primer parámetro es la palabra 'GET' o 'SET'
	mov si, token
	
	mov di, .get_cmd
	call os_string_compare
	jc .set_str
		
	mov di, .set_cmd
	call os_string_compare
	jc .get_str
	
	jmp .error
	
	.set_str:
	mov cx, 1
	jmp .check_second
	.get_str:
	mov cx, 2

.check_second:
	call get_token			; La siguiente debe ser una variable de cadena, localícela
	
	cmp ax, STRING_VAR
	jne .error
	
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	mov word [.string_loc], si
	
.check_third:
	call get_token			; Ahora debería haber un número
	
	cmp ax, NUMBER
	je .third_is_number
	
	cmp ax, VARIABLE
	je .third_is_variable
	
	jmp .error
	
.third_is_number:	
	mov si, token
	call os_string_to_int
	jmp .got_number	

.third_is_variable:
	mov ah, 0
	mov al, [token]
	call get_var
	jmp .got_number

.got_number:
	cmp ax, 128
	jg .outrange
	cmp ax, 0
	je .outrange
	sub ax, 1
	mov dx, ax
	
.check_forth:
	call get_token			; A continuación una variable numérica
	
	cmp ax, VARIABLE
	jne .error
	
	mov byte al, [token]
	mov byte [.tmp], al
	
	cmp cx, 2
	je .set_var
	
.get_var:
	mov word si, [.string_loc]	; Mover a la ubicación de la cadena
	add si, dx			; Añadir desplazamiento
	lodsb				; Cargar datos
	mov ah, 0
	mov bx, ax			; Establecer datos en variable numérica
	mov byte al, [.tmp]
	call set_var
	jmp mainloop
	
.set_var:
	mov byte al, [.tmp]		; Recuperar la variable
	call get_var			; Obtener su valor
	mov di, [.string_loc]		; Localiza la cadena
	add di, dx			; Añadir el desplazamiento
	stosb				; Almacenamiento de datos
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error
	
.outrange:
	mov si, err_string_range
	jmp error

.data:
	.get_cmd		db "GET", 0
	.set_cmd		db "SET", 0
	.string_loc		dw 0
	.tmp			db 0



; ------------------------------------------------------------------
; WAITKEY

do_waitkey:
	call get_token
	cmp ax, VARIABLE
	je .is_variable

	mov si, err_syntax
	jmp error

.is_variable:
	mov ax, 0
	mov byte al, [token]

	push ax

	call os_wait_for_key

	cmp ax, 48E0h
	je .up_pressed

	cmp ax, 50E0h
	je .down_pressed

	cmp ax, 4BE0h
	je .left_pressed

	cmp ax, 4DE0h
	je .right_pressed

.store:
	mov bx, 0
	mov bl, al

	pop ax

	call set_var

	jmp mainloop


.up_pressed:
	mov ax, 1
	jmp .store

.down_pressed:
	mov ax, 2
	jmp .store

.left_pressed:
	mov ax, 3
	jmp .store

.right_pressed:
	mov ax, 4
	jmp .store


; ==================================================================
; INTERNAL ROUTINES FOR INTERPRETER

; ------------------------------------------------------------------
; Get value of variable character specified in AL (eg 'A')

get_var:
	mov ah, 0
	sub al, 65
	mov si, variables
	add si, ax
	add si, ax
	lodsw
	ret


; ------------------------------------------------------------------
; Set value of variable character specified in AL (eg 'A')
; with number specified in BX

set_var:
	mov ah, 0
	sub al, 65				; Elimine los códigos ASCII antes de 'A'

	mov di, variables			; Encuentra posición en la tabla (de palabras)
	add di, ax
	add di, ax
	mov ax, bx
	stosw
	ret


; ------------------------------------------------------------------
; Get token from current position in prog

get_token:
	mov word si, [prog]
	lodsb

	cmp al, 10
	je .newline

	cmp al, ' '
	je .newline

	call is_number
	jc get_number_token

	cmp al, '"'
	je get_quote_token

	cmp al, 39			; Comilla (')
	je get_char_token

	cmp al, '$'
	je near get_string_var_token

	jmp get_string_token


.newline:
	inc word [prog]
	jmp get_token



get_number_token:
	mov word si, [prog]
	mov di, token

.loop:
	lodsb
	cmp al, 10
	je .done
	cmp al, ' '
	je .done
	call is_number
	jc .fine

	mov si, err_char_in_num
	jmp error

.fine:
	stosb
	inc word [prog]
	jmp .loop

.done:
	mov al, 0			; Cero terminar el token
	stosb

	mov ax, NUMBER			; Devuelve el tipo de token
	ret


get_char_token:
	inc word [prog]			; Mover más allá de la primera cita (')

	mov word si, [prog]
	lodsb

	mov byte [token], al

	lodsb
	cmp al, 39			; Necesita terminar con otra cita.
	je .is_ok

	mov si, err_quote_term
	jmp error

.is_ok:
	inc word [prog]
	inc word [prog]

	mov ax, CHAR
	ret


get_quote_token:
	inc word [prog]			; Mover más allá de la primera cita (") char
	mov word si, [prog]
	mov di, token
.loop:
	lodsb
	cmp al, '"'
	je .done
	cmp al, 10
	je .error
	stosb
	inc word [prog]
	jmp .loop

.done:
	mov al, 0			; Cero terminar el token
	stosb
	inc word [prog]			; Mover más allá de la cita final

	mov ax, QUOTE			; Devuelve el tipo de token
	ret

.error:
	mov si, err_quote_term
	jmp error


get_string_var_token:
	lodsb
	mov bx, 0			; Si es una cadena var, pasa el número de cadena en BX
	mov bl, al
	sub bl, 49

	inc word [prog]
	inc word [prog]

	mov ax, STRING_VAR
	ret
	

get_string_token:
	mov word si, [prog]
	mov di, token
.loop:
	lodsb
	cmp al, 10
	je .done
	cmp al, ' '
	je .done
	stosb
	inc word [prog]
	jmp .loop
.done:
	mov al, 0			; Cero terminar el token
	stosb

	mov ax, token
	call os_string_uppercase

	mov ax, token
	call os_string_length		; ¿Cuánto tiempo fue la ficha?
	cmp ax, 1			; Si 1 char, es una variable o delimitador.
	je .is_not_string

	mov si, token			; Si el token termina con ':', es una etiqueta
	add si, ax
	dec si
	lodsb
	cmp al, ':'
	je .is_label

	mov ax, STRING			; De lo contrario es una cadena general de caracteres.
	ret

.is_label:
	mov ax, LABEL
	ret


.is_not_string:
	mov byte al, [token]
	call is_letter
	jc .is_var

	mov ax, UNKNOWN
	ret

.is_var:
	mov ax, VARIABLE		; De lo contrario, probablemente una variable
	ret


; ------------------------------------------------------------------
; Set carry flag if AL contains ASCII number

is_number:
	cmp al, 48
	jl .not_number
	cmp al, 57
	jg .not_number
	stc
	ret
.not_number:
	clc
	ret


; ------------------------------------------------------------------
; Set carry flag if AL contains ASCII letter

is_letter:
	cmp al, 65
	jl .not_letter
	cmp al, 90
	jg .not_letter
	stc
	ret

.not_letter:
	clc
	ret


; ------------------------------------------------------------------
; Imprimir mensaje de error y salir

error:
	mov ah, 5			; Revertir la página de visualización
	mov al, 0
	int 10h

	mov byte [work_page], 0
	mov byte [disp_page], 0

	call os_print_newline
	call os_print_string		; Imprimir mensaje de error

	mov si, line_num_starter
	call os_print_string


	; Y ahora imprima el número de línea donde ocurrió el error. Nosotros hacemos esto
	; trabajando desde el inicio del programa hasta el punto actual
	; contando el número de caracteres de nueva línea en el camino

	mov word si, [load_point]
	mov word bx, [prog]
	mov cx, 1

.loop:
	lodsb
	cmp al, 10
	jne .not_newline
	inc cx
.not_newline:
	cmp si, bx
	je .finish
	jmp .loop
.finish:

	mov ax, cx
	call os_int_to_string
	mov si, ax
	call os_print_string


	call os_print_newline

	mov word sp, [orig_stack]	; Restaura la pila como estaba cuando se inició BASIC

	ret				; Y acaba


	; Error messages text...

	err_char_in_num		db "Error: unexpected char in number", 0
	err_cmd_unknown		db "Error: unknown command", 0
	err_divide_by_zero	db "Error: attempt to divide by zero", 0
	err_doloop_maximum	db "Error: DO/LOOP nesting limit exceeded", 0
	err_file_notfound	db "Error: file not found", 0
	err_goto_notlabel	db "Error: GOTO or GOSUB not followed by label", 0
	err_label_notfound	db "Error: label not found", 0
	err_nest_limit		db "Error: FOR or GOSUB nest limit exceeded", 0
	err_next		db "Error: NEXT without FOR", 0
	err_loop		db "Error: LOOP without DO", 0
	err_print_type		db "Error: PRINT not followed by quoted text or variable", 0
	err_quote_term		db "Error: quoted string or char not terminated correctly", 0
	err_return		db "Error: RETURN without GOSUB", 0
	err_string_range	db "Error: string location out of range", 0
	err_syntax		db "Error: syntax error", 0
	err_break		db "BREAK CALLED", 0

	line_num_starter	db " - line ", 0


; ==================================================================
; Seccion Data

	orig_stack		dw 0		; Ubicación de la pila original cuando se inició BASIC

	prog			dw 0		; Puntero a la ubicación actual en el código BASIC
	prog_end		dw 0		; Puntero a byte final del código BASIC

	load_point		dw 0

	token_type		db 0		; Tipo de última lectura de token (por ejemplo, NÚMERO, VARIABLE)
	token			times 255 db 0	; Espacio de almacenamiento para el token

vars_loc:
	variables		times 26 dw 0	; Espacio de almacenamiento para variables A a Z

	for_variables		times 26 dw 0	; Almacenamiento para bucles FOR
	for_code_points		times 26 dw 0	; Almacenamiento para posiciones de código donde comienzan los bucles FOR
	
	do_loop_store		times 10 dw 0	; Almacenamiento para bucles de OD.
	loop_in			db 0		; Nivel de bucle

	last_if_true		db 1		; Buscando 'ELSE'

	ink_colour		db 0		; Color de impresión de texto
	work_page		db 0		; Página para imprimir a
	disp_page		db 0		; Página para mostrar

	alert_cmd		db "ALERT", 0
	askfile_cmd		db "ASKFILE", 0
	break_cmd		db "BREAK", 0
	call_cmd		db "CALL", 0
	case_cmd		db "CASE", 0
	cls_cmd			db "CLS", 0
	cursor_cmd		db "CURSOR", 0
	curschar_cmd		db "CURSCHAR", 0
	curscol_cmd		db "CURSCOL", 0
	curspos_cmd		db "CURSPOS", 0
	delete_cmd		db "DELETE", 0
	do_cmd			db "DO", 0
	else_cmd		db "ELSE", 0
	end_cmd			db "END", 0
	files_cmd		db "FILES", 0
	for_cmd 		db "FOR", 0
	gosub_cmd		db "GOSUB", 0
	goto_cmd		db "GOTO", 0
	getkey_cmd		db "GETKEY", 0
	if_cmd 			db "IF", 0
	include_cmd		db "INCLUDE", 0
	ink_cmd			db "INK", 0
	input_cmd 		db "INPUT", 0
	len_cmd			db "LEN", 0
	listbox_cmd		db "LISTBOX", 0
	load_cmd		db "LOAD", 0
	loop_cmd		db "LOOP", 0
	move_cmd 		db "MOVE", 0
	next_cmd 		db "NEXT", 0
	number_cmd		db "NUMBER", 0
	page_cmd		db "PAGE", 0
	pause_cmd 		db "PAUSE", 0
	peek_cmd		db "PEEK", 0
	peekint_cmd		db "PEEKINT", 0
	poke_cmd		db "POKE", 0
	pokeint_cmd		db "POKEINT", 0
	port_cmd		db "PORT", 0
	print_cmd 		db "PRINT", 0
	rand_cmd		db "RAND", 0
	read_cmd		db "READ", 0
	rem_cmd			db "REM", 0
	rename_cmd		db "RENAME", 0
	return_cmd		db "RETURN", 0
	save_cmd		db "SAVE", 0
	serial_cmd		db "SERIAL", 0
	size_cmd		db "SIZE", 0
	sound_cmd 		db "SOUND", 0
	string_cmd		db "STRING", 0
	waitkey_cmd		db "WAITKEY", 0

	and_keyword		db "AND", 0
	then_keyword		db "THEN", 0
	chr_keyword		db "CHR", 0
	hex_keyword		db "HEX", 0
	
	lower_keyword		db "LOWER", 0
	upper_keyword		db "UPPER", 0

	ink_keyword		db "INK", 0
	progstart_keyword	db "PROGSTART", 0
	ramstart_keyword	db "RAMSTART", 0
	timer_keyword		db "TIMER", 0
	variables_keyword	db "VARIABLES", 0
	version_keyword		db "VERSION", 0

	gosub_depth		db 0
	gosub_points		times 10 dw 0	; Puntos en el código para VOLVER a

	string_vars		times 1024 db 0	; 8 * 128 cadenas de bytes


; ------------------------------------------------------------------
;SUERTE :3

