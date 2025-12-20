---
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

From: `common/services/usb/class/dfu_flip/device/bootloader/xmega/conf/conf_isp.h`:

| Model                           | ISP_PORT_DIR | ISP_PORT_PINCTRL | ISP_PORT_IN | ISP_PORT_PIN | Friendly Name |
|---------------------------------|--------------|------------------|-------------|--------------|---------------|
| XMEGA_A1U                       | PORTF_DIR    | PORTF_PIN5CTRL   | PORTF_IN    | 0            | PF0           |
| XMEGA_A3U, XMEGA_A3BU, XMEGA_C3 | PORTE_DIR    | PORTE_PIN5CTRL   | PORTE_IN    | 5            | PE5           |
| XMEGA_A4U, XMEGA_C4             | PORTC_DIR    | PORTC_PIN3CTRL   | PORTC_IN    | 3            | PC3           |
| XMEGA_B                         | PORTC_DIR    | PORTC_PIN6CTRL   | PORTC_IN    | 6            | PC6           |

> [!bug]
> It seems that the definition for `XMEGA_A1U` is incorrect, `ISP_PORT_PIN` is `0` : `ISP_PORT_PINCTRL` should be `PORTF_PIN0CTRL` (not `PORTF_PIN5CTRL`).
> In addition, documentation is about a non existent `PF10` (Table 5-1).

> [!check]
> We are not concerned about it here, as we're working on `ATxmega128A4U`, using `PC3` by default to switch to DFU mode.

From `common/services/isp/flip/xmega/cstartup.s90`:

```
$ grep ISP_PORT_ common/services/isp/flip/xmega/cstartup.s90
        STS   ISP_PORT_DIR, R15
        STS   ISP_PORT_PINCTRL, R16
        LDS   R16,ISP_PORT_IN
        SBRS  R16,ISP_PORT_PIN       // test ISP pin active
        STS   ISP_PORT_PINCTRL, R15
```

And from previous definitions with `/lib/avr/include/avr/iox32a4u.h`:

```
$ grep '#define PORTC_' /lib/avr/include/avr/iox32a4u.h

#define PORTC_DIR  _SFR_MEM8(0x0640)
[...]
#define PORTC_IN  _SFR_MEM8(0x0648)
[...]
#define PORTC_PIN3CTRL  _SFR_MEM8(0x0653)
```

We know we have at least 5 places in firmwares related to `PC3`, with values:

- `0x640` - `PORTC_DIR` / `ISP_PORT_DIR`
- `0x653` - `PORTC_PIN3CTRL` (2x) / `ISP_PORT_PINCTRL`
- `0x648` - `PORTC_IN` / `ISP_PORT_IN`
- `0x3` - _bit position for pin \#3_ / `ISP_PORT_PIN`

## `ATxmega32A4U`

Official firmware is for `PC3`:

```
> srec_info atxmega32a4u_104.hex -intel
Format: Intel Hexadecimal (MCS-86)
Execution Start Address: 00008000
Data:   8000 - 81A5
        81F4 - 8FB5

> srec_cat atxmega32a4u_104.hex -intel -crop 0x800c 0x800e 0x8012 0x8014 0x801e 0x8020 0x8020 0x8021 0x80e0 0x80e2 -o - -hex_dump
00008000:                                     40 06        #            @.
00008010:       53 06                               48 06  #  S.          H.
00008020: 03                                               #.
000080E0: 53 06                                            #S.
```

For Chameleon Mini revE, we need a bootloader for `PA6`:

```
$ grep '#define PORTA_' /lib/avr/include/avr/iox32a4u.h
#define PORTA_DIR  _SFR_MEM8(0x0600)
[...]
#define PORTA_IN  _SFR_MEM8(0x0608)
[...]
#define PORTA_PIN6CTRL  _SFR_MEM8(0x0616)
```

- `0x600` - `PORTA_DIR`
- `0x616` - `PORTA_PIN6CTRL` (2x)
- `0x608` - `PORTA_IN`
- `0x6` - _bit position for pin \#6_

