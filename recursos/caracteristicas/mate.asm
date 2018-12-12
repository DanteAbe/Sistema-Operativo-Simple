
os_seed_random:
	push bx
	push ax

	mov bx, 0
	mov al, 0x02			; Minuto
	out 0x70, al
	in al, 0x71

	mov bl, al
	shl bx, 8
	mov al, 0			; Segundo
	out 0x70, al
	in al, 0x71
	mov bl, al

	mov word [os_random_seed], bx	; El kernel será algo así como 0x4435 (Si fueran
					; 44 minutos y 35 segundos después de la hora)
	pop ax
	pop bx
	ret


	os_random_seed	dw 0


; ------------------------------------------------------------------
; os_get_random -- Devuelve un entero aleatorio entre bajo y alto (inclusive)
; IN: AX = entero bajo, BX = entero alto
; OUT: CX = entero aleatorio

os_get_random:
	push dx
	push bx
	push ax

	sub bx, ax			; Se quiere un número entre 0 y...(alto y bajo)
	call .generate_random
	mov dx, bx
	add dx, 1
	mul dx
	mov cx, dx

	pop ax
	pop bx
	pop dx
	add cx, ax			; Se añade la baja compensación atrás
	ret


.generate_random:
	push dx
	push bx

	mov ax, [os_random_seed]
	mov dx, 0x7383			; El número mágico (random.org)
	mul dx				; DX:AX = AX * DX
	mov [os_random_seed], ax

	pop bx
 	pop dx
	ret


; ------------------------------------------------------------------
; os_bcd_to_int -- Se convierte un número codificado decimal binario en un número entero
; IN: AL = BCD número; OUT: AX = valor entero

os_bcd_to_int:
	pusha

	mov bl, al			; Almacena el número entero por ahora

	and ax, 0Fh			; Bits de cero a alto
	mov cx, ax			; CH/CL = número de BCD más bajo, cero ampliado

	shr bl, 4			; Mueve el número BCD más alto a bits más bajos, cero lleno msb
	mov al, 10
	mul bl				; AX = 10 * BL

	add ax, cx			; Añade BCD más bajo a 10*el más alto
	mov [.tmp], ax

	popa
	mov ax, [.tmp]			; Y devuelve en AX
	ret


	.tmp	dw 0


; ------------------------------------------------------------------
; os_long_int_negate -- Multiplica el valor en DX:AX por -1
; IN: DX:AX = entero largo; OUT: DX:AX = -(inicial DX:AX)

os_long_int_negate:
	neg ax
	adc dx, 0
	neg dx
	ret


; ==================================================================

