# Zim to Tiddly and Tiddly to Markdown
Simple Bash script convert Zim-Wiki files into TiddlyWiki format inspired by https://github.com/0xMH/Zim-Tiddlywiki-converter. Simple markups will convert into TiddlyWiki style. The LaTeX math formula will be inserted back into the file in correponding places. Screenshots will be renamed according the to time stamp, and all be placed into Figures folder, and the image link will be placed in note file. 

Another script converting Tiddly format to markdown is also provided.

## Usage

1. Download the `.sh` script

2. Suppose the Zim notebook is located at `notebook_dir` ( which will have the `noteboke.zim` file, the script will recursively go over every `.txt` file)
```bash
./Zim2Tiddly.sh notebook_dir output_dir
```

Similar for `Tiddly2MD.sh`

## Format that can be handled

- Headings
- Lists
- Emphasis
- Horizontal Rules
- Verbatim
- Code block
- Links
- Equation
- Screenshot (tiff)

## Format that not be handled

- Mixed list
- Format not lised above

## Disclaimer

This is just a very simple script (even with many bugs) that can handle some simpel format transformation from Zim to Tiddly. Please backup your own data before converting (but it should not touch the original files)
