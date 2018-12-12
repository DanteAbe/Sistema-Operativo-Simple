; COMANDOS

os_command_line:
	call os_clear_screen

	mov si, version_msg
	call os_print_string
	mov si, help_text
	call os_print_string


get_cmd:					; Bucle de procesamiento principal
	mov di, input			; Limpia el buffer interno cada vez
	mov al, 0
	mov cx, 256
	rep stosb

	mov di, command			; Y un simple buffer de comando
	mov cx, 32
	rep stosb

	mov si, prompt			; Procesamiento principal, solicitud de entrada
	call os_print_string

	mov ax, input			; Obtiene la cadena de comandos del usuario, pantalla de inicio
	call os_input_string

	call os_print_newline

	mov ax, input			; Remueve espacios finales
	call os_string_chomp

	mov si, input			; Si solo enter es presionado, solicitud de nuevo
	cmp byte [si], 0
	je get_cmd

	mov si, input			; Aparte o separa el comando individual
	mov al, ' '
	call os_string_tokenize

	mov word [param_list], di	; Almacena las ubicaciones de los parámetros completos
	mov si, input			; Almacena una copia del comando para modificaciones posteriores
	mov di, command
	call os_string_copy



	; Primero, vamos a ver si es un comando interno....

	mov ax, input
	call os_string_uppercase

	mov si, input

	mov di, salir_string		; 'SALIR' entró?
	call os_string_compare
	jc near salir

	mov di, escritorio_string	; 'ESCRITORIO' entró?
	call os_string_compare
	jc near list_directory

	mov di, detalles_string		; 'DETALLES' entró?
	call os_string_compare
	jc near detalles_file

	mov di, eliminar_string		; 'ELIMINAR' entró?
	call os_string_compare
	jc near eliminar_file

	mov di, copiar_string		; 'COPIAR' entró?
	call os_string_compare
	jc near copiar_file

	mov di, renombrar_string	; 'RENOMBRAR' entró?
	call os_string_compare
	jc near ren_file


	mov ax, command
	call os_string_uppercase
	call os_string_length


	mov si, command
	add si, ax

	sub si, 4

	mov di, bin_extension		; Hay un archivo BIN?
	call os_string_compare
	jc bin_file

	mov di, bas_extension		; Hay un archivo BAS?
	call os_string_compare
	jc bas_file

	jmp no_extension


bin_file:
	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

execute_bin:
	mov si, command
	mov di, kern_file_string
	mov cx, 6
	call os_string_strincmp
	jc no_kernel_allowed

	mov ax, 0			; Limpia los registros
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov word si, [param_list]
	mov di, 0

	call 32768			; Llamado a un programa externo

	jmp get_cmd		; una vez acabado inicia de nuevo



bas_file:
	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

	mov ax, 32768
	mov word si, [param_list]
	call os_run_basic

	jmp get_cmd



no_extension:
	mov ax, command
	call os_string_length

	mov si, command
	add si, ax

	mov byte [si], '.'
	mov byte [si+1], 'B'
	mov byte [si+2], 'I'
	mov byte [si+3], 'N'
	mov byte [si+4], 0

	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc try_bas_ext

	jmp execute_bin


try_bas_ext:
	mov ax, command
	call os_string_length

	mov si, command
	add si, ax
	sub si, 4

	mov byte [si], '.'
	mov byte [si+1], 'B'
	mov byte [si+2], 'A'
	mov byte [si+3], 'S'
	mov byte [si+4], 0

	jmp bas_file



total_fail:
	mov si, invalid_msg
	call os_print_string

	jmp get_cmd


no_kernel_allowed:
	mov si, kern_warn_msg
	call os_print_string

	jmp get_cmd


; ------------------------------------------------------------------

clear_screen:
	call os_clear_screen
	jmp get_cmd

; ------------------------------------------------------------------

kern_warning:
	mov si, kern_warn_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

list_directory:
	mov cx,	0			

	mov ax, dirlist			
	call os_get_file_list

	mov si, dirlist
	mov ah, 0Eh			

.repeat:
	lodsb				
	cmp al, 0			
	je .done

	cmp al, ','			
	jne .nonewline
	pusha
	call os_print_newline		
	popa
	jmp .repeat

.nonewline:
	int 10h
	jmp .repeat

.done:
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

