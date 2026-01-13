---
title: Crazyradio PA
categories:
  - electronic
  - mcu
  - Nordic
tags:
  - Nordic
  - nrf24lu1+
---

## Chip

`nrf24lu1+`

## Programming connector
```
                SCK  MOSI MISO
          PROG _    |  |  |    _ CS
                \---|--|--|---/
 USB <]        | 2  4  6  8  10|        (>  SMA /
               | 1  3  5  7  9 |        (>  ANTENNA
               _/---|--|--x---\_
           +5V      |  |         GND
                RESET  +3V3
```

## References

- <https://www.bitcraze.io/products/crazyradio-pa/>