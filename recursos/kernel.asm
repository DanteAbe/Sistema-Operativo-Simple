	BITS 16

	%DEFINE AssemblerOS_VER '1.0'	; OS 
	%DEFINE AssemblerOS_API_VER 16	; API version 

	disk_buffer	equ	24576   ; Tamaño del Kernel en la RAM

;Desde aqui Dante Abraham
; ------------------------------------------------------------------
; Llamado a todos los vectores con sus ubicaciones

os_call_vectors:
	jmp os_main			; 0000h 
	jmp os_print_string		; 0003h
	jmp os_move_cursor		; 0006h
	jmp os_clear_screen		; 0009h
	jmp os_print_horiz_line		; 000Ch
	jmp os_print_newline		; 000Fh
	jmp os_wait_for_key		; 0012h
	jmp os_check_for_key		; 0015h
	jmp os_int_to_string		; 0018h
	jmp os_speaker_tone		; 001Bh
	jmp os_speaker_off		; 001Eh
	jmp os_load_file		; 0021h
	jmp os_pause			; 0024h
	jmp os_fatal_error		; 0027h
	jmp os_draw_background		; 002Ah
	jmp os_string_length		; 002Dh
	jmp os_string_uppercase		; 0030h
	jmp os_string_lowercase		; 0033h
	jmp os_input_string		; 0036h
	jmp os_string_copy		; 0039h
	jmp os_dialog_box		; 003Ch
	jmp os_string_join		; 003Fh
	jmp os_get_file_list		; 0042h
	jmp os_string_compare		; 0045h
	jmp os_string_chomp		; 0048h
	jmp os_string_strip		; 004Bh
	jmp os_string_truncate		; 004Eh
	jmp os_bcd_to_int		; 0051h
	jmp os_get_time_string		; 0054h
	jmp os_get_api_version		; 0057h
	jmp os_file_selector		; 005Ah
	jmp os_get_date_string		; 005Dh
	jmp os_send_via_serial		; 0060h
	jmp os_get_via_serial		; 0063h
	jmp os_find_char_in_string	; 0066h
	jmp os_get_cursor_pos		; 0069h
	jmp os_print_space		; 006Ch
	jmp os_dump_string		; 006Fh
	jmp os_print_digit		; 0072h
	jmp os_print_1hex		; 0075h
	jmp os_print_2hex		; 0078h
	jmp os_print_4hex		; 007Bh
	jmp os_long_int_to_string	; 007Eh
	jmp os_long_int_negate		; 0081h
	jmp os_set_time_fmt		; 0084h
	jmp os_set_date_fmt		; 0087h
	jmp os_show_cursor		; 008Ah
	jmp os_hide_cursor		; 008Dh
	jmp os_dump_registers		; 0090h
	jmp os_string_strincmp		; 0093h
	jmp os_write_file		; 0096h
	jmp os_file_exists		; 0099h
	jmp os_create_file		; 009Ch
	jmp os_remove_file		; 009Fh
	jmp os_rename_file		; 00A2h
	jmp os_get_file_size		; 00A5h
	jmp os_input_dialog		; 00A8h
	jmp os_list_dialog		; 00ABh
	jmp os_string_reverse		; 00AEh
	jmp os_string_to_int		; 00B1h
	jmp os_draw_block		; 00B4h
	jmp os_get_random		; 00B7h
	jmp os_string_charchange	; 00BAh
	jmp os_serial_port_enable	; 00BDh
	jmp os_sint_to_string		; 00C0h
	jmp os_string_parse		; 00C3h
	jmp os_run_basic		; 00C6h
	jmp os_port_byte_out		; 00C9h
	jmp os_port_byte_in		; 00CCh
	jmp os_string_tokenize		; 00CFh


; ------------------------------------------------------------------
; START OF MAIN KERNEL CODE

os_main:
	cli				; Limpiar interruptores
	mov ax, 0
	mov ss, ax			; Definir segmento
	mov sp, 0FFFFh
	sti				; Restaurar interruptores

	cld				; Direccion definida de la RAM

	mov ax, 2000h			; Definir segmentos donde se guardo la memoria
	mov ds, ax			
	mov es, ax			
	mov fs, ax			; Cargado a 64K
	mov gs, ax

	cmp dl, 0
	je no_change
	mov [bootdev], dl		
	push es
	mov ah, 8			
	int 13h
	pop es
	and cx, 3Fh			; Maximo numero de secotres
	mov [SecsPerTrack], cx		; Sector a 1
	movzx dx, dh			
	add dx, 1			
	mov [Sides], dx

no_change:
	mov ax, 1003h			; Definir atributos
	mov bx, 0			
	int 10h

	call os_seed_random		; Generar numeros Random

	mov ax, autorun_bin_file_name
	call os_file_exists
	jc no_autorun_bin		; Salta las 3 lineas si no encuentra AUTORUN

	mov cx, 32768			; Sino carga en la RAM.
	call os_load_file
	jmp execute_bin_program		; ...y mueve el ejecutable


	; o sino un archivo .BAS?

no_autorun_bin:
	mov ax, autorun_bas_file_name
	call os_file_exists
	jc option_screen		; Si no existe un AUTORUN, que salte

	mov cx, 32768			; sino cargarlo en la RAM
	call os_load_file
	call os_clear_screen
	mov ax, 32768
	call os_run_basic		; Interpretador basico de Kernel

	jmp app_selector		; Busca BASIC


	; Ahora se abre la pantalla de comandos

