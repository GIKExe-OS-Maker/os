BITS 16
ORG 0x7C00

start:
	; Initialize the stack
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7C00
	mov bp, sp

	in al, 0x92
	or al, 2
	out 0x92, al

	cli
	in al, 0x70
	or al, 0x80
	out 0x70, al

	; Load GDT
	lgdt [gdt_descriptor]

	; Enter protected mode
	mov eax, cr0
	or  al, 1
	mov cr0, eax
	jmp 08h:protected_mode_start

[BITS 32]
protected_mode_start:
	; Initialize segment registers
	mov ax, 10h
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x90000  ; Setup stack

	; Set up VGA for 640x360 mode
	call set_vga_mode_640x360

	; Draw a hollow rectangle
	call draw_hollow_rectangle

	; Infinite loop to prevent the program from exiting
hang:
	hlt
	jmp hang

set_vga_mode_640x360:
	; Unlock VGA registers
	mov dx, 0x03C4  ; VGA Sequencer Index
	mov ax, 0x0604  ; Unlocking sequence
	out dx, ax

	; Set clock mode
	mov ax, 0x0100
	out dx, ax
	mov dx, 0x03D4  ; VGA CRT Controller Index
	mov al, 0x11
	out dx, al
	inc dx
	in al, dx
	and al, 0x7F
	out dx, al

	; Set 640x360 mode
	mov dx, 0x03C2  ; Misc Output
	mov al, 0xE3
	out dx, al

	; Horizontal total
	mov dx, 0x03D4
	mov al, 0x00
	out dx, al
	inc dx
	mov al, 0x9F
	out dx, al

	; Horizontal display end
	mov dx, 0x03D4
	mov al, 0x01
	out dx, al
	inc dx
	mov al, 0x7F
	out dx, al

	; Horizontal blank start
	mov dx, 0x03D4
	mov al, 0x02
	out dx, al
	inc dx
	mov al, 0x80
	out dx, al

	; Horizontal blank end
	mov dx, 0x03D4
	mov al, 0x03
	out dx, al
	inc dx
	mov al, 0x1F
	out dx, al

	; Vertical total
	mov dx, 0x03D4
	mov al, 0x06
	out dx, al
	inc dx
	mov al, 0x4D
	out dx, al

	; Vertical display end
	mov dx, 0x03D4
	mov al, 0x12
	out dx, al
	inc dx
	mov al, 0x4F
	out dx, al

	; Vertical blank start
	mov dx, 0x03D4
	mov al, 0x15
	out dx, al
	inc dx
	mov al, 0x96
	out dx, al

	; Vertical blank end
	mov dx, 0x03D4
	mov al, 0x16
	out dx, al
	inc dx
	mov al, 0x30
	out dx, al

	ret

draw_hollow_rectangle:
	; Draw a hollow rectangle at (100, 100) with width 200 and height 100
	mov edi, 0xA0000  ; Start of VGA framebuffer in A000:0000

	; Draw top and bottom sides
	mov ecx, 200      ; Width of the rectangle
	mov eax, 100      ; X offset
	add edi, eax      ; Adjust to starting column
	mov ebx, edi

draw_top_side:
	mov byte [edi], 0x0F  ; Set pixel color (white)
	inc edi
	loop draw_top_side

	mov edi, ebx
	add edi, 640 * 99     ; Move to bottom side
	mov ecx, 200          ; Width of the rectangle

draw_bottom_side:
	mov byte [edi], 0x0F  ; Set pixel color (white)
	inc edi
	loop draw_bottom_side

	; Draw left and right sides
	mov edi, ebx
	mov ecx, 100          ; Height of the rectangle

draw_left_side:
	mov byte [edi], 0x0F  ; Set pixel color (white)
	add edi, 640          ; Move to next row
	loop draw_left_side

	mov edi, ebx
	add edi, 200          ; Move to right side
	mov ecx, 100          ; Height of the rectangle

draw_right_side:
	mov byte [edi], 0x0F  ; Set pixel color (white)
	add edi, 640          ; Move to next row
	loop draw_right_side

	ret

; GDT setup
gdt_start:
	dq 0x0000000000000000 ; Null descriptor
	dq 0x00CF9A000000FFFF ; Code segment descriptor
	dq 0x00CF92000000FFFF ; Data segment descriptor

gdt_end:

gdt_descriptor:
	dw gdt_end - gdt_start - 1
	dd gdt_start

times 510-($-$$) db 0
dw 0xAA55 ; Boot signature