```
srec_cat atxmega32a4u_104.hex -intel -exclude 0x800c 0x800e 0x8012 0x8014 0x801e 0x8020 0x8020 0x8021 0x80e0 0x80e2 ^
  -generate 0x800c 0x800e               -constant_little_endian 0x600 2 ^
  -generate 0x8012 0x8014 0x80e0 0x80e2 -constant_little_endian 0x616 2 ^
  -generate 0x801e 0x8020               -constant_little_endian 0x608 2 ^
  -generate 0x8020 0x8021               -constant_little_endian 0x6   1 ^
  -o atxmega32a4u_104_PA6.hex -intel
```

## 128

```
> srec_info atxmega128a4u_104.hex -intel
Format: Intel Hexadecimal (MCS-86)
Execution Start Address: 00020000
Data:   020000 - 0201E5
        0201F4 - 0215E1

> srec_cat atxmega128a4u_104.hex -intel -crop 0x2000c 0x2000e 0x20012 0x20014 0x2001e 0x20020 0x20020 0x20021 0x20090 0x20092 -o - -hex_dump
00020000:                                     40 06        #            @.
00020010:       53 06                               48 06  #  S.          H.
00020020: 03                                               #.
00020090: 53 06                                            #S.
```

```
srec_cat atxmega128a4u_104.hex -intel -exclude  0x2000c 0x2000e 0x20012 0x20014 0x2001e 0x20020 0x20020 0x20021 0x20090 0x20092 ^
  -generate 0x2000c 0x2000e                 -constant_little_endian 0x600 2 ^
  -generate 0x20012 0x20014 0x20090 0x20092 -constant_little_endian 0x616 2 ^
  -generate 0x2001e 0x20020                 -constant_little_endian 0x608 2 ^
  -generate 0x20020 0x20021                 -constant_little_endian 0x6   1 ^
  -o atxmega128a4u_104_PA6.hex -intel
```

```
srec_cat atxmega128a4u_104.hex -intel -exclude 0x2000c 0x2000e 0x20012 0x20014 0x2001e 0x20020 0x20020 0x20021 0x20090 0x20092 ^
  -generate 0x2000c 0x2000e                 -constant_little_endian 0x600 2 ^
  -generate 0x20012 0x20014 0x20090 0x20092 -constant_little_endian 0x616 2 ^
  -generate 0x2001e 0x20020                 -constant_little_endian 0x608 2 ^
  -generate 0x20020 0x20021                 -constant_little_endian 0x6   1 ^
  ..\..\..\..\..\atmel\test.hex -intel -offset 0x21fe0 ^
  -o atxmega128a4u_104_PA6_SPM.hex -intel
```



```
srec_cmp -v original\bootloader-atxmega128a4u-104-PA6-SPM.hex -intel -crop 0x21fe0 ..\..\..\..\atmel\test.hex -intel -offset 0x21fe0
```

```
gentilkiwi@rog-k:/mnt/c/security/code/atmel$ cat test.sx
#include <avr/io.h>
#define CCP_SPM_gc      (0x9D<<0) /* SPM instruction protection # TB3262 */

    movw ZL, r24         ; Load R25:R24 into Z.
    sts NVM_CMD, r20     ; Load prepared command into NVM Command register.
    ldi r18, CCP_SPM_gc  ; Prepare Protect SPM signature in R18
    sts CCP, r18         ; Enable SPM operation (this disables interrupts for 4 cycles).
    spm                  ; Self-program.
    clr r1               ; Clear R1 for GCC _zero_reg_ to function properly.
    out RAMPZ, r19       ; Restore RAMPZ register.
    ret
gentilkiwi@rog-k:/mnt/c/security/code/atmel$ avr-gcc -mmcu=atxmega128a4u -nostartfiles -Ttext=0x21fe0 -o test.elf test.sx
gentilkiwi@rog-k:/mnt/c/security/code/atmel$ avr-objcopy -O ihex test.elf test.hex
gentilkiwi@rog-k:/mnt/c/security/code/atmel$ srec_cat test.hex -intel -o - -hex_dump
00021FE0: FC 01 40 93 CA 01 2D E9 20 93 34 00 E8 95 11 24  #|.@.J.-i .4.h..$
00021FF0: 3B BF 08 95                                      #;?..
```

