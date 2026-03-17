---
title: Logitech dongle C-U0007
categories:
  - electronic
  - mcu
  - Nordic
tags:
  - Logitech
  - C-U0007
  - C-U0003
  - C-U0013
  - Nordic
  - nrf24lu1+
---

## Hardware

`Nordic NRF24LU1+` based dongle

## Firmwares

### Downloads

- [`RQR12.05_B0028.bin`](/assets/downloads/logitech/RQR12.05_B0028.bin)
- [`RQR12.07_B0029.bin`](/assets/downloads/logitech/RQR12.07_B0029.bin)
- [`RQR12.08_B0030.bin`](/assets/downloads/logitech/RQR12.08_B0030.bin)
- [`RQR12.09_B0030.bin`](/assets/downloads/logitech/RQR12.09_B0030.bin)
- [`RQR12.10_B0032.bin`](/assets/downloads/logitech/RQR12.10_B0032.bin)
  - [`RQR12.10_B0032_patched.bin`](/assets/downloads/logitech/RQR12.10_B0032_patched.bin)
  - [`RQR12.10_B0032_read_mem.asm`](/assets/downloads/logitech/RQR12.10_B0032_read_mem.asm)
- [`RQR12.11_B0032.bin`](/assets/downloads/logitech/RQR12.11_B0032.bin)
- [`RQR21.00_B0007.bin`](/assets/downloads/logitech/RQR21.00_B0007.bin) - not related but compatible ;)

#### Bootloaders

- [`RQR12_bootloader_02B0014_0x7400.bin`](/assets/downloads/logitech/RQR12_bootloader_02B0014_0x7400.bin)
- [`RQR12_bootloader_02B0015_0x7400.bin`](/assets/downloads/logitech/RQR12_bootloader_02B0015_0x7400.bin) - current bootloader with CRC validation
- [`RQR12_bootloader_04B0016_0x6c00.bin`](/assets/downloads/logitech/RQR12_bootloader_04B0016_0x6c00.bin) - current bootloader with RSA signature validation

### Remarks

- `RQR12.09` & `RQR12.11` are compatible with bootloaders >= `04B0016` (signature needed)
- `RQR12.05`, `RQR12.07`, `RQR12.08` & `RQR12.10` (/patched) are compatible with bootloaders <= `02B0015` ;
- `RQR12.09` & `RQR12.11` are the same as `RQR12.08` & `RQR12.10`, but the first ones were made to be compatible with `04B0016` bootloader size ;
- bootloader `04B0016` (and > ?) need a valid signature to be pushed in RAM before writing the last (first) byte ;
- provided bootloaders are now generic (reference firmware version removed from them) ;
- usually you cannot upload a new bootloader on an official Logitech dongle without SPI access + full erase (see `Infopage - Configuration`): there are here to experiment.
- "source" code of the patch intrgrated in `RQR12.10_B0032_patched.bin` is available in `RQR12.10_B0032_read_mem.asm`

### Digests

