---
categories:
  - electronic
  - mcu
  - Microchip & Atmel
tags:
  - Chameleon
  - Microchip
  - Atmel
  - Atmega
  - ATmega328P
  - Arduino
---

This part is about the _real_ `ATmega328P`, with 32 KB of flash, running our Arduino programs/sketches.
In the Uno R3 case, `ATmega328P` does not interact directly with our computer (no USB support), but uses UART communication via the `ATmega16U2` supporting USB (`ATmega328P` (UART) ↔ `ATmega16U2` (USB) ↔ our computer).
The `ATmega328P` uses a minimalist bootloader called `optiboot`, which is slightly under 512 bytes, leaving more space for our programs/sketches, and allows UART flashing via the `ATmega16U2`.

> [!note]
> You can find information about `ATmega16U2` on the Arduino Uno R3: [Arduino Uno R3 - ATmega16U2 (for USB to serial and its DFU)](Arduino%20Uno%20R3%20-%20ATmega16U2%20(for%20USB%20to%20serial%20and%20its%20DFU).md)

You can find original `optiboot` bootloader in :
- `%localappdata%\Arduino15\packages\arduino\hardware\avr\<version>\bootloaders\optiboot`
- https://github.com/arduino/ArduinoCore-avr/tree/master/bootloaders/optiboot

Ressources used are available on: https://github.com/gentilkiwi/attachments/tree/main/blog/arduino_uno_r3/atmega328p

Our Arduino Uno R3 uses `optiboot_atmega328.hex` file, by default in its version `4.4`.

With default fuses values, the memory map for Intel HEX files is:

| Start      | End        | Size      | Section              | Contents                          |
|------------|------------|-----------|----------------------|-----------------------------------|
| `0x000000` | `0x007fff` | 32 KB     | Flash (_see below_)  | User program + Bootloader         |
| `0x000000` | `0x007dff` | 31.5 KB   | Flash (Program)      | User program code                 |
| `0x007e00` | `0x007fff` | 512 bytes | Flash (Bootloader)   | Bootloader code                   |
| `0x810000` | `0x8103ff` | 1 KB      | EEPROM               | User data                         |
| `0x820000` | `0x820002` | 3 bytes   | Fuses                | Low, High, and Extended fuse bits |
| `0x830000` | `0x830000` | 1 byte    | Lock Bits            | Protection flags                  |

> [!note]
> You can see other values in the datasheet:
> - `ATmega328P` uses an addressing mode in `words` (16 bits), not `bytes` (8 bits): so bootloader start at `0x3f00` in words... but also  `0x7e00` in bytes
> - EEPROM is not really @ `0x810000`, as fuses or lock, but programmer softwares are using different addresses to not mix different memory areas.

## Building firmware

You can build a new version of Optiboot thanks to: https://github.com/Optiboot/optiboot

```
sudo apt update
sudo apt upgrade --assume-yes
sudo apt install build-essential avr-libc binutils-avr gcc-avr srecord
```

```
git clone https://github.com/Optiboot/optiboot.git
cd optiboot
make --directory=optiboot/bootloaders/optiboot AVR_FREQ=16000000 LED_START_FLASHES=2 atmega328
srec_info optiboot/bootloaders/optiboot/optiboot_atmega328.hex -intel
```

> [!note]
> You now need an external programmer (not `arduino`) in order to replace the bootloader, see below.

## Programming

> [!info]
> Tested with `arduino` (with limitations), `avrispmkII` & `pickit4_isp`

### `arduino`

In this mode, only flash is available (and the bootloader part is not writable).

> [!note]
> This is the normal programming mode used by Arduino IDE (calling an old version of `avrdude`)

#### Check connection

```
> avrdude -c arduino -P COM5 -p ATmega328P -v
[...]
Using port            : COM5
Using programmer      : arduino
AVR part              : ATmega328P
Programming modes     : SPM, ISP, HVPP, debugWIRE
Programmer type       : Arduino
Description           : Arduino bootloader using STK500 v1 protocol
HW Version            : 3
FW Version            : 4.4

AVR device initialized and ready to accept instructions
Device signature = 1E 95 0F (ATmega328P, ATA6614Q, LGT8F328P)
[...]
```

> [!danger]
> Make backup of flash before any write operation: `avrdude -c arduino -P COM5 -p ATmega328P -U flash:r:backup_flash.hex:i`
> You can restore memories `avrdude -c arduino -P COM5 -p ATmega328P -U flash:w:backup_flash.hex:i`

You can flash an application, such as `blink.hex`, with the following command:

```
> avrdude -c arduino -P COM5 -p atmega328p -U flash:w:blink.hex:i
Reading 924 bytes for flash from input file blink.hex
Writing 924 bytes to flash
Writing | ################################################## | 100% 0.18 s
Reading | ################################################## | 100% 0.13 s
924 bytes of flash verified
```

### `pickit4_isp` or `avrispmkII`

#### Notes

>[!note]
> When using a hardware programmer, connect it to the `ATmega328P` ISP connector (located at the bottom middle)
> ```
> RESET  CLK  MISO
>     \---|---/     
>    | 5  3  1 |
>    | 6  4  2 |
>     /---|---\
>   GND  MOSI VCC
> ```

> [!note]
> When using a programmer, you can interact with fuses, lock, eeprom, and bootloader part of flash

> [!note]
> When using `pickit4`, you may need to switch mode to `avr`:  `avrdude -c pickit4_isp -p ATmega328P -x mode=avr` (`-x mode=pic` to switch back)

