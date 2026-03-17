; Benjamin DELPY `gentilkiwi`
; https://blog.gentilkiwi.com
; benjamin@gentilkiwi.com
; Licence : https://creativecommons.org/licenses/by/4.0/
;
; This is a little patch for Logitech RQR12_10_B0032 or RQR12_11_B0032 -ONLY- , to introduce a new 'REGISTER_KIWI' ('k') to dump
; usage: KUNI_FW_GetLongRegister(pHandles, DEVICE_INDEX_RECEIVER, REGISTER_KIWI, (BYTE[]) { HIBYTE(Addr), LOBYTE(Addr), 0x00)
;   len = 0x00  -> 0x10 (the maximum bytes you can have from a long)
;   len |= 0x80 -> infopage
; - yes, you must be able to patch altered firmware with a crc-aware OR signature-aware bootloader ;) -
;
; Building ( sdcc - https://sdcc.sourceforge.net/ ):
;   sdas8051 -o RQR12.10_B0032_read_mem.asm
;   sdld -i RQR12.10_B0032_read_mem.rel
;
; Result ( SRecord - https://srecord.sourceforge.net/ ) :
;   srec_cat -o - -hex_dump RQR12.10_B0032_read_mem.ihx -intel
;	000032D0:                                           80 9E  #              ..
;	00003300:             02 5A 00                             #    .Z.
;	00005A00: E5 37 64 6B 70 02 80 05 7F 02 02 32 7E 85 38 83  #e7dkp......2~.8.
;	00005A10: 85 39 82 E5 3A 54 0F 70 02 74 10 FA 78 38 E5 3A  #.9.e:T.p.t.zx8e:
;	00005A20: 30 E7 02 D2 FB E0 F6 A3 08 DA FA C2 FB 02 32 FD  #0g.R{`v#.ZzB{.2}

.module read_mem

RAM   			= 0x00
INFEN			= 0xfb ; FSR.3 (0xf8 - bit 3)
ADDR_ORIG_ERROR	= 0x327e
ADDR_ORIG_END	= 0x32fd

.area CODE (ABS)

.org 0x32de
	; the original jump target was to... another jump (0x3306) jumping to ADDR_ORIG_ERROR (0x327e)
	; unfortunately, I need some byte in this target, so let's fix by jumping directly to target
	; ...ironically I feel this to be optimized version of the original code.
	;
	; code:32DC             code_32DC:                              ; CODE XREF: Dispatch_Hidpp_MsgId+31↑j
	; code:32DC                                                     ; Dispatch_Hidpp_MsgId+3C↑j
	; code:32DC 7F 03                       mov     R7, #3
	; code:32DE 80 26                       sjmp    code_3306
	; ... with ...
	; code:3306             code_3306:                              ; CODE XREF: Dispatch_Hidpp_MsgId+59↑j
	; code:3306 41 7E                       ajmp    code_327E
	
	sjmp ADDR_ORIG_ERROR
	; old opcodes : 80 26
	; new opcodes : 80 9e


.org 0x3304
	; this part of the code was inside the part Dispatch_Hidpp_MsgId_GET_LONG_REGISTER_local, it ends here
	; when neither REGISTER_DEVICE_ACTIVITY nor REGISTER_PAIRING_INFORMATION are asked.
	; as we want a new REGISTER_KIWI, we'll have to redirect the flow to new value check, then kiwi
	;
	; code:3304             code_3304:                              ; CODE XREF: Dispatch_Hidpp_MsgId+2A↑j
	; code:3304 7F 02                       mov     R7, #2          ; HIDPP_ERR_INVALID_ADDRESS
	; code:3306
	; code:3306             code_3306:                              ; CODE XREF: Dispatch_Hidpp_MsgId+59↑j
	; code:3306 41 7E                       ajmp    code_327E
	
	ljmp Dispatch_Hidpp_MsgId_AlternativeEnding
	; old opcodes : 7f 02 41 7e
	; new opcodes : 02 5a 00 [7e]


.org 0x5a00

Dispatch_Hidpp_MsgId_AlternativeEnding:	; hijack goes here
	mov		A, RAM + 0x37
	xrl		A, #'k'
	jnz		not_kiwi		; :(
	mov		DPH, RAM + 0x38	; AddrHi
	mov		DPL, RAM + 0x39	; AddrLo
	mov		A, RAM + 0x3a	; Type | Size (0 = 0x10)
	anl		A, #0x0f
	jnz		size_ok
	mov		A, #0x10		; forced to 0x10 bytes (max)
size_ok:
	mov		R2, A
	mov		R0, #(RAM + 0x38)
	mov		A, RAM + 0x3a
	jnb		ACC.7, flash_loop 
	setb	INFEN
flash_loop:
	movx    A, @DPTR
	mov		@R0, A
	inc		DPTR
	inc		R0
	djnz	R2, flash_loop
	clr		INFEN
	ljmp	ADDR_ORIG_END
not_kiwi:
	mov		R7, #2			; HIDPP_ERR_INVALID_ADDRESS
	ljmp	ADDR_ORIG_ERROR