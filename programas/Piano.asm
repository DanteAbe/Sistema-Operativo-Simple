	BITS 16
 	%INCLUDE "assemblerdev.inc"
	ORG 32768

;Hasta aqui Joaquin Galean
;Desde aqui Gabriel Casazola
start:
	call os_hide_cursor

	call os_clear_screen

	mov ax, mus_kbd_title_msg		; Configurar la pantalla
	mov bx, mus_kbd_footer_msg
	mov cx, BLANCO_EN_ROJO_CLARO
	call os_draw_background

	mov bl, NEGRO_EN_BLANCO			; Bloque blanco para dibujar teclado en
	mov dh, 4
	mov dl, 5
	mov si, 69
	mov di, 21
	call os_draw_block



	; Ahora muchos bucles para dibujar el teclado.

	mov dl, 24		; Línea superior de la caja
	mov dh, 6
	call os_move_cursor

	mov ah, 0Eh
	mov al, 196

	mov cx, 31
.loop1:
	int 10h
	loop .loop1


	mov dl, 24		; Línea inferior de la caja
	mov dh, 18
	call os_move_cursor

	mov ah, 0Eh
	mov al, 196

	mov cx, 31
.loop2:
	int 10h
	loop .loop2



	mov dl, 23		; Esquina superior izquierda
	mov dh, 6
	call os_move_cursor

	mov al, 218
	int 10h


	mov dl, 55		; Esquina superior derecha
	mov dh, 6
	call os_move_cursor

	mov al, 191
	;Hasta aqui Joaquin
	;Desde aca Gabo
	int 10h


	mov dl, 23		; Esquina izquierda inferior
	mov dh, 18
	call os_move_cursor

	mov al, 192
	int 10h


	mov dl, 55		; Esquina inferior derecha
	mov dh, 18
	call os_move_cursor

	mov al, 217
	int 10h


	mov dl, 23		; Linea de caja izquierda
	mov dh, 7
	mov al, 179
.loop3:
	call os_move_cursor
	int 10h
	inc dh
	cmp dh, 18
	jne .loop3


	mov dl, 55		; Linea de caja derecha
	mov dh, 7
	mov al, 179
.loop4:
	call os_move_cursor
	int 10h
	inc dh
	cmp dh, 18
	jne .loop4


	mov dl, 23		; Lineas de seperacion de claves
.biggerloop:
	add dl, 4
	mov dh, 7
	mov al, 179
.loop5:
	call os_move_cursor
	int 10h
	inc dh
	cmp dh, 18
	jne .loop5
	cmp dl, 51
	jne .biggerloop


	mov al, 194		; Parte superior de la linea de caja de union
	mov dh, 6
	mov dl, 27
.loop6:
	call os_move_cursor
	int 10h
	add dl, 4
	cmp dl, 55
	jne .loop6


	mov al, 193		; Parte inferior de la linea de caja de union
	mov dh, 18
	mov dl, 27
.loop7:
	call os_move_cursor
	int 10h
	add dl, 4
	cmp dl, 55
	jne .loop7


	; Y ahora para las teclas negras

	mov bl, NEGRO_EN_BLANCO	

	mov dh, 6
	mov dl, 26
	mov si, 3
	mov di, 13
	call os_draw_block
	
	mov dh, 6
	mov dl, 30
	mov si, 3
	mov di, 13
	call os_draw_block
	
	mov dh, 6
	mov dl, 38
	mov si, 3
	mov di, 13
	call os_draw_block
	
	mov dh, 6
	mov dl, 42
	mov si, 3
	mov di, 13
	call os_draw_block
	
	mov dh, 6
	mov dl, 46
	mov si, 3
	mov di, 13
	call os_draw_block

	; Y por último, dibujar las etiquetas en las teclas que indican que
	; (¡computadora!) teclas para presionar para obtener notas
	
	mov ah, 0Eh

	mov dh, 17
	mov dl, 25
	call os_move_cursor

	mov al, 'Z'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, 'X'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, 'C'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, 'V'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, 'B'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, 'N'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, 'M'
	int 10h

	add dl, 4
	call os_move_cursor
	mov al, ','
	int 10h

	; Ahora los accidentales 
	
	mov dh, 11
	mov dl, 27
	call os_move_cursor
	mov al, 'S'
	int 10h
	
	add dl, 4
	call os_move_cursor
	mov al, 'D'
	int 10h
	
	add dl, 8
	call os_move_cursor
	mov al, 'G'
	int 10h
	
	add dl, 4
	call os_move_cursor
	mov al, 'H'
	int 10h
	
	add dl, 4
	call os_move_cursor
	mov al, 'J'
	int 10h

	; ¡Uf! Hemos dibujado todas las llaves ahora

.retry:
	call os_wait_for_key

.nokey:				; Llaves a juego con notas
	cmp al, 'z'
	jne .s
	mov ax, 4000
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.s:
	cmp al, 's'
	jne .x
	mov ax, 3800
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.x:
	cmp al, 'x'
	jne .d
	mov ax, 3600
	mov bx, 0
	call os_speaker_tone
;Hasta aca Gabriel Casazola
;Desde aqui Karen Galean
	jmp .retry
.d:
	cmp al, 'd'
	jne .c
	mov ax, 3400
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.c:
	cmp al, 'c'
	jne .v
	mov ax, 3200
	mov bx, 0
	call os_speaker_tone
	jmp .retry


.v:
	cmp al, 'v'
	jne .g
	mov ax, 3000
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.g:
	cmp al, 'g'
	jne .b
	mov ax, 2850
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.b:
	cmp al, 'b'
	jne .h
	mov ax, 2700
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.h:
	cmp al, 'h'
	jne .n
	mov ax, 2550
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.n:
	cmp al, 'n'
	jne .j
	mov ax, 2400
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.j:
	cmp al, 'j'
	jne .m
	mov ax, 2250
	mov bx, 0
	call os_speaker_tone
	jmp .retry
.m:
	cmp al, 'm'
	jne .comma
	mov ax, 2100
	mov bx, 0
	call os_speaker_tone
	jmp .retry

.comma:
	cmp al, ','
	jne .space
	mov ax, 2000
	mov bx, 0
	call os_speaker_tone
	jmp .retry

.space:
	cmp al, ' '
	jne .esc
	call os_speaker_off
	jmp .retry

.esc:
	cmp al, 27
	je .end
	jmp .nowt

.nowt:
	jmp .retry

.end:
	call os_speaker_off

	call os_clear_screen

	call os_show_cursor

	ret			; Volver al sistema operativo


	mus_kbd_title_msg	db 'PIANO', 0
	mus_kbd_footer_msg	db 'Presione las teclas para tocar notas, el espacio para silenciar una nota y Esc para salir.', 0


; ------------------------------------------------------------------

;Hasta aqui Karen Galean