detalles_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			
	jne .filename_provided

	mov si, nofilename_msg		
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_file_exists		
	jc .not_found

	mov cx, 32768			
	call os_load_file

	mov word [file_size], bx

	cmp bx, 0			
	je get_cmd

	mov si, 32768
	mov ah, 0Eh			
.loop:
	lodsb				

	cmp al, 0Ah			
	jne .not_newline

	call os_get_cursor_pos
	mov dl, 0
	call os_move_cursor

.not_newline:
	int 10h				
	dec bx				
	cmp bx, 0			
	jne .loop

	jmp get_cmd

.not_found:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

eliminar_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Se entrego?
	jne .filename_provided

	mov si, nofilename_msg		
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_remove_file
	jc .failure

	mov si, .success_msg
	call os_print_string
	mov si, ax
	call os_print_string
	call os_print_newline
	jmp get_cmd

.failure:
	mov si, .failure_msg
	call os_print_string
	jmp get_cmd


	.success_msg	db 'Eliminar Archivo: ', 0
	.failure_msg	db 'No se pudo eliminar', 13, 10, 0



; ------------------------------------------------------------------

copiar_file:
	mov word si, [param_list]
	call os_string_parse
	mov word [.tmp], bx

	cmp bx, 0			
	jne .filename_provided

	mov si, nofilename_msg		
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov dx, ax			
	mov ax, bx
	call os_file_exists
	jnc .already_exists

	mov ax, dx
	mov cx, 32768
	call os_load_file
	jc .load_fail

	mov cx, bx
	mov bx, 32768
	mov word ax, [.tmp]
	call os_write_file
	jc .write_fail

	mov si, .success_msg
	call os_print_string
	jmp get_cmd

.load_fail:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd

.write_fail:
	mov si, writefail_msg
	call os_print_string
	jmp get_cmd

.already_exists:
	mov si, exists_msg
	call os_print_string
	jmp get_cmd


	.tmp		dw 0
	.success_msg	db 'Copy/Paste con exito', 13, 10, 0


; ------------------------------------------------------------------

ren_file:
	mov word si, [param_list]
	call os_string_parse

	cmp bx, 0			; Hay dos archivos?
	jne .filename_provided

	mov si, nofilename_msg  ; Mostrar error
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov cx, ax			; El nombre esta en espera
	mov ax, bx			; Ubicacion
	call os_file_exists	; COmparar si ya existe
	jnc .already_exists

	mov ax, cx			; El nombre vuelve
	call os_rename_file
	jc .failure

	mov si, .success_msg
	call os_print_string
	jmp get_cmd

.already_exists:
	mov si, exists_msg
	call os_print_string
	jmp get_cmd

.failure:
	mov si, .failure_msg
	call os_print_string
	jmp get_cmd


	.success_msg	db 'Renombrado con exito', 13, 10, 0
	.failure_msg	db 'Hubo un error', 13, 10, 0


; ------------------------------------------------------------------

salir:
	ret


; ------------------------------------------------------------------

	input			times 256 db 0
	command			times 32 db 0

	dirlist			times 1024 db 0
	tmp_string		times 15 db 0

	file_size		dw 0
	param_list		dw 0

	bin_extension		db '.BIN', 0
	bas_extension		db '.BAS', 0

	prompt			db '> ', 0

	help_text		db 'COMANDOS: ESCRITORIO, COPIAR, RENOMBRAR, ELIMINAR, DETALLES, SALIR', 13, 10, 0
	invalid_msg		db 'No es un comando o un programa', 13, 10, 0
	nofilename_msg		db 'No ingreso nombre del archivo, ej: KERNEL.BIN', 13, 10, 0
	notfound_msg		db 'Archivo no encontrado', 13, 10, 0
	writefail_msg		db 'No se puede escribir', 13, 10, 0
	exists_msg		db 'Ya existe', 13, 10, 0

	version_msg		db 'AssemblerOS ', AssemblerOS_VER, 13, 10, 0

	salir_string		db 'SALIR', 0
	escritorio_string	db 'ESCRITORIO', 0

	detalles_string		db 'DETALLES', 0
	eliminar_string		db 'ELIMINAR', 0
	renombrar_string	db 'RENOMBRAR', 0
	copiar_string		db 'COPIAR', 0

	kern_file_string	db 'KERNEL', 0
	kern_warn_msg		db 'NO SE EJECUTA EL KERNEL!', 13, 10, 0


; ==================================================================

