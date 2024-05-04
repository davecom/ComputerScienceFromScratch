# FunComputerScienceProjectsInPython
Source for the book Fun Computer Science Projects in Python by [David Kopec](https://davekopec.com).

## Get the Book

## Authorship and License

The code in this repository is Copyright 2024 David Kopec and released under the terms of the Apache License 2.0. That means you can reuse the code, but you must give credit to David Kopec. Please read the license for details. 

## Running and Testing Each Project

The following directions assume you are in the root directory of the repository in a terminal and that your Python command is `python` (on some systems it is `python3`). The code is written against Python 3.12, although most of it will run with Python 3.9+.

### Brainfuck (Chapter 1)

A simple [Brainfuck](https://en.wikipedia.org/wiki/Brainfuck) interpreter.

#### Requirements

No External Dependencies

#### Running

`python -m Brainfuck <your_file_name>`

For example:

`python -m Brainfuck Brainfuck/Examples/beer.bf`

#### Testing

`python -m tests.test_brainfuck`

### NanoBASIC (Chapter 2)

An interpreter for a very simple dialect of BASIC based on [Tiny BASIC](https://en.wikipedia.org/wiki/Tiny_BASIC).

#### Requirements

No external dependencies

#### Running

`python -m NanoBASIC <your_file_name>`

For example:

`python -m NanoBASIC NanoBASIC/Examples/fib.bas`

#### Testing

`python -m tests.test_nanobasic`

### RetroDither (Chapter 3)

Dithers images into 1 bit black & white and exports them to MacPaint format.

#### Requirements

- Pillow

#### Running

`python -m RetroDither <input_file_name> <output_file_name>`

For example:

`python -m RetroDither swing.jpeg swing.mac`

Additional options:

`-g` output a .gif format version as well

### StainedGlass (Chapter 4)

Computationally draws abstract approximations of images using vector shapes.

#### Requirements

- Pillow

#### Running

`python -m StainedGlass <input_file_name> <output_file_name>`

For example:

`python -m StainedGlass swing.jpeg swing.png`

Additional options:

`-h, --help`            shows help

`-t TRIALS, --trials TRIALS`
                        The number of trials to run (default 10000).

`-m {random,average,common}, --method {random,average,common}`
                        The method for determining shape colors (default average).

`-s {ellipse,triangle,quadrilateral,line}, --shape {ellipse,triangle,quadrilateral,line}`
                        The shape type to use (default ellipse). 

`-l LENGTH, --length LENGTH`
                        The length (height) of the final image in pixels (default 256). 

`-v, --vector`          Create vector output. A SVG file will also be output.

`-a ANIMATE, --animate ANIMATE` If a number greater than 0 is provided, will create an animated GIF with the number of milliseconds per frame
                        provided.

### Chip8 (Chapter 5)

A Chip8 virtual machine.

#### Requirements

- PyGame
- NumPy

#### Running

`python -m Chip8 <your_file_name>`

For example:

`python -m Chip8 Chip8/Games/tetris.chip`

#### Testing

`python -m tests.test_chip8`

### NESEmulator (Chapter 6)

A simple [NES](https://en.wikipedia.org/wiki/Nintendo_Entertainment_System) emulator that can play some basic public domain games.

#### Requirements

- PyGame
- NumPy

#### Running

`python -m NESEmulator <your_file_name>`

For example:

`python -m NESEmulator NESEmulator/Games/LanMaster.nes`

"a" is Select, "s" is Start, "arrow keys" are the D-pad, "z" is B, and "x" is A.

#### Testing

`python -m tests.test_nesemulator`

### KNN (Chapter 7)

A handwritten digit recognizer using the K-nearest neighbors algorithm.

#### Requirements

- PyGame
- NumPy

#### Running

`python -m KNN`

Then use the key commands "c" to classify, "p" to predict, and "e" to erase.

#### Testing

`python -m tests.test_knn`

## Type Hints
The code in this repository uses the latest type hinting features in Python 3.12. If you are using an older version of Python, you may need to remove some of the type hints to run the code. All the type hints in the source code were checked using [Pyright](https://github.com/microsoft/pyright).