```
SHA2-256(RQR12.05_B0028.bin)                 = 8fd0cbd7932541805a943a5b72536564dac5ecfa58302d7b760617bbad5e9f6a
SHA2-256(RQR12.07_B0029.bin)                 = 16f699ed0373acedefd9ee9cd0b0f26afa94a78028cbb90d3cc5ff6f5a9a228e
SHA2-256(RQR12.08_B0030.bin)                 = 8ffee0cafc7a6ebf5d058d0d8a11498621c7cdef7a0c5ebf148bc190646407ea
SHA2-256(RQR12.09_B0030.bin)                 = 43b44ec1f6959cf5974329000847dcd5cc510c11ad62af4f2d048f0f74f7559f
SHA2-256(RQR12.10_B0032.bin)                 = aeda60a060898692cf41a11577461f80a78ed993545ad4ef744e2f7a6cd9d5ae
SHA2-256(RQR12.10_B0032_patched.bin)         = 400564d1e02c9c89fa827dfc3a002fd7eafffd8908a8e14b3626304e63e08ae2
SHA2-256(RQR12.11_B0032.bin)                 = e7db69331e8a09165b377889de561f12f309976d36c86caf11ad68cbc9f87f8f
SHA2-256(RQR12_bootloader_02B0014_0x7400.bin)= c08de6a8e0364b2234e73400f3ce58d6132ea11eee972b13310333670707b635
SHA2-256(RQR12_bootloader_02B0015_0x7400.bin)= c7bc2c7e293034547e11dda1e8e6a05572b07455304194ad1cd7076bc8c82489
SHA2-256(RQR12_bootloader_04B0016_0x6c00.bin)= 06d0ad91d48f3e1e6f06ab832f2f12098e9c27f5e565b86370550bf5c5f0faf3
SHA2-256(RQR21.00_B0007.bin)                 = 54cb6e853f27464c2c52b3a65c82d4f094a046c8dcb09b559b24ba1f22450cb0
```

### Useful commands

To transform a valid Intel HEX file into padded (`0xff`) binary:
```
> srec_cat -o myfirmware.bin -binary myfirmware.hex -intel -fill 0xff 0x0 -maximum-address "(" myfirmware.hex -intel ")"
```

### Check signature

```
> openssl pkeyutl -verify -inkey logitech_c-u0007_pubkey.der -pubin -rawin -sigfile RQR12.11_B0032_sign.rev.bin -in RQR12.11_B0032.bin
Signature Verified Successfully
```

or if firmware hash is wanted:

```
> openssl pkeyutl -verifyrecover -inkey logitech_c-u0007_pubkey.der -pubin -in RQR12.11_B0032_sign.rev.bin | openssl asn1parse -inform DER -i
    0:d=0  hl=2 l=  49 cons: SEQUENCE
    2:d=1  hl=2 l=  13 cons:  SEQUENCE
    4:d=2  hl=2 l=   9 prim:   OBJECT            :sha256
   15:d=2  hl=2 l=   0 prim:   NULL
   17:d=1  hl=2 l=  32 prim:  OCTET STRING      [HEX DUMP]:E7DB69331E8A09165B377889DE561F12F309976D36C86CAF11AD68CBC9F87F8F

> openssl dgst -sha256 RQR12.11_B0032.bin
SHA2-256(RQR12.11_B0032.bin)= e7db69331e8a09165b377889de561f12f309976d36c86caf11ad68cbc9f87f8f
```

### Notes

