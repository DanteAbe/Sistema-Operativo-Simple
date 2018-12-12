BITS 16

	jmp short bootloader_start	; Descripcion del disco
	nop				


; ------------------------------------------------------------------
; Descripcion del Disco
; Note: some of these values are hard-coded in the source!
; Values are those used by IBM for 1.44 MB, 3.5" diskette

OEMLabel		db "ASSEBOOT"	; Etiqueta del Disco
BytesPerSector		dw 512		; Bytes por sector
SectorsPerCluster	db 1		; Sectores por cluster
ReservedForBoot		dw 1		; Sectores reservados para el boot
NumberOfFats		db 2		; Copias del FAT
RootDirEntries		dw 224		; Numero de entradas de la direccion root
					; (224 * 32 = 7168 = 14 sectores a leer)
LogicalSectors		dw 2880		; Sectores logicos
MediumByte		db 0F0h		; Descriptor
SectorsPerFat		dw 9		; Sectores por FAT
SectorsPerTrack		dw 18		; Sectores por track (36/cylinder)
Sides			dw 2		; Numero de lados
HiddenSectors		dd 0		; Numero de sectores ocultos
LargeSectors		dd 0		; Numero de LBA sectores
DriveNo			dw 0		; Drive No: 0
Signature		db 41		; Drive signature: 41 para la imagen
VolumeID		dd 00000000h	; Volume ID: ninguno
VolumeLabel		db "AssemblerOS "; Volume Label: solo 11 caracteres
FileSystem		db "FAT12   "	; Tipo de System


; ------------------------------------------------------------------
; Codigo principal del Boot

bootloader_start:
	mov ax, 07C0h			; 4Kb para la stack
	add ax, 544			; 8kb buffer = 512 paragraphs + 32 paragraphs (cargador)
	cli				; Desactiva interruptres en cambio de stack
	mov ss, ax
	mov sp, 4096
	sti				; Restaura interruptores

	mov ax, 07C0h			; Segmentacion de Data para cargar
	mov ds, ax

	

	cmp dl, 0
	je no_change
	mov [bootdev], dl		; guarda el numero del boot
	mov ah, 8			; Parametros del disco
	int 13h
	jc fatal_disk_error
	and cx, 3Fh			; Maximo numero de sectores
	mov [SectorsPerTrack], cx	; Sectores empiezan en 1
	movzx dx, dh			; 
	add dx, 1			; 
	mov [Sides], dx

no_change:
	mov eax, 0			; 



floppy_ok:				; Listo para leer el primer bloque
	mov ax, 19			; busqueda de la direccion root
	call l2hts

	mov si, buffer			
	mov bx, ds
	mov es, bx
	mov bx, si

	mov ah, 2			
	mov al, 14			

	pusha				


read_root_dir:
	popa				
	pusha

	stc				
	int 13h				; Leyendo los sectores con el BIOS

	jnc search_dir			
	call reset_floppy		
	jnc read_root_dir		

	jmp reboot			


search_dir:
	popa

	mov ax, ds			; Direccion Root esta en el buffer
	mov es, ax			
	mov di, buffer

	mov cx, word [RootDirEntries]	; Busca las 244 entradas
	mov ax, 0			


next_root_entry:
	xchg cx, dx			

	mov si, kern_filename		; Busca el nombre del kernel
	mov cx, 11
	rep cmpsb
	je found_file_to_load		

	add ax, 32			

	mov di, buffer			; Siguiente entrada
	add di, ax

	xchg dx, cx			
	loop next_root_entry

	mov si, file_not_found		; Si el kernel no se encuentra, se lanzara error
	call print_string
	jmp reboot


found_file_to_load:			
	mov ax, word [es:di+0Fh]	
	mov word [cluster], ax

	mov ax, 1			
	call l2hts

	mov di, buffer			
	mov bx, di

	mov ah, 2			
	mov al, 9		

	pusha				


read_fat:
	popa				
	pusha

	stc
	int 13h				; Leer los sectores usando la BIOS

	jnc read_fat_ok			; Si la lectura esta bien, proseguir
	call reset_floppy		; sino, resetear
	jnc read_fat			; Reseteado?

