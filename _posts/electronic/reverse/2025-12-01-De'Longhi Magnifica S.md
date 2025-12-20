---
title: De'Longhi Magnifica S
categories:
  - electronic
  - reverse
tags:
  - delonghi
  - magnifica
  - 5213223671-16
  - microchip
  - pic18lf2525
  - pickit
  - crc16_delonghi
---

![](/assets/img/electronic_magnifica_s_power_board.jpg)

## Hardware

There are many other models - I was on a `5213223671-16`, software version `02.2.000`.

### MCU

Microchip PIC18LF2525 - <https://www.microchip.com/en-us/product/PIC18F2525>

![](/assets/img/electronic_magnifica_s_power_board_PIC18LF2525.png)

| PIN | Function      |
|:---:|---------------|
|  1  | MCLR/VPP      |
|  19 | VSS (Ground)  |
|  20 | VDD           |
|  27 | PGC (ICSPCLK) |
|  28 | PGD (ICSPDAT) |

![](/assets/img/electronic_magnifica_s_power_board_PIC18LF2525_pinout.jpg)

### PICkit 4

Microchip PICkit 4 (or +) - <https://www.microchip.com/en-us/development-tool/pg164140>

![](/assets/img/electronic_magnifica_s_power_board_pickit4.jpg)

| PIN | Function |
|:---:|----------|
|  1  | NMCLR    |
|  2  | VDD      |
|  3  | Ground   |
|  4  | PGD      |
|  5  | PGC      |

## Firmware

### Dump

MPAB IPE - https://www.microchip.com/en-us/tools-resources/production/mplab-integrated-programming-environment
_included in MPLAB X IDE - https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide _

If not already in `Advanced Mode`, `Settings / Advanced Mode` (default password is `microchip`)

> [!warning]
> Do **NOT** power circuit from programmer: `Power / Power target circuit from PICkit 4: unchecked`
> Machine is already powered from general power supply

![](/assets/img/electronic_magnifica_s_power_board_pickit4_dump.png)

> [!tip]
> To export in Intel `.hex` format : `Production / Allow Export Hex`, then `File / Export Hex`

### Reverse

![](/assets/img/electronic_magnifica_s_firmware_ghidra.jpg)

#### Data & CRC-16

Reversing PIC is hard to me, but:

- State is stored in `EEPROM` @ address `0xf00000` ;
   ![](/assets/img/electronic_magnifica_s_power_board_PIC18LF2525_eeprom_dump.png)
   - Using `void eeprom_write(uchar address,uchar value)` & `uchar eeprom_read(uchar address)`
- When all is ok, there is 3 information blocks - each repeated 2 times (data are variable according to your coffee machine usage & settings)
   1.  `03 1a 18 50 3d 37 4c 4c 00 ec 6a 00 02 01 10 00 00 00 [fe a9]`
   2. `40 02 00 3c 00 55 00 78 00 be 00 fa 96 02 bc 00 a0 00 a0 [c6 5a]`
   3. `00 00 14 28 fe 37 2c e0 00 03 00 5f e1 c0 00 00 00 00 00 00 00 [c5 06]`
- Last two bytes (inside `[]`) are part of a checksum on previous bytes
   -  It seems to be a `CRC-16, poly 0x8005, initial value 0x3fc` (algorithm validated against other models)
   - Python snippet, with sample data:

```python
# CRC-16, Poly 0x8005, Init: 0x3fc
def crc16_delonghi(data: bytes):
    crc = 0x03fc
    for o in data:
        crc ^= o << 8
        for i in range(8):
            if (crc & 0x8000) > 0:
                crc = (crc << 1) ^ 0x8005
            else:
                crc <<= 1
    return crc & 0xffff

def pretty_crc16_delonghi(string):
    input = bytes.fromhex(string)
    output = crc16_delonghi(input)
    print('CRC: {} for {}'.format(hex(output), string))


if __name__ == '__main__':
    '''
    03 1a 18 50 3d 37 4c 4c 00 ec 6a 00 02 01 10 00 00 00 [fe a9]
    40 02 00 3c 00 55 00 78 00 be 00 fa 96 02 bc 00 a0 00 a0 [c6 5a]
    00 00 14 28 fe 37 2c e0 00 03 00 5f e1 c0 00 00 00 00 00 00 00 [c5 06]
    '''
    pretty_crc16_delonghi('03 1a 18 50 3d 37 4c 4c 00 ec 6a 00 02 01 10 00 00 00')
    pretty_crc16_delonghi('40 02 00 3c 00 55 00 78 00 be 00 fa 96 02 bc 00 a0 00 a0')
    pretty_crc16_delonghi('00 00 14 28 fe 37 2c e0 00 03 00 5f e1 c0 00 00 00 00 00 00 00')
```

   - Results:

```
CRC: 0xfea9 for 03 1a 18 50 3d 37 4c 4c 00 ec 6a 00 02 01 10 00 00 00
CRC: 0xc65a for 40 02 00 3c 00 55 00 78 00 be 00 fa 96 02 bc 00 a0 00 a0
CRC: 0xc506 for 00 00 14 28 fe 37 2c e0 00 03 00 5f e1 c0 00 00 00 00 00 00 00
```

### Data (work in progress)

> [!information] work in progress

#### Sticker

```
ECAM22.110.B / 04928 / S11
5213223671-16
521322367116'2048524676'022000
```

#### Data interpretation

```
00 15 1B 50 33 3E 3F 4C 00 EC 65 00 02 02 10 000000 [4017]
4002003C0055007800BE00FA9602BC00A000A0 [C65A]
196C 0C 41 FE3E 2E2A 0003 00625585 00000000000000 [CE4C]
```

```
    2E2A = 11818 Coffees
    0003 =     3 Descalings
00625585 = 6444421, * 0,0005 = 3222 liters of waters (n * 0.5 dcl, or / 2000)
```