```
BOT01.02_B0015 / BOT01.02_B0014 (!)
  Firmware memory        : 0x0000 (0x6800)
  Firmware device data   : 0x6c00 ( 0x400)
  Firmware sensitive data: 0x7000 ( 0x400)
  Bootloader memory      : 0x7400
  Update protection      : CRC16-CCIT (on Firmware memory)
    poly = 0x1021
    init = 0xffff
    CRC16 address : 0x67fe-0x67ff
  InfoPage               : 5a5affffffffffffffffffCHIPIDCHIP
                           ffffffffffffffffffffffffffffffff
                           3a00ff00ff...
    Configuration - 3a00ff00ff:
      Areas:
        Unprotected: 0x0000 (0x7400) - NUPP=0x3a
        Protected  : 0x7400 ( 0x800) - NUPP=0x3a & DAEN=1
        Data       : 0x7c00 ( 0x400) - DAEN=1
      SPI read:
        mainblock  : no - RDISMB=1
        infopage   : yes - RDISIP=0
      Boot         : 0x7400 (protected) STP=1 (odd 1's at the last memory line (f1 ff ...)
      Debug        : no - DBG=0
```
```
BOT01.04_B0016
  Firmware memory        : 0x0000 (0x6400)
  Firmware device data   : 0x6400 ( 0x400)
  Firmware sensitive data: 0x6800 ( 0x400)
  Bootloader memory      : 0x6c00
  Update protection      : PKCS#1 v1.5 - RSA 2048/SHA256 (on Firmware memory)
    N(le) = 0xde8ec27ec39e5f183515261c462beddf9111d7e5455cb984c04c9ee876d61f49
              6eeaea0f2dd1a45591b8d68174f4c5c1cc5e83a0934c870cc7cad0cd2ecce73d
              57235b7563fdf5b9295a46d41d94f9205c63ad33a6bc5842e6709ea78e00c198
              9e219bf03df76941f9a63d66959812e9ceca3400535e4dc1441d182e4fbb2662
              1ec44aa3be55295337c34ec0395fcdb2692716fc60225e77f5559dba66f750e0
              c90ffec5ad8f096d3a9553cebdd8f0b9be86f8479c0475133e38eb6a0df162c8
              2e89ed83d43ae02a88c05ddbbb63f2d738777466d81d226a36158d4eb72a1591
              d921c91084b6484e512130b02c36bae22f8b3a92d3c722e81dbb404ead56ff69
    e = 0x17 (23)
  InfoPage               : 5a5affffffffffffffffffCHIPIDCHIP
                           ffffffffffffffffffffffffffffffff
                           3600ff00ff...
    Configuration - 3600ff00ff:
      Areas:
        Unprotected: 0x0000 (0x6c00) - NUPP=0x36
        Protected  : 0x6c00 (0x1000) - NUPP=0x36 & DAEN=1
        Data       : 0x7c00 ( 0x400) - DAEN=1
      SPI read:
        mainblock  : no - RDISMB=1
        infopage   : yes - RDISIP=0
      Boot         : 0x6c00 (protected) STP=1 (odd 1's at the last memory line (f1 ff ...)
      Debug        : no - DBG=0
```

#### Downloads

- [`logitech_c-u0007_pubkey.der`](/assets/downloads/logitech/logitech_c-u0007_pubkey.der)
  - [`logitech_c-u0007_pubkey.asn1`](/assets/downloads/logitech/logitech_c-u0007_pubkey.asn1)
- [`RQR12.09_B0030_sign.rev.bin`](/assets/downloads/logitech/RQR12.09_B0030_sign.rev.bin)
- [`RQR12.11_B0032_sign.rev.bin`](/assets/downloads/logitech/RQR12.11_B0032_sign.rev.bin)


## Channels

Frequency is: 2400 MHz + channel

### Firmware  channel table
_in firmware: channel 5 is at index 1, index 0 is adjusted to index 1_
```
 5,  8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 56, 59, 62, 65, 68, 71, 74
```

### Devices under test
```
 5,  8,     14, 17,                 32, 35,     41, 44,                     62, 65,     71, 74
```

### Pairwise hop table
_experimentally verified, minor interference_
```
 5   <==>   14                  29   <==>   38                          59   <==>   68
     8   <==>   17                  32   <==>   41      47   <==>   56      62   <==>   71
        11   <==>   20                  35   <==>   44                          65   <==>   74

                                                41   <===   50
                                                    44   <===   53
```

With devices I used, it limits minor interference hops to:
```
 5   <==>   14                      32   <==>   41                          62   <==>   71
     8   <==>   17                      35   <==>   44                          65   <==>   74
```

### Scan sequence
```
 5 -> 32 -> 62 ->  8 -> 35 -> 65 -> 14 -> 41 -> 71 -> 17 -> 44 -> 74 (->  5 -> ...)
```

## References

- <https://github.com/Logitech/fw_updates/tree/master/RQR12>
- <https://github.com/decrazyo/unifying>
- <https://travisgoodspeed.blogspot.com/2011/02/promiscuity-is-nrf24l01s-duty.html>
- <https://github.com/RoganDawes/LOGITacker>
- <https://github.com/whad-team>
- <https://github.com/BastilleResearch/nrf-research-firmware>