---
title: Arduino Uno R3 - ATmega16U2 (USB part)
categories:
  - electronic
  - mcu
  - Microchip & Atmel
tags:
  - Chameleon
  - Microchip
  - Atmel
  - Atmega
  - ATmega16U2
  - Arduino
---

This part is the adapter used in front of the _real_ `ATmega328P` running our Arduino software.  
In the Uno R3 case, this adapter is an `ATmega16U2` (16 KB) with specialized firmwares to be able to interact with the `ATmega328P`.  
`ATmega328P` (UART) ↔ `ATmega16U2` (USB) ↔ our computer, and this chip also facilitates flashing new programs onto the `ATmega328P`.

> You can find information about `ATmega328P` on the Arduino Uno R3: [Arduino Uno R3 - ATmega328P](Arduino-Uno-R3-ATmega328P.html)

You can find original firmwares in:
- `%localappdata%\Arduino15\packages\arduino\hardware\avr\<version>\firmwares\atmegaxxu2`
- <https://github.com/arduino/ArduinoCore-avr/tree/master/firmwares/atmegaxxu2>

The firmware files are organized as follows:
- USB to Serial part is in `arduino-usbserial` directory, built firmware is : [`Arduino-usbserial-atmega16u2-Uno-Rev3.hex`](https://raw.githubusercontent.com/arduino/ArduinoCore-avr/refs/heads/master/firmwares/atmegaxxu2/arduino-usbserial/Arduino-usbserial-atmega16u2-Uno-Rev3.hex)
- USB DFU part is in `arduino-usbdfu` directory, **firmware is not precompiled**.

For convenience, they are merged in: [`Arduino-COMBINED-dfu-usbserial-atmega16u2-Uno-Rev3.hex`](https://raw.githubusercontent.com/arduino/ArduinoCore-avr/refs/heads/master/firmwares/atmegaxxu2/Genuino-COMBINED-dfu-usbserial-atmega16u2-Uno-R3.hex)  
Both are _inspired_ by [LUFA](https://github.com/abcminiuser/lufa) ([`Projects/USBtoSerial`](https://github.com/abcminiuser/lufa/tree/master/Projects/USBtoSerial) & [`Bootloaders/DFU`](https://github.com/abcminiuser/lufa/tree/master/Bootloaders/DFU))

> The DFU firmware is inside `Arduino-COMBINED-dfu-usbserial-atmega16u2-Uno-Rev3.hex`  
> You can extract the original DFU firmware part with: `srec_cat -output Arduino-dfu-atmega16u2-Uno-Rev3.hex -intel Arduino-COMBINED-dfu-usbserial-atmega16u2-Uno-Rev3.hex -intel -exclude 0x0000 0x3000`  
> The DFU firmware alone is now located in the `Arduino-dfu-atmega16u2-Uno-Rev3.hex` file.

With default fuses values, the memory map for Intel HEX files is:

| Start      | End        | Size      | Section              | Contents                          |
|------------|------------|-----------|----------------------|-----------------------------------|
| `0x000000` | `0x003fff` | 16 KB     | Flash (_see below_)  | User program + Bootloader         |
| `0x000000` | `0x002fff` | 12 KB     | Flash (Program)      | User program code                 |
| `0x003000` | `0x003fff` | 4 KB      | Flash (Bootloader)   | Bootloader code                   |
| `0x810000` | `0x8101ff` | 512 bytes | EEPROM               | User data                         |
| `0x820000` | `0x820002` | 3 bytes   | Fuses                | Low, High, and Extended fuse bits |
| `0x830000` | `0x830000` | 1 byte    | Lock Bits            | Protection flags                  |

> You can see other values in the datasheet:
> - `ATmega16U2` uses an addressing mode in `words` (16 bits), not `bytes` (8 bits): so bootloader start at `0x1800` in words... but also  `0x3000` in bytes
> - EEPROM is not really @ `0x810000`, as fuses or lock, but programmer softwares are using different addresses to not mix different memory areas.
> 
> Technically, an `ATmega8U2` (8 KB) would have been enough: 4 KB of program code + 4 KB of bootloader code.

## Building firmwares

You can build a fixed DFU firmware, and a new version of USBtoSerial thank to:
- LUFA: <https://github.com/abcminiuser/lufa>
- A patch adjusting LUFA to Arduino Uno R3 use case: [`lufa_usbtoserial_dfu.patch`](/assets/downloads/arduino_uno_r3/atmega16u2/lufa_usbtoserial_dfu.patch)

```
sudo apt update
sudo apt upgrade --assume-yes
sudo apt install build-essential avr-libc binutils-avr gcc-avr srecord git
```

```
git clone https://github.com/abcminiuser/lufa.git
cd lufa
git apply --whitespace=nowarn --verbose ../lufa_usbtoserial_dfu.patch
make --directory=Bootloaders/DFU
make --directory=Projects/USBtoSerial
srec_info Projects/USBtoSerial/USBtoSerial.hex -intel Bootloaders/DFU/BootloaderDFU.hex -intel
```

> You now need an external programmer (not `flip1`) in order to replace bootloader (DFU), see below.

## Programming

Tested with `flip1` (with limitations), `avrispmkII` & `pickit4_isp`

### `flip1` (dfu)

#### Notes

The DFU mode is available by making contact between `GND` (6) and `RESET` (5) pins (then release) on the `ATmega16U2` ISP connector (top right). Then flashing is available by USB - no hardware programmer needed.

```
      -------
 GND | 6.↔.5 | RESET
MOSI | 4. .3 | CLK
 VCC | 2. .1 | MISO
      -------
```
Do **not** use the Arduino header or the Arduino ISP connector (bottom of the board)

In DFU mode, only flash & eeprom memories are available (and the bootloader part is not writable).

Original Arduino DFU firmware is **incorrect**, returning an incorrect device signature to the programmer:
- KO - `avrdude` - checking device signature ;
  - OK - ...when ignoring bad signature with `-F` parameter ;
- OK - `dfu-programmer` - not checking device signature ;
- OK - Atmel Flip - not checking device signature ;
- KO - Microchip studio - checking device signature.

```
> avrdude -v -c flip1 -p ATmega16U2
[...]
AVR device initialized and ready to accept instructions
Device signature = 94 00 00
Error: expected signature for ATmega16U2 is 1E 94 89
  - double check chip or use -F to carry on regardless
[...]
```

> DFU firmware problem was fixed in 2013/2015 in the LUFA project ( <https://github.com/abcminiuser/lufa> ).  
> Bonus: TX/RX leds are now flashing to show we're in DFU mode :)

Windows user: Atmel DFU driver can be found in Microchip Studio or FLIP, but is available here for convenience: [`atmel_usb_dfu_driver.zip`](/assets/downloads/atmel_usb_dfu_driver.zip) (it's only a libusb wrapper)

#### Before flashing

Make backup before any write operation: `avrdude -c flip1 -p ATmega16U2 -F -U flash:r:backup_flash.hex:i`  
You can restore the flash by: `avrdude -c flip1 -p ATmega16U2 -F -U flash:w:backup_flash.hex:i`

#### Flash

As bootloader part is not writable in DFU mode, you can _only_ flash the firmware part `usbserial` inside the chip (by forcing using `-F` parameter when using original bootloader):

```
> avrdude -v -c flip1 -p ATmega16U2 -F -U flash:w:Arduino-usbserial-atmega16u2-Uno-Rev3.hex:i
[...]
AVR device initialized and ready to accept instructions
Device signature = 94 00 00
Warning: expected signature for ATmega16U2 is 1E 94 89
Auto-erasing chip as flash memory needs programming (-U flash:w:...)
specify the -D option to disable this feature
Erased chip
Reading 4034 bytes for flash from input file Arduino-usbserial-atmega16u2-Uno-Rev3.hex
in 1 section [0, 0xfc1]: 32 pages and 62 pad bytes
Writing 4034 bytes to flash
Writing | ################################################## | 100% 0.31 s
Reading | ################################################## | 100% 0.04 s
4034 bytes of flash verified
[...]
```

When using fixed bootloader:

```
> avrdude -v -c flip1 -p ATmega16U2 -U flash:w:USBtoSerial.hex:i
[...]
AVR device initialized and ready to accept instructions
Device signature = 1E 94 89 (ATmega16U2)
Auto-erasing chip as flash memory needs programming (-U flash:w:...)
specify the -D option to disable this feature
Erased chip
Reading 3968 bytes for flash from input file USBtoSerial.hex
in 1 section [0, 0xf7f]: 31 pages and 0 pad bytes
Writing 3968 bytes to flash
Writing | ################################################## | 100% 0.31 s
Reading | ################################################## | 100% 0.05 s
3968 bytes of flash verified
[...]
```

### `pickit4_isp` or `avrispmkII`

#### Notes

When using a hardware programmer, connect it to the `ATmega16U2` ISP connector (located at the top right)
```
      -----
 GND |6. .5| RESET
MOSI |4. .3| CLK
 VCC |2. .1| MISO
      -----
```

When using a programmer, you can interact with fuses, lock, eeprom, and bootloader part of flash

When using `pickit4`, you may need to switch mode to `avr`:  `avrdude -c pickit4_isp -p ATmega16U2 -x mode=avr` (`-x mode=pic` to switch back)

Original fuses

| Fuse Name | Value |
|-----------|-------|
| LOW       | 0xef  |
| HIGH      | 0xd9  |
| EXTENDED  | 0xf4  |
| LOCK      | 0xcf  |

- Bootloader 2048 words (4 KB when in bytes), @ 0x1800 (0x3000 when in bytes)
- LPM and SPM prohibited in Boot Section

You can check them with:
- version < 8.0: `avrdude -c pickit4_isp -p ATmega16U2 -U lfuse:r:-:h -U hfuse:r:-:h -U efuse:r:-:h -U lock:r:-:h`
- version >= 8.0: `avrdude -c pickit4_isp -p ATmega16U2 -U lfuse,hfuse,efuse,lock:r:-:h`

#### Check connection

```
> avrdude -c pickit4_isp -p ATmega16U2 -v
[...]
Using port            : usb
Using programmer      : pickit4_isp
AVR part              : ATmega16U2
Programming modes     : SPM, ISP, HVPP, debugWIRE
Programmer type       : JTAG3_ISP
Description           : MPLAB(R) PICkit 4 in ISP mode
ICE HW version        : 6
ICE FW version        : 1.15 (rel. 20)
Serial number         : BUR222474515
Vtarget               : 0.0 V
SCK period            : 8.0 us
Vtarget               : 5.01 V

AVR device initialized and ready to accept instructions
Device signature = 1E 94 89 (ATmega16U2)
[...]
```

#### Before flashing

Make backup before any write operation: `avrdude -c pickit4_isp -p ATmega16U2 -U flash:r:backup_flash.hex:i`  
You can restore the flash by: `avrdude -c pickit4_isp -p ATmega16U2 -e -U flash:w:backup_flash.hex:i`

The `-e` will erase the `eeprom` too (if previous fuses values were wrong, it may be not erased, feel free to check with: `avrdude -c pickit4_isp -p ATmega16U2 -U eeprom:r:-:h` before trying again)

#### Flash original firmware

even if the original DFU firmware part isn't perfect, it's enough to have something working

```
avrdude -c pickit4_isp -p ATmega16U2 -e -U flash:w:Arduino-COMBINED-dfu-usbserial-atmega16u2-Uno-Rev3.hex:i -U lfuse:w:0xef:m -U hfuse:w:0xd9:m -U efuse:w:0xf4:m -U lock:w:0xcf:m
```

or with all combined (`avrdude` version >= 8.0):

```
avrdude -c pickit4_isp -p ATmega16U2 -e -U flash,lfuse,hfuse,efuse,lock:w:Arduino-COMBINED-dfu-usbserial-atmega16u2-Uno-Rev3_fuses_lock.hex:i
```

> You can produce this combined file with fuses & lock with:
> ```
> srec_cat -output Arduino-COMBINED-dfu-usbserial-atmega16u2-Uno-Rev3_fuses_lock.hex -intel ^
>   Arduino-COMBINED-dfu-usbserial-atmega16u2-Uno-Rev3.hex -intel ^
>   -generate 0x820000 0x820003 -repeat_data 0xef 0xd9 0xf4 ^
>   -generate 0x830000 0x830001 -constant 0xcf
> ```
> You can add `-generate 0x810000 0x810200 -constant 0xff ^` before the first `-generate` if you **really** want the EEPROM data (normally erased when programming)

#### Flash fixed firmware

Files: [`USBtoSerial.hex`](/assets/downloads/arduino_uno_r3/atmega16u2/USBtoSerial.hex) & [`BootloaderDFU.hex`](/assets/downloads/arduino_uno_r3/atmega16u2/BootloaderDFU.hex)

```
avrdude -c pickit4_isp -p ATmega16U2 -e -U flash:w:USBtoSerial.hex:i -U flash:w:BootloaderDFU.hex:i -U lfuse:w:0xef:m -U hfuse:w:0xd9:m -U efuse:w:0xf4:m -U lock:w:0xcf:m
```

or with all combined (`avrdude` version >= 8.0):

File: [`usbserial-bootloaderdfu_fuses_lock.hex`](/assets/downloads/arduino_uno_r3/atmega16u2/usbserial-bootloaderdfu_fuses_lock.hex)

```
avrdude -c pickit4_isp -p ATmega16U2 -e -U flash,lfuse,hfuse,efuse,lock:w:usbserial-bootloaderdfu_fuses_lock.hex:i
```

> You can produce this combined file with fuses & lock with:
> ```
> srec_cat -output usbserial-bootloaderdfu_fuses_lock.hex -intel ^
>   USBtoSerial.hex -intel ^
>   BootloaderDFU.hex -intel ^
>   -generate 0x820000 0x820003 -repeat_data 0xef 0xd9 0xf4 ^
>   -generate 0x830000 0x830001 -constant 0xcf
> ```
> You can add `-generate 0x810000 0x810200 -constant 0xff ^` before the first `-generate` if you **really** want the EEPROM data (normally erased when programming)

## Atmel original DFU

_if you don't want to use the LUFA one..._

I don't have any untouched `ATmega16U2` (aka not related to Arduino), so I'm unable to dump (if any?) original bootloader from it.  
It seems you can find older/other ones in: <https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/SoftwareLibraries/Firmware/megaUSB_DFU_Bootloaders.zip>

Unfortunately, no `ATmega16U2` inside, but a `at90usb162-bl-usb-1_0_5.hex` for a [`AT90USB162`](https://www.microchip.com/en-us/product/at90usb162).  
As the `ATmega16U2` is an optimized version of the `AT90USB162`, **we can use this bootloader as-is** with various programmer software (including `avrdude` by forcing).

**For convenience**, I patched (PID & Product) it to create a new [`atmega16u2-bl-usb-1_0_5.hex`](/assets/downloads/arduino_uno_r3/atmega16u2/atmega16u2-bl-usb-1_0_5.hex), the result is:

```
> avrdude -c flip1 -p ATmega16U2 -v
[...]
Using port            : usb
Using programmer      : flip1
AVR part              : ATmega16U2
Programming modes     : SPM, ISP, HVPP, debugWIRE
Programmer type       : flip1
Description           : FLIP bootloader using USB DFU v1 (doc7618)
    USB Vendor          : ATMEL (0x03EB)
    USB Product         : ATmega16U2 DFU (0x2FEF)
    USB Release         : 0.0.0
    USB Serial No       : 1.0.5
    USB max packet size : 32

AVR device initialized and ready to accept instructions
Device signature = 1E 94 89 (ATmega16U2)
```

## References

### ATmega / Microchip
- ATmega16U2: <https://www.microchip.com/en-us/product/atmega16u2>
- AVR4023 - FLIP USB DFU Protocol: <https://www.microchip.com/en-us/application-notes/an8457>
- USB DFU Bootloader Datasheet: <https://ww1.microchip.com/downloads/en/DeviceDoc/doc7618.pdf>
- megaAVR DFU USB Bootloaders (no `ATmega16U2` inside): <https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/SoftwareLibraries/Firmware/megaUSB_DFU_Bootloaders.zip>
- AVR530 - Migrating from AT90USB162/82 to ATmega16U2/8U2: <https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ApplicationNotes/ApplicationNotes/doc8224.pdf>

### Arduino
- Flash the USB-to-serial firmware for UNO (Rev3 and earlier) and Mega boards: <https://support.arduino.cc/hc/en-us/articles/4408887452434-Flash-the-USB-to-serial-firmware-for-UNO-Rev3-and-earlier-and-Mega-boards>
- Set the Atmega16U2/8U2 chip on UNO (Rev3 or earlier) and Mega boards to DFU mode: <https://support.arduino.cc/hc/en-us/articles/4410804625682-Set-the-Atmega16U2-8U2-chip-on-UNO-Rev3-or-earlier-and-Mega-boards-to-DFU-mode>
- Arduino USB 2 Serial Micro: <https://docs.arduino.cc/retired/boards/arduino-usb-2-serial-micro/>

### SRecord
- SRecord (version 1.65 used here): <https://srecord.sourceforge.net/>

### LUFA
- LUFA (The Lightweight USB Framework for AVRs): <https://github.com/abcminiuser/lufa>

### Programmers

#### Hardware
- Pickit 4: <https://www.microchip.com/en-us/development-tool/pg164140>
- AVRISP MKII : <https://www.microchip.com/en-us/development-tool/atavrisp2>

#### Software
- AVRDUDE (version 8.0 used here): <https://github.com/avrdudes/avrdude>
- dfu-programmer: <https://github.com/dfu-programmer/dfu-programmer>
- Microchip Studio: <https://www.microchip.com/en-us/tools-resources/develop/microchip-studio>
- FLIP (requires JRE) : <https://www.microchip.com/en-us/development-tool/flip>
- MPLAB X IDE (includes IPE): <https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide>