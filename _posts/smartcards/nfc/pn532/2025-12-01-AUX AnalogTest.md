---
title: PN532 AUX AnalogTest
categories:
  - smartcards
  - nfc
  - pn532
tags:
  - PN532
  - nfc
  - SPI
  - AUX
  - CIU_AnalogTest
  - TxActive
  - RxActive
---

It can be useful to know when the PN532 is transmitting or receiving. For better oscilloscope sync. or to debug timings in applications.
For this, you can try to use the `CIU_AnalogTest` with its AUX1 and AUX2 output.

## `CIU_AnalogTest` register (address 6328h)

> See PN532/C1 § 8.6.23.53

![](/assets/img/pn532_aux_analog_test.png)

It includes 2 symbols to control the pins AUX1 and AUX2:
- `AnalogSelAux1[3:0]` for the AUX1 output
- `AnalogSelAux2[3:0]` for the AUX2 output

## Register configuration

![](/assets/img/pn532_aux_bits.png)

By pushing `0b11001101` in the `PN53X_REG_CIU_AnalogTest` register, we have:
- `0b1100` in `AnalogSelAux1[3:0]`, TxActive on AUX1
- `0b1101` in `AnalogSelAux2[3:0]`, RxActive on AUX2

Code with `kpn532` library:

```cpp
pNFC->WriteRegister(PN53X_REG_CIU_AnalogTest, 0b11001101);
```

## Capture

![](/assets/img/pn532_aux_capture_full.png)

In this example we:
- Send `InCommunicateThru` command with `0x06 0x00` data (`ST25TB - Initiate`)

  ![](/assets/img/pn532_aux_capture_send.png)

- Wait interrupt, then Read ACK

  ![](/assets/img/pn532_aux_capture_ack.png)

- _NFC exchange is done now_

  ![](/assets/img/pn532_aux_capture_nfc.png)

    - AUX1 is high when transmitting
    - AUX2 is high when receiving
  
  This is confirmed with an oscilloscope capture

  ![](/assets/img/pn532_aux_capture_osc.png)

- Wait interrupt, then Read `InCommunicateThru` response with `0x00 0x89` data (status code: `0x00`, `ST25TB - chipid: 0x89`)

  ![](/assets/img/pn532_aux_capture_recv.png)

### Timings

The NFC exchange is ~1.4 ms (`P0`), but the whole communication part is ~3.3 ms (`P1`).

![](pn532_aux_capture_timings.png)

## References

### NXP PN532
- <https://www.nxp.com/products/rfid-nfc/nfc-hf/nfc-readers/nfc-integrated-solution:PN5321A3HN>
- <https://www.nxp.com/docs/en/nxp/data-sheets/PN532_C1.pdf>
- <https://www.nxp.com/docs/en/user-guide/141520.pdf>

### Library & Analyzer
- <https://github.com/BdF-LabSec/kpn532>
- <https://github.com/gentilkiwi/Saleae-Logic2-HLA-NXP-PN532>