; ******************************************************************
fatal_disk_error:
; ******************************************************************
	mov si, disk_error		; Imprimir error del disco
	call print_string
	jmp reboot			; Doble error


read_fat_ok:
	popa

	mov ax, 2000h			
	mov es, ax
	mov bx, 0

	mov ah, 2			
	mov al, 1

	push ax				

load_file_sector:
	mov ax, word [cluster]		; Convertir el sector a logico
	add ax, 31

	call l2hts			

	mov ax, 2000h			
	mov es, ax
	mov bx, word [pointer]

	pop ax				
	push ax

	stc
	int 13h

	jnc calculate_next_cluster	

	call reset_floppy		
	jmp load_file_sector



; En la FAT, los valores de clúster se almacenan en 12 bits, por lo que tenemos que

; hacer un poco de matemáticas para averiguar si estamos tratando con un byte

; y 4 bits del siguiente byte, o los últimos 4 bits de un byte

; y luego el byte posterior!

calculate_next_cluster:
	mov ax, [cluster]
	mov dx, 0
	mov bx, 3
	mul bx
	mov bx, 2
	div bx				; DX = [cluster] mod 2
	mov si, buffer
	add si, ax			; AX = word in FAT for the 12 bit entry
	mov ax, word [ds:si]

	or dx, dx			; If DX = 0 [cluster] is even; if DX = 1 then it's odd

	jz even				; If [cluster] is even, drop last 4 bits of word
					; with next cluster; if odd, drop first 4 bits

odd:
	shr ax, 4			; Shift out first 4 bits (they belong to another entry)
	jmp short next_cluster_cont


even:
	and ax, 0FFFh			


next_cluster_cont:
	mov word [cluster], ax		

	cmp ax, 0FF8h		
	jae end

	add word [pointer], 512		
	jmp load_file_sector


end:					; TENEMOS EL ARCHIVO A CARGAR!
	pop ax				; Limpiar la stack
	mov dl, byte [bootdev]		; Kernel con boot informacion

	jmp 2000h:0000h			


; ------------------------------------------------------------------
; BOOTLOADER SUBRUTINAS

reboot:
	mov ax, 0
	int 16h				
	mov ax, 0
	int 19h				; Reinicia el sistema


print_string:				
	pusha

	mov ah, 0Eh			; int 10h teletype function

.repeat:
	lodsb				; Recibir letra
	cmp al, 0
	je .done			; si es cero, el texto esta vacio
	int 10h				; sino imprimirlo
	jmp short .repeat

.done:
	popa
	ret


reset_floppy:		
	push ax
	push dx
	mov ax, 0
	mov dl, byte [bootdev]
	stc
	int 13h
	pop dx
	pop ax
	ret


l2hts:			
			
	push bx
	push ax

	mov bx, ax			; Guardar sector logico

	mov dx, 0			; Primer sector
	div word [SectorsPerTrack]
	add dl, 01h			
	mov cl, dl			
	mov ax, bx

	mov dx, 0			
	div word [SectorsPerTrack]
	mov dx, 0
	div word [Sides]
	mov dh, dl			
	mov ch, al			

	pop ax
	pop bx

	mov dl, byte [bootdev]		; Dispositivo correcto

	ret


; ------------------------------------------------------------------
; STRINGS AND VARIABLES

	kern_filename	db "KERNEL  BIN"	; Nombre del kernel

	disk_error	db "Uy, error de emulado", 0
	file_not_found	db "KERNEL.BIN NO ENCONTRADO!!! D:", 0

	bootdev		db 0 	; Numero del boot
	cluster		dw 0 	; El cluster del programa a cargar
	pointer		dw 0 	


; ------------------------------------------------------------------
; END OF BOOT SECTOR AND BUFFER START

	times 510-($-$$) db 0	; Sector boot en 0
	dw 0AA55h		; Boot signature (NO CAMBIAR COÑO!)


buffer:				; Disk buffer empiza con 8k

;Hasta aqui Dante Abraham
; ==================================================================

