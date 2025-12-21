---
title: ChameleonMini RevE - ATxmega32A4U
categories:
  - electronic
  - mcu
  - Microchip & Atmel
tags:
  - Chameleon
  - Microchip
  - Atmel
  - xmega
---
## Normal flashing

_Work In Progress_

## DFU

### Patching firmware

Official documentation, sources & pre-compiled bootloaders for DFU modes for the `XMEGA` family, including our `ATxmega32A4U`, is available at <https://www.microchip.com/en-us/application-notes/an8429>.
In the application note, `PC3` is the default pin for `ATxmega32A4U` used to detect if DFU must be enabled at startup.

Unfortunately, ChameleonMini is not using `PC3`, but `PA6`. Instead of rebuilding it (project is for IAR compiler, not free), we can _patch_ the official binary file `atxmega32a4u_104.hex`

#### Values

From: `common/services/usb/class/dfu_flip/device/bootloader/xmega/conf/conf_isp.h`:

| Model                           | ISP_PORT_DIR | ISP_PORT_PINCTRL | ISP_PORT_IN | ISP_PORT_PIN | Friendly Name |
|---------------------------------|--------------|------------------|-------------|--------------|---------------|
| XMEGA_A1U                       | PORTF_DIR    | PORTF_PIN5CTRL   | PORTF_IN    | 0            | PF0           |
| XMEGA_A3U, XMEGA_A3BU, XMEGA_C3 | PORTE_DIR    | PORTE_PIN5CTRL   | PORTE_IN    | 5            | PE5           |
| XMEGA_A4U, XMEGA_C4             | PORTC_DIR    | PORTC_PIN3CTRL   | PORTC_IN    | 3            | PC3           |
| XMEGA_B                         | PORTC_DIR    | PORTC_PIN6CTRL   | PORTC_IN    | 6            | PC6           |

