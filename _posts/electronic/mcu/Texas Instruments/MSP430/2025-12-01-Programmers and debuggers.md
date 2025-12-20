---
categories:
  - electronic
  - mcu
  - Texas Instruments
  - MSP430
tags:
  - ti
  - texas
  - instruments
  - msp430
  - ez-fet
  - msp-fet
  - launchpad
  - uniflash
  - msp430flasher
---

## Hardware programmers/debuggers

### MSP-FET
_the traditional & efficient way (also the expensive way)_ - https://www.ti.com/tool/MSP-FET

This programmer/debugger is the most universal one for MSP430/MSP432

![](/assets/img/msp-fet-kameleon.jpg)

Its connector allows multiple ways of connection to boards, but usually only [traditional JTAG or Spy-Bi-Wire](https://www.ti.com/lit/pdf/slau320) will be needed

![](/assets/img/msp-fet-jtag-con.png)

> [!note] The big brother of `MSP-FET` is named `MSP-GANG` - <https://www.ti.com/tool/MSP-GANG>  
> _more suited to go outside of your laboratory for programming on-the-go without a computer_

More information in: <https://www.ti.com/lit/pdf/slau647> § 5.6 MSP-FET Stand-Alone Debug Probe
Library & API: <https://www.ti.com/tool/MSPDS>

### Launchpad
_the embedded way_

Launchpad development boards are very useful to begin with MSP430 micro-controllers. They embed what is necessary to debug, flash, even to make some energy traces for some versions.

See: <https://www.ti.com/design-development/embedded-development/msp430-mcus.html> ("LaunchPad development kits" part) for some boards.

To debug/program, [Spy-Bi-Wire JTAG](https://www.ti.com/lit/pdf/slau320) is generally used, it is slightly different from the original JTAG protocol - by mixing signal on the same line, even the `RESET` one.
- Unfortunately, standard tools are not suitable without modifications, especially because of initialization sequence ;
- Fortunately, Launchpad boards embed what is called : `eZ-FET 1.x`, `eZ-FET 2.x` or `eZ-FET Lite` (or `ez430` for oldest ones) emulator (<https://www.ti.com/lit/pdf/slau647>) at the top of the board.

`ez-FET` part on `MSP‑EXP430FR2433` kit:

![](/assets/img/lp_ez_part.png)

`ez-FET` diagram on `MSP‑EXP430FR5969` kit:

![](/assets/img/lp_msp430_ez-fet.png)

Embedded `ez-FET` on boards handles USB communication with computer, via virtual COM ports for UART but also for JTAG/Energytrace communication.

> [!info] This is not exclusive to Texas Instruments:
> - STMicroelectronics with their Nucleo - embed ST-Link
> - Nordic Semiconductor with their NRF5*-DK embed JLink
> - ...

#### Technically
> [!info] Your _not primary interest_ MCUs on the board dedicated to communication/trace are often more expensive than your main MCU

The `eZ-FET` part is made from another `MSP430` MCU, with native USB support - usually a `MSP430F5528` with specific firmware, energy trace part is with another `MSP430` MCU - usually `MSP430G2452`


### Launchpad for others
_share your Launchpad with friendly MSP430_

> [!tip] It seems that the less expensive way to have a cheap programmer/debugger is to reuse a recent Launchpad board, at this time a `MSP-EXP430FR2433` kit (< $10)
> ![](/assets/img/msp-exp430fr2433_price.png)
> From TI: https://www.ti.com/product/MSP-EXP430FR2433/part-details/MSP-EXP430FR2433

Thanks to jumpers, you can isolate the `eZ-FET` part from the main MCU, and attach to another one.  
You'll need to connect the `eZ-FET` pins `GND`, `3V3`, `SBWTDIO` & `SBWTCK` to your targeted MCU:

![](/assets/img/msp-exp430f5529lp_isolated.jpg)

- Example for a `MSP430FR2476` on the `eZ-FET lite` of the `MSP-EXP430F5529LP`
    
    ![](/assets/img/msp-exp430f5529lp_first_kiemul.jpg)
    
    ```
    * Dll Version : 31501001
    * FwVersion   : 31200000
    * Interface   : TIUSB
    * HwVersion   : E 3.0
    * JTAG Mode   : AUTO
    * Device      : MSP430FR2476
    ```

- Example for a `MSP430FR2673` on the `eZ-FET` of the `LP-MSP430FR2476`

    ![](/assets/img/lp-msp430fr2476_kameleon.jpg)
    
    ```
    * Dll Version : 31501001
    * FwVersion   : 31200000
    * Interface   : TIUSB
    * HwVersion   : E 6.0
    * JTAG Mode   : AUTO
    * Device      : MSP430FR2673
    ```


## Software tools

- On premise
    - Code Composer Studio: <https://www.ti.com/tool/CCSTUDIO> (Eclipse based by default, Theia proposed)
    - Uniflash: <https://www.ti.com/tool/UNIFLASH>
    - MSP430 Flasher: <https://www.ti.com/tool/MSP430-FLASHER>
        - may require newer `MSP430.dll` from <https://www.ti.com/tool/MSPDS>
- Cloud based
    - Code Composer Studio: <https://dev.ti.com/ide/> (was Eclipse based, Theia now)
    - Uniflash: <https://dev.ti.com/uniflash/>
    
> [!question] Cloud based tools need a browser extension & a local agent running in background
> _maybe one day with native browser serial communication?_

### MSP430 Flasher

Example here to program `st25tb_kameleon.hex` in a `MSP430FR2673` on the `eZ-FET` of the `LP-MSP430FR2476`:

```
> MSP430Flasher -i TIUSB -n MSP430FR2673 -z [VCC,RESET] -e ERASE_ALL -v -w st25tb_kameleon.hex

* -----/|-------------------------------------------------------------------- *
*     / |__                                                                   *
*    /_   /   MSP Flasher v1.3.20                                             *
*      | /                                                                    *
* -----|/-------------------------------------------------------------------- *
*
* Evaluating triggers...done
* Checking for available FET debuggers:
* Found USB FET @ COM38 <- Selected
* Initializing interface @ COM38...done
* Checking firmware compatibility:
* FET firmware is up to date.
* Reading FW version...done
* Setting VCC to 3000 mV...done
* Accessing device...done
* Reading device information...done
* Loading file into device...done
* Verifying memory (st25tb_kameleon.hex)...done
*
* ----------------------------------------------------------------------------
* Arguments   : -i TIUSB -n MSP430FR2673 -z [VCC,RESET] -e ERASE_ALL -v -w st25tb_kameleon.hex
* ----------------------------------------------------------------------------
* Driver      : loaded
* Dll Version : 31501001
* FwVersion   : 31200000
* Interface   : TIUSB
* HwVersion   : E 6.0
* JTAG Mode   : AUTO
* Device      : MSP430FR2673
* EEM         : Level 5, ClockCntrl 2
* Erase Mode  : ERASE_ALL
* Prog.File   : st25tb_kameleon.hex
* Verified    : TRUE
* BSL Unlock  : FALSE
* InfoA Access: FALSE
* VCC ON      : 3000 mV
* ----------------------------------------------------------------------------
* Resetting device (RST/NMI)...done
* Starting target code execution...done
* Disconnecting from device...done
*
* ----------------------------------------------------------------------------
* Driver      : closed (No error)
* ----------------------------------------------------------------------------
*/
```

#### Reported HwVersion

| HwVersion | Description   |
|-----------|---------------|
| E2.0      | eZ430         |
| E3.0      | eZ-FET lite   |
| E4.0+     | eZ-FET        |
| U1.40     | MSP-FET430UIF |
| U1.64     | MSP-FET430UIF |
| U3.0      | MSP-FET       |


## What about BootStrap Loader? (BSL)

`MSP430` support BootStrap Loader. Embedded code (in ROM for some) can include BSL with UART, i2c, SPI, but now also USB.  
See: <https://www.ti.com/tool/MSPBSL> & <https://www.ti.com/tool/MSP430USBDEVPACK>

> [!warning] BSL can be useful to flash new versions of firmware/recovery, but is **not** a debugger.

Even if the UART one can be seen as promising, it's necessary to run one initialization sequence on RST & TEST pin before... making it difficult to use without a specific USB to Serial adaptator like FT232 (with usually DTR & RTS).

Drawbacks for the UART BSL:
1. USB to Serial adaptators with DTR & RTS are not so common ;
    1. Some adaptators supporting custom GPIO can also be used, but it needs to adapt (if possible) flashing programs ;
2. It needs more pins: `3V3`, `GND`, `TX`, `RX`, `DTR (RST)` & `RTS (TEST)` - _6 vs 4 for Spy-Bi-Wire JTAG_ ;
3. Softwares to use it are not very well supported since embedded `ez-FET` ;
4. Cost: specific adaptators & script customization must be compared to < $10 Launchpad with `ez-FET` - including the debugger!

Drawbacks for the USB BSL:
1. A MSP430 with native USB support is needed ;
    1. Only 48/571 at this time
2. External crystal is needed ;
3. Generic software to use it is needed!

### BSL Ressources
- <https://www.ti.com/lit/pdf/slau655>
- <https://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPBSL_Scripter/latest/index_FDS.html>
- <https://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPBSL_CustomBSL430/latest/index_FDS.html>