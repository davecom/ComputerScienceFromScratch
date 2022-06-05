# chip8-test-rom
Chip8 / SChip Test ROM

![Screenshot of all tests passed](https://repository-images.githubusercontent.com/273511354/3ee2ae80-b25c-11ea-93ca-ec86d3fa694a)

Originally written and [published](https://www.cyberforum.ru/post919567.html) by Sergey Naydenov ([Tronix](mailto:tronix286@rambler.ru))

Small program for testing (S)CHIP-8 emulators. If all test passed, "OK" is displayed in the upper left corner, 
otherwise the program prints ERROR followed by the error code.

## Error codes:

- **ERROR INI** - Emulator initialization failed. When program starts, all registers (V0-VF) must be set to 0.
- **ERROR BCD** - BCD instruction problems.
- **ERROR 0** - Problems with Fx65 instruction. Can't load zeroes from memory to registers.
- **ERROR 1** - System font 8x5 not found. In memory at offset 000h - zeroes.
- **ERROR 2** - Addition without overflow (254+1). VF register need to be set to 0, but after operation it is still 1
- **ERROR 3** - After operation 254+1, register v0 needs to be set to 255, but it doesn't.
- **ERROR 4** - Addition with overflow (255+1). VF register must be set to 1, but after operation it is still 0
- **ERROR 5** - Wrong result after addition operation (255+1). Must be 0.
- **ERROR 6** - After subtraction 1-1 register VF must be 1, but it is still 0.
- **ERROR 7** - Wrong result after 1-1 operation. Result must be 0.
- **ERROR 8** - Subtract 0-1. VF register must be 0, but it is still 1
- **ERROR 9** - Wrong result after 0-1 operation. Register v0 must be 255.
- **ERROR 10** - TBD
- **ERROR 11** - TBD
- **ERROR 12** - TBD
- **ERROR 13** - TBD
- **ERROR 14** - TBD
- **ERROR 15** - TBD
- **ERROR 16** - TBD
- **ERROR 17** - TBD
- **ERROR 18** - TBD
- **ERROR 19** - TBD
- **ERROR 20** - TBD
- **ERROR 21** - TBD
- **ERROR 22** - TBD
- **ERROR 23** - Can not restore HP48 flags (FX75/FX85 instructions).
- **ERROR 24** - Check FX1E (I = I + VX) buffer overflow. If buffer overflows, register VF must be set to 1, 
                 otherwise 0. As a result, register VF not set to 1.
                 This undocumented feature of the Chip-8 and used by Spacefight 2019! game.

## Note

SCTEST.SRC is the original assembly of SCTEST.CH8 written in CHIPPER (see [this](http://www.pong-story.com/chip8/chp8_220.zip) zip file) dialect.

There is an ongoing effort to port the original into [Octo](https://johnearnest.github.io/Octo/) syntax for easy assembly.
