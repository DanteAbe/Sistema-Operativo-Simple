
	BITS 16

	%INCLUDE "assemblerdev.inc"
	ORG 32768


start:
	mov ax, warnmsg_1
	mov bx, warnmsg_2
	mov cx, 0
	mov dx, 1
	call os_dialog_box
	cmp ax, 0
	je .proceed

	call os_clear_screen
	ret


.proceed:
	call os_clear_screen

	mov ax, 0			
	call os_serial_port_enable

	mov si, start_msg
	call os_print_string


main_loop:
	mov dx, 0			
	mov ax, 0
	mov ah, 03h			
	int 14h

	bt ax, 8			
	jc received_byte

	mov ax, 0			
	call os_check_for_key

	cmp ax, 4200h			
	je finish			

	cmp al, 0			
	je main_loop

	call os_send_via_serial		
	jmp main_loop

received_byte:				
	call os_get_via_serial

	cmp al, 1Bh			
	je esc_received

	mov ah, 0Eh			
	int 10h
	jmp main_loop

finish:
	mov si, finish_msg
	call os_print_string

	call os_wait_for_key

	ret



esc_received:
	call os_get_via_serial		
	cmp al, '['			
	jne main_loop

	mov bl, al			

	call os_get_via_serial		

	cmp al, 'H'
	je near move_to_home

	cmp al, 'J'
	je near erase_to_bottom

	cmp al, 'K'
	je near erase_to_end_of_line


					
					
					

	mov cl, al			
	mov al, bl			

	mov ah, 0Eh			
	int 10h
	mov al, cl
	int 10h

	jmp main_loop



move_to_home:
	mov dx, 0
	call os_move_cursor
	jmp main_loop


erase_to_bottom:
	call os_get_cursor_pos

	push dx				

	call erase_sub

	inc dh				
	mov dl, 0
	call os_move_cursor

	mov ah, 0Ah			
	mov al, ' '
	mov bx, 0
	mov cx, 80
.more:
	int 10h
	inc dh				
	call os_move_cursor
	cmp dh, 25			
	jne .more

	pop dx				
	call os_move_cursor

	jmp main_loop



erase_to_end_of_line:
	call erase_sub
	jmp main_loop


erase_sub:
	call os_get_cursor_pos

	push dx				

	mov ah, 80			
	sub ah, dl			

	mov cx, 0			
	mov cl, ah

	mov ah, 0Ah			
	mov al, ' '
	mov bx, 0
	int 10h

	pop dx
	call os_move_cursor

	ret


	warnmsg_1	db 'Terminal de programa serial', 0
	warnmsg_2	db 'Si no hay puertos, continuara?', 0

	start_msg	db 'AssembleRulesOS -- Presionar F8 para largarte', 13, 10, 'Conectando mediante el puerto serial 9600...', 13, 10, 13, 10, 0
	finish_msg	db 13, 10, 13, 10, 'Saliendo de AssembleRulesOS; presiona cualquier tecla', 13, 10, 0


; ------------------------------------------------------------------

