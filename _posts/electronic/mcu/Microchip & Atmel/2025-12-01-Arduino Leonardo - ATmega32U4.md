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
  - ATmega32U4
  - Arduino
---

> [!attention]
> Work in progress

`%localappdata%\Arduino15\packages\arduino\hardware\avr\<version>\bootloaders\caterina`

`Caterina-Leonardo.hex`

```
> avrdude -c avr109 -P COM11 -r -p atmega32u4 -v
[...]
Touching serial port COM11 at 1200 baud
Waiting for new port... 450 ms: using new port COM12
Using port            : COM12
Using programmer      : avr109
AVR part              : ATmega32U4
Programming modes     : SPM, ISP, HVPP, JTAG
Programmer type       : butterfly
Description           : Atmel bootloader (AVR109, AVR911)
connecting to programmer: .
Programmer id    = CATERIN; type = S
Software version = 1.0; no hardware version given
programmer supports auto addr increment
programmer supports buffered memory access with buffersize=128 bytes
Devcode selected: 0x44

AVR device initialized and ready to accept instructions
Device signature = 1E 95 87 (ATmega32U4)
[...]
```