option_screen:
	mov ax, os_init_msg		; Pantalla de bienvenida
	mov bx, os_version_msg
	mov cx, 01111111b		; FONDO PLOMO
	call os_draw_background

	mov ax, dialog_string_1		
	mov bx, dialog_string_2
	mov cx, dialog_string_3
	mov dx, 1			; Botones Ok o Cancel
	call os_dialog_box

	cmp ax, 1			; Ok es igual a 0
	jne near app_selector

	call os_clear_screen		; sino limpiar la pantalla
	call os_command_line

	jmp option_screen		


	; Data...

	os_init_msg		db '                                  Assembler OS                  ', 0
	os_version_msg		db 'Version ', AssemblerOS_VER, 0

	dialog_string_1		db 'Bienvenido Joven :v', 0
	dialog_string_2		db 'Ok: para seguir al escritorio', 0
	dialog_string_3		db 'Cancelar: para los comandos', 0



app_selector:
	mov ax, os_init_msg		; Dibujar Escritorio
	mov bx, os_version_msg
	mov cx, 01111111b		; SEGUNDO FONDO EN PLOMO
	call os_draw_background

	call os_file_selector		; Seleccionar archivo

	jc option_screen		; Regresa al menu

	mov si, ax			; Intento correr 'KERNEL.BIN'?
	mov di, kern_file_name
	call os_string_compare
	jc no_kernel_execute		; Mostrar ventana de error

	push si				; Guardar el archivo temporalmente

	mov bx, si
	mov ax, si
	call os_string_length

	mov si, bx
	add si, ax			; SI 

	dec si
	dec si
	dec si				

	mov di, bin_ext
	mov cx, 3
	rep cmpsb			; Hay 'BIN'?
	jne not_bin_extension		; sino es un '.BAS'

	pop si				; Restaurar nombre del archivo


	mov ax, si
	mov cx, 32768			
	call os_load_file		


execute_bin_program:
	call os_clear_screen		; Limpiar pantalla antes de continuar

	mov ax, 0			; Limpiar registros
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov si, 0
	mov di, 0

	call 32768			; llamar programa externo

	call os_clear_screen		; Termina, limpiar pantalla
	jmp app_selector		; volver al escritorio


no_kernel_execute:			
	mov ax, kerndlg_string_1
	mov bx, kerndlg_string_2
	mov cx, kerndlg_string_3
	mov dx, 0			; Boton de dialogo de caja
	call os_dialog_box

	jmp app_selector		; Reintentar


not_bin_extension:
	pop si				

	push si				

	mov bx, si
	mov ax, si
	call os_string_length

	mov si, bx
	add si, ax			; SI now points to end of filename...

	dec si
	dec si
	dec si				; ...and now to start of extension!

	mov di, bas_ext
	mov cx, 3
	rep cmpsb			; Are final 3 chars 'BAS'?
	jne not_bas_extension		; If not, error out


	pop si

	mov ax, si
	mov cx, 32768			
	call os_load_file		

	call os_clear_screen		; Limpiar pantalla antes de empezar

	mov ax, 32768
	mov si, 0			
	call os_run_basic		; Y ejecute nuestro intérprete BASIC en el código!
	mov si, basic_finished_msg
	call os_print_string
	call os_wait_for_key

	call os_clear_screen
	jmp app_selector		;y volver a la lista de programas


not_bas_extension:
	pop si

	mov ax, ext_string_1
	mov bx, ext_string_2
	mov cx, 0
	mov dx, 0			; un boton en el cuadro de dialogo
	call os_dialog_box

	jmp app_selector		; Iniciando de nuevo


	; Y ahora los datos para el código anterior ....

	kern_file_name		db 'KERNEL.BIN', 0

	autorun_bin_file_name	db 'AUTORUN.BIN', 0
	autorun_bas_file_name	db 'AUTORUN.BAS', 0

	bin_ext			db 'BIN'
	bas_ext			db 'BAS'

	kerndlg_string_1	db 'OYE! Eso no se puede hacer!', 0
	kerndlg_string_2	db 'El kernel no puede abrirse ni editarse', 0
	kerndlg_string_3	db 'cuidado muchacho', 0

	ext_string_1		db 'Archivo invalido', 0
	ext_string_2		db 'Solo se ejecutan programas .BAS o .BIN', 0

	basic_finished_msg	db '>>> Programa Basico terminado', 0


; ------------------------------------------------------------------
; Variables del sistema para las Syscalls


	; Formato de dia y tiempo

	fmt_12_24	db 0		; Non-zero = 24-hr formato

	fmt_date	db 0, '/'	; 0, 1, 2 = M/D/Y, D/M/Y or Y/M/D
					; Bit 7 = nombre para meses
					; If bit 7 = 0, segundo byte = separador de letras


; ------------------------------------------------------------------
; HERRAMIENTAS DEL SISTEMA


	%INCLUDE "caracteristicas/cliente.asm"
 	%INCLUDE "caracteristicas/disco.asm"
	%INCLUDE "caracteristicas/teclado.asm"
	%INCLUDE "caracteristicas/mate.asm"
	%INCLUDE "caracteristicas/miselaneos.asm"
	%INCLUDE "caracteristicas/puertos.asm"
	%INCLUDE "caracteristicas/sonido.asm"
	%INCLUDE "caracteristicas/pantalla.asm"
	%INCLUDE "caracteristicas/cadena.asm"
	%INCLUDE "caracteristicas/basico.asm"
t