https://www.microchip.com/en-us/application-notes/an8429

https://github.com/iceman1001/ChameleonMini-rebooted
https://github.com/emsec/ChameleonMini
https://github.com/RfidResearchGroup/ChameleonMini


## 128

```
> srec_info atxmega128a4u_104.hex -intel
Format: Intel Hexadecimal (MCS-86)
Execution Start Address: 00020000
Data:   020000 - 0201E5
        0201F4 - 0215E1

> srec_cat atxmega128a4u_104.hex -intel -crop 0x2000c 0x2000e 0x20012 0x20014 0x2001e 0x20020 0x20020 0x20021 0x20090 0x20092 -o - -hex_dump
00020000:                                     40 06        #            @.
00020010:       53 06                               48 06  #  S.          H.
00020020: 03                                               #.
00020090: 53 06                                            #S.
```

```
srec_cat atxmega128a4u_104.hex -intel -exclude  0x2000c 0x2000e 0x20012 0x20014 0x2001e 0x20020 0x20020 0x20021 0x20090 0x20092 ^
  -generate 0x2000c 0x2000e                 -constant_little_endian 0x600 2 ^
  -generate 0x20012 0x20014 0x20090 0x20092 -constant_little_endian 0x616 2 ^
  -generate 0x2001e 0x20020                 -constant_little_endian 0x608 2 ^
  -generate 0x20020 0x20021                 -constant_little_endian 0x6   1 ^
  -o atxmega128a4u_104_PA6.hex -intel
```

```
srec_cat atxmega128a4u_104.hex -intel -exclude 0x2000c 0x2000e 0x20012 0x20014 0x2001e 0x20020 0x20020 0x20021 0x20090 0x20092 ^
  -generate 0x2000c 0x2000e                 -constant_little_endian 0x600 2 ^
  -generate 0x20012 0x20014 0x20090 0x20092 -constant_little_endian 0x616 2 ^
  -generate 0x2001e 0x20020                 -constant_little_endian 0x608 2 ^
  -generate 0x20020 0x20021                 -constant_little_endian 0x6   1 ^
  ..\..\..\..\..\atmel\test.hex -intel -offset 0x21fe0 ^
  -o atxmega128a4u_104_PA6_SPM.hex -intel
```



```
srec_cmp -v original\bootloader-atxmega128a4u-104-PA6-SPM.hex -intel -crop 0x21fe0 ..\..\..\..\atmel\test.hex -intel -offset 0x21fe0
```

```
gentilkiwi@rog-k:/mnt/c/security/code/atmel$ cat test.sx
#include <avr/io.h>
#define CCP_SPM_gc      (0x9D<<0) /* SPM instruction protection # TB3262 */

    movw ZL, r24         ; Load R25:R24 into Z.
    sts NVM_CMD, r20     ; Load prepared command into NVM Command register.
    ldi r18, CCP_SPM_gc  ; Prepare Protect SPM signature in R18
    sts CCP, r18         ; Enable SPM operation (this disables interrupts for 4 cycles).
    spm                  ; Self-program.
    clr r1               ; Clear R1 for GCC _zero_reg_ to function properly.
    out RAMPZ, r19       ; Restore RAMPZ register.
    ret
gentilkiwi@rog-k:/mnt/c/security/code/atmel$ avr-gcc -mmcu=atxmega128a4u -nostartfiles -Ttext=0x21fe0 -o test.elf test.sx
gentilkiwi@rog-k:/mnt/c/security/code/atmel$ avr-objcopy -O ihex test.elf test.hex
gentilkiwi@rog-k:/mnt/c/security/code/atmel$ srec_cat test.hex -intel -o - -hex_dump
00021FE0: FC 01 40 93 CA 01 2D E9 20 93 34 00 E8 95 11 24  #|.@.J.-i .4.h..$
00021FF0: 3B BF 08 95                                      #;?..
```
