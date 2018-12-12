	BITS 16
	%INCLUDE "assemblerdev.inc"
	ORG 32768

	disk_buffer	equ	24576


start:
	call .draw_background

	mov ax, .command_list			; Dibujar lista de operaciones de disco
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_list_dialog

	jc near .exit				; Presiono ESC?

	cmp ax, 1				; sino responda a las opciones
	je near .delete_file

	cmp ax, 2
	je near .rename_file

	cmp ax, 3
	je near .copy_file

	cmp ax, 4
	je near .file_size

	cmp ax, 5
	je near .disk_info



.delete_file:
	call .draw_background

	call os_file_selector			; recibir el nombre del archivo
	jc .no_delete_file_selected		; si ya esta, presionar ESC

	push ax					; guardar el nombre de archivo

	call .draw_background

	mov ax, .delete_confirm_msg		; confirmar el eliminar
	mov bx, 0
	mov cx, 0
	mov dx, 1
	call os_dialog_box

	cmp ax, 0
	je .ok_to_delete

	pop ax
	jmp .delete_file

.ok_to_delete:
	pop ax
	call os_remove_file
	jc near .writing_error



.no_delete_file_selected:
	jmp start



.rename_file:
	call .draw_background

	call os_file_selector			; recibir el nombre del archivo
	jc .no_rename_file_selected		; si ESC es presionado, salir

	mov si, ax				
	mov di, .filename_tmp1
	call os_string_copy

.retry_rename:
	call .draw_background

	mov bx, .filename_msg			; recibir el segundo nombre del archivo
	mov ax, .filename_input
	call os_input_dialog

	mov si, ax				
	mov di, .filename_tmp2
	call os_string_copy

	mov ax, di				; El segundo nombre existe?
	call os_file_exists
	jnc .rename_fail			; salir si es asi

	mov ax, .filename_tmp1
	mov bx, .filename_tmp2

	call os_rename_file
	jc near .writing_error

	jmp start


.rename_fail:
	mov ax, .err_file_exists
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp .retry_rename


.no_rename_file_selected:
	jmp start


.copy_file:
	call .draw_background

	call os_file_selector			; recibir el nombre del archivo
	jc .no_copy_file_selected

	mov si, ax				
	mov di, .filename_tmp1
	call os_string_copy

	call .draw_background

	mov bx, .filename_msg			
	mov ax, .filename_input
	call os_input_dialog

	mov si, ax
	mov di, .filename_tmp2
	call os_string_copy

	mov ax, .filename_tmp1
	mov bx, .filename_tmp2

	mov cx, 36864				; Posicion del Assembler Manager
	call os_load_file

	cmp bx, 28672				; ES mas grande de 28k?
	jg .copy_file_too_big

	mov cx, bx				
	mov bx, 36864
	mov ax, .filename_tmp2
	call os_write_file

	jc near .writing_error

	jmp start

.no_copy_file_selected:
	jmp start

.copy_file_too_big:				; Si es mas grande de 28k
	call .draw_background
	mov ax, .err_too_large_msg
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp start

.file_size:
	call .draw_background

	call os_file_selector			; recibir el nombre del archivo
	jc .no_rename_file_selected		

	call os_get_file_size

	mov ax, bx				
	call os_int_to_string
	mov bx, ax				

	mov ax, .size_msg
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp start


.disk_info:
	mov cx, 1				; Carga el primer sector de la RAM
	mov dx, 0
	mov bx, disk_buffer

	mov ah, 2
	mov al, 1
	stc
	int 13h					; BIOS 

	mov si, disk_buffer + 2Bh		; Aqui inicia el disco

	mov di, .tmp_string1
	mov cx, 11				
	rep movsb

	mov byte [di], 0			

	mov si, disk_buffer + 36h		

	mov di, .tmp_string2
	mov cx, 8				
	rep movsb

	mov byte [di], 0			

	mov ax, .label_string_text		; Agrega la info de los resultados
	mov bx, .tmp_string1
	mov cx, .label_string_full
	call os_string_join

	mov ax, .fstype_string_text
	mov bx, .tmp_string2
	mov cx, .fstype_string_full
	call os_string_join

	call .draw_background

	mov ax, .label_string_full		; Muestra la info
	mov bx, .fstype_string_full
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp start


.writing_error:
	call .draw_background
	mov ax, .error_msg
	mov bx, .error_msg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp start


.exit:
	call os_clear_screen
	ret


.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 00100000b
	call os_draw_background
	ret


	.command_list		db 'Borrar Archivo, Renombrar Archivo, Copiar Archivo, Mostrar tamanio, Mostrar info del disco', 0

	.help_msg1		db 'Seleccione una operacion,', 0
	.help_msg2		db 'o presiona ESC para largarte...', 0

	.title_msg		db 'Assembler Rules Manager', 0
	.footer_msg		db 'Copiar, renombrar y eliminar archivos', 0

	.label_string_text	db 'Nombre del Systema: ', 0
	.label_string_full	times 30 db 0

	.fstype_string_text	db 'Tipos del Systema: ', 0
	.fstype_string_full	times 30 db 0

	.delete_confirm_msg	db '¿Estas seguro wachin?', 0

	.filename_msg		db 'Ingresa el nombre completo mas la expansion (Ej: Chorizo.BAR):', 0
	.filename_input		times 255 db 0
	.filename_tmp1		times 15 db 0
	.filename_tmp2		times 15 db 0

	.size_msg		db 'Tamaño del Archivo (en bytes):', 0

	.error_msg		db 'Hubo un error al escribirlo', 0
	.error_msg2		db 'Lee solo media, o el Archivo existe!', 0
	.err_too_large_msg	db 'Muy largo wey (max 24K)!', 0
	.err_file_exists	db 'El nombre ya existe', 0

	.tmp_string1		times 15 db 0
	.tmp_string2		times 15 db 0


; ------------------------------------------------------------------