> [!bug]
> It seems that the definition for `XMEGA_A1U` is incorrect, `ISP_PORT_PIN` is set to `0` : `ISP_PORT_PINCTRL` should be `PORTF_PIN0CTRL` (not `PORTF_PIN5CTRL`).
> In addition, documentation is about a non existent default pin `PF10` (Table 5-1), it should be `PF0` ( <https://microchip.my.site.com/s/article/AVR1916---Default-pin-configuration-for-boot-loader--ATxmega128A1U> )

We are not concerned about it here, as we're working on a `ATxmega32A4U`, using `PC3` by default to switch to DFU mode - confirmed by the `conf_isp.h` header.
`ISP_PORT_*` definitions will be used in the firmware project, only in the file `common/services/isp/flip/xmega/cstartup.s90`:

```
$ grep ISP_PORT_ common/services/isp/flip/xmega/cstartup.s90
        STS   ISP_PORT_DIR, R15
        STS   ISP_PORT_PINCTRL, R16
        LDS   R16,ISP_PORT_IN
        SBRS  R16,ISP_PORT_PIN       // test ISP pin active
        STS   ISP_PORT_PINCTRL, R15
```

5 references to `ISP_PORT_*` to find and replace, but we need to use values and not symbols with the compiled file.

#####  Original

With our MCU header `/lib/avr/include/avr/iox32a4u.h`, for `PC3`:

```
$ grep '#define PORTC_' /lib/avr/include/avr/iox32a4u.h
[...]
#define PORTC_DIR  _SFR_MEM8(0x0640)
#define PORTC_IN  _SFR_MEM8(0x0648)
#define PORTC_PIN3CTRL  _SFR_MEM8(0x0653)
```

We know we have at least 5 places in the firmware related to `PC3`, with values:

- `0x640` - `PORTC_DIR` / `ISP_PORT_DIR`
- `0x653` - `PORTC_PIN3CTRL` (2x) / `ISP_PORT_PINCTRL`
- `0x648` - `PORTC_IN` / `ISP_PORT_IN`
- `0x3` - _bit position for pin \#3_ / `ISP_PORT_PIN`

##### New

With our MCU header `/lib/avr/include/avr/iox32a4u.h`, for new `PA6`:

```
$ grep '#define PORTA_' /lib/avr/include/avr/iox32a4u.h
[...]
#define PORTA_DIR  _SFR_MEM8(0x0600)
#define PORTA_IN  _SFR_MEM8(0x0608)
#define PORTA_PIN6CTRL  _SFR_MEM8(0x0616)
```

We know we have at least 5 places in the firmware to replace for `PA6`, with values:

- `0x600` - `PORTA_DIR` / `ISP_PORT_DIR`
- `0x616` - `PORTA_PIN6CTRL` (2x) / `ISP_PORT_PINCTRL`
- `0x608` - `PORTA_IN` / `ISP_PORT_IN`
- `0x6` - _bit position for pin \#6_ / `ISP_PORT_PIN`

#### Patch

Let's check values from the original firmware binary before:

```
$ srec_info atxmega32a4u_104.hex -intel
Format: Intel Hexadecimal (MCS-86)
Execution Start Address: 00008000
Data:   8000 - 81A5
        81F4 - 8FB5

$ srec_cat atxmega32a4u_104.hex -intel -crop 0x800c 0x800e 0x8012 0x8014 0x801e 0x8020 0x8020 0x8021 0x80e0 0x80e2 -o - -hex_dump
00008000:                                     40 06        #            @.
00008010:       53 06                               48 06  #  S.          H.
00008020: 03                                               #.
000080E0: 53 06                                            #S.
```

Then we can replace them:

```
srec_cat atxmega32a4u_104.hex -intel -exclude 0x800c 0x800e 0x8012 0x8014 0x801e 0x8020 0x8020 0x8021 0x80e0 0x80e2 \
  -generate 0x800c 0x800e               -constant_little_endian 0x600 2 \
  -generate 0x8012 0x8014 0x80e0 0x80e2 -constant_little_endian 0x616 2 \
  -generate 0x801e 0x8020               -constant_little_endian 0x608 2 \
  -generate 0x8020 0x8021               -constant_little_endian 0x6   1 \
  -o atxmega32a4u_104_PA6.hex -intel
```

Patched DFU bootloader firmware is: `atxmega32a4u_104_PA6.hex`

## Programming

### `flip2` (dfu)

#### Check connection

```
> avrdude -c flip2 -p ATxmega32A4U -v
[...]
Using port            : usb
Using programmer      : flip2
AVR part              : ATxmega32A4U
Programming modes     : SPM, PDI
Programmer type       : flip2
Description           : FLIP bootloader using USB DFU v2 (AVR4023)
    USB Vendor          : 0x03EB
    USB Product         : 0x2FE4
    USB Release         : 0.0.4
    Part signature      : 0x1E9541
    Part revision       : E
    Bootloader version  : 2.0.4
    USB max packet size : 64

AVR device initialized and ready to accept instructions
Device signature = 1E 95 41 (ATxmega32A4U, ATxmega32A4)
```

### `pickit4_isp` or `avrispmkII`

> Original fuses
> 
> | Fuse Name | Value |
> |-----------|-------|
> | FUSE0     | 0xff  |
> | FUSE1     | 0x00  |
> | FUSE2     | 0xbe  |
> | FUSE4     | 0xfe  |
> | FUSE5     | 0xec  |
> | LOCK      | 0xff  |
> 
> You can check them with:
> - version < 8.0: `avrdude -c avrispmkii -p ATxmega32A4U -U fuse0:r:-:h -U fuse1:r:-:h -U fuse2:r:-:h -U fuse4:r:-:h -U fuse5:r:-:h -U lock:r:-:h`
> - version >= 8.0: `avrdude -c avrispmkii -p ATxmega32A4U -U fuse0,fuse1,fuse2,fuse4,fuse5,lock:r:-:h`

#### Check connection

```
> avrdude -c avrispmkii -p ATxmega32A4U -v
[...]
Using port            : usb
Using programmer      : avrispmkII
Usbdev_open(): found AVRISP mkII, serno: 001D2C990079
AVR part              : ATxmega32A4U
Programming modes     : SPM, PDI
Programmer type       : STK500V2
Description           : USB Atmel AVR ISP mkII
Programmer model      : AVRISP mkII
HW version            : 1
Serial number         : 001D2C990079
FW Version Controller : 1.24
Vtarget               : 3.2 V
SCK period            : 8.0 us
Silicon revision: 0.4

AVR device initialized and ready to accept instructions
Device signature = 1E 95 41 (ATxmega32A4U, ATxmega32A4)
```

#### Before flashing

> Make backup before any write operation: `avrdude -c avrispmkii -p ATxmega32A4U -U flash:r:backup_flash.hex:i -U eeprom:r:backup_eeprom.hex:i`  
> You can restore the flash by: `avrdude -c avrispmkii -p ATxmega32A4U -e -U flash:w:backup_flash.hex:i -U eeprom:w:backup_flash.hex:i`

> NOTE: The `-e` will erase the `eeprom` too (if previous fuses values were wrong, it may be not erased, feel free to check with: `avrdude -c avrispmkii -p ATxmega32A4U -U eeprom:r:-:h` before trying again)

#### Flash new firmware

```
avrdude -c avrispmkii -p ATxmega32A4U -e -U flash:w:ChameleonMini.hex:i -U flash:w:atxmega32a4u_104_PA6.hex:i -U eeprom:w:ChameleonMini.eep:i -U fuse0:w:0xff:m -U fuse1:w:0x00:m -U fuse2:w:0xbe:m -U fuse4:w:0xfe:m -U fuse5:w:0xec:m -U lock:w:0xff:m
```

or with all combined (`avrdude` version >= 8.0):

```
avrdude -c avrispmkii -p ATxmega32A4U -e -U flash,eeprom,fuse0,fuse1,fuse2,fuse4,fuse5,lock:w:ChameleonMini-bootloaderdfu_eeprom_fuses_lock.hex:i
```

> You can produce this combined file (`ChameleonMini-bootloaderdfu_eeprom_fuses_lock.hex`) with eeprom, fuses & lock with:
> - From the patched DFU firmware (`atxmega32a4u_104_PA6.hex`)
> ```
> srec_cat -output ChameleonMini-bootloaderdfu_eeprom_fuses_lock.hex -intel \
>   ChameleonMini.hex -intel \
>   atxmega32a4u_104_PA6.hex -intel \
>   ChameleonMini.eep -intel -offset 0x810000 \
>   -generate 0x820000 0x820003 -repeat_data 0xff 0x00 0xbe \
>   -generate 0x820004 0x820006 -repeat_data 0xfe 0xec \
>   -generate 0x830000 0x830001 -constant 0xff
> ```
> - From the unpatched DFU firmware (`atxmega32a4u_104.hex`)
> ```
> srec_cat -output ChameleonMini-bootloaderdfu_eeprom_fuses_lock.hex -intel \
>   ChameleonMini.hex -intel \
>   atxmega32a4u_104.hex -intel -exclude 0x800c 0x800e 0x8012 0x8014 0x801e 0x8020 0x8020 0x8021 0x80e0 0x80e2 \
>   -generate 0x800c 0x800e               -constant_little_endian 0x600 2 \
>   -generate 0x8012 0x8014 0x80e0 0x80e2 -constant_little_endian 0x616 2 \
>   -generate 0x801e 0x8020               -constant_little_endian 0x608 2 \
>   -generate 0x8020 0x8021               -constant_little_endian 0x6   1 \
>   ChameleonMini.eep -intel -offset 0x810000 \
>   -generate 0x820000 0x820003 -repeat_data 0xff 0x00 0xbe \
>   -generate 0x820004 0x820006 -repeat_data 0xfe 0xec \
>   -generate 0x830000 0x830001 -constant 0xff
> ```

## References

- <https://www.microchip.com/en-us/product/atxmega32a4u>
- <https://www.microchip.com/en-us/application-notes/an8429>
- <https://github.com/iceman1001/ChameleonMini-rebooted>
- <https://github.com/emsec/ChameleonMini>
- <https://github.com/RfidResearchGroup/ChameleonMini>