> [!note]
> Original fuses
> 
> | Fuse Name | Value |
> |-----------|-------|
> | LOW       | 0xff  |
> | HIGH      | 0xde  |
> | EXTENDED  | 0xfd  |
> | LOCK      | 0xcf  |
> 
> - Bootloader 256 words (512 B when in bytes), @ 0x3f00 (0x7e00 when in bytes)
> - LPM and SPM prohibited in Boot Section
> 
> You can check them with:
> - version < 8.0: `avrdude -c pickit4_isp -p ATmega328P -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h`
> - version >= 8.0: `avrdude -c pickit4_isp -p ATmega328P -U lfuse,hfuse,efuse,lock:r:-:h`

#### Check connection

```
> avrdude -c pickit4_isp -p ATmega328P -v
[...]
Using port            : usb
Using programmer      : pickit4_isp
AVR part              : ATmega328P
Programming modes     : SPM, ISP, HVPP, debugWIRE
Programmer type       : JTAG3_ISP
Description           : MPLAB(R) PICkit 4 in ISP mode
ICE HW version        : 6
ICE FW version        : 1.15 (rel. 20)
Serial number         : BUR222474515
Vtarget               : 0.0 V
SCK period            : 8.0 us
Vtarget               : 4.99 V

AVR device initialized and ready to accept instructions
Device signature = 1E 95 0F (ATmega328P, ATA6614Q, LGT8F328P)
[...]
```

#### Before flashing

> [!danger]
> - Make backup before any write operation: `avrdude -c pickit4_isp -p ATmega328P -U flash:r:backup_flash.hex:i`
> - You can restore the flash by: `avrdude -c pickit4_isp -p ATmega328P -e -U flash:w:backup_flash.hex:i`
> - if not using `-D` when writing, flash is erased (including bootloader): do not forget it, or be sure to include bootloader memory.

> [!note]
> The `-e` will erase the `eeprom` too (if previous fuses values were wrong, it may be not erased, feel free to check with: `avrdude -c pickit4_isp -p ATmega328P -U eeprom:r:-:h` before trying again)

#### Flash

Only program

> [!tip]
> Prefer `-c arduino` programming mode when dealing with programs only

```
avrdude -c pickit4_isp -p ATmega328P -D -U flash:w:blink.hex:i
```

Program with bootloader

```
avrdude -c pickit4_isp -p ATmega328P -e -U flash:w:blink.hex:i -U flash:w:optiboot_atmega328.hex:i
```

Program with bootloader & fuses/lock

```
avrdude -c pickit4_isp -p ATmega328P -e -U flash:w:blink.hex:i -U flash:w:optiboot_atmega328.hex:i -U lfuse:w:0xff:m -U hfuse:w:0xde:m -U efuse:w:0xfd:m -U lock:w:0xcf:m
```

or with all combined (`avrdude` version >= 8.0):

```
avrdude -c pickit4_isp -p ATmega328P -e -U flash,lfuse,hfuse,efuse,lock:w:blink_optiboot_fuses_lock.hex:i
```

> [!tip]
> You can produce this combined file with fuses & lock with:
> ```
> srec_cat -output blink_optiboot_fuses_lock.hex -intel ^
>   blink.hex -intel ^
>   optiboot_atmega328.hex -intel ^
>   -generate 0x820000 0x820003 -repeat_data 0xff 0xde 0xfd ^
>   -generate 0x830000 0x830001 -constant 0xcf
> ```
> You can add `-generate 0x810000 0x810200 -constant 0xff ^` before the first `-generate` if you **really** want the EEPROM data (normally erased when programming)

##### New bootloader

If you flashed a new Optiboot bootloader version, you can test it and see new `FW Version`:

```
> avrdude -c arduino -P COM5 -p ATmega328P -v
[...]
Using port            : COM5
Using programmer      : arduino
AVR part              : ATmega328P
Programming modes     : SPM, ISP, HVPP, debugWIRE
Programmer type       : Arduino
Description           : Arduino bootloader using STK500 v1 protocol
HW Version            : 3
FW Version            : 8.3

AVR device initialized and ready to accept instructions
Device signature = 1E 95 0F (ATmega328P, ATA6614Q, LGT8F328P)
[...]
```

## References

### Files used
- gentilkiwi's GitHub: https://github.com/gentilkiwi/attachments/tree/main/blog/arduino_uno_r3/atmega328p

### ATmega / Microchip
- ATmega328P: https://www.microchip.com/en-us/product/atmega328p
- AVR109: Self Programming: https://ww1.microchip.com/downloads/en/Appnotes/doc1644.pdf
- AVR Open-source Programmer: https://www.microchip.com/en-us/application-notes/an2568
- Serial bootloader for tinyAVR and megaAVR devices: https://microchip.my.site.com/s/article/Serial-bootloader-for-tinyAVR-and-megaAVR-devices

### SRecord
- SRecord (version 1.65 used here): https://srecord.sourceforge.net/

### Bootloaders
- Optiboot: https://github.com/Optiboot/optiboot
- Urboot: https://github.com/stefanrueger/urboot

### Programmers

#### Hardware
- Pickit 4: https://www.microchip.com/en-us/development-tool/pg164140
- AVRISP MKII : https://www.microchip.com/en-us/development-tool/atavrisp2

#### Software
- AVRDUDE (version 8.0 used here): https://github.com/avrdudes/avrdude
- Microchip Studio: https://www.microchip.com/en-us/tools-resources/develop/microchip-studio
- MPLAB X IDE (includes IPE): https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide