# Chart Annotation Line Counter

This project provides tools to analyze and compare line counts across different chart implementation files. It analyzes the distribution of code, data, and annotation lines in various chart implementations (D3, Vega, Vega-Lite, HighCharts, ggplot2), helping to understand the annotation overhead for different libraries.

## Overview

The line counter analyzes files specified in a `stats.txt` configuration file, counting non-comment, non-empty lines within specified ranges. It categorizes lines as:

- **Code**: Implementation logic
- **Data**: Data definitions and specifications
- **Annotation**: Explanatory content and visualization annotations

## Configuration Format

The `stats.txt` file follows this format:

```
chart-type:
    filename.ext:
        Code: 10-50,70-90
        Data: 51-69
        Annotation: 91-120
```

Where:
- `chart-type` is a directory containing chart files (e.g., bar-chart, line-chart)
- `filename.ext` is the chart implementation file
- Section headings (`Code`, `Data`, `Annotation`) define line categories
- Line ranges can be comma-separated (e.g., `10-50,70-90`) or `all` for the entire file

## Python Line Counter
```text
usage: line_counter.py [-h] [--stats_file STATS_FILE] [--col_process TITLE EXPR] [--debug] [--debug_file DEBUG_FILE]

        Line Counter - Analyze and count lines of code in chart files.
        
        This tool reads a stats.txt file containing chart file information,
        counts non-comment, non-empty lines in specified ranges, and presents
        the results in tabular format. It can also perform calculations on 
        the resulting data columns.
        

options:
  -h, --help            show this help message and exit
  --stats_file STATS_FILE
                        Path to the stats file (default: stats.txt)
  --col_process TITLE EXPR
                        Add a calculated column with custom TITLE using the expression EXPR. EXPR format examples: "1+2", "1-3",
                        "1+2-3+4" Column indices start at 1, where 1 is the first data column after the file name. Can be used
                        multiple times to add multiple calculated columns. Example: --col_process "Code" "1+2" --col_process "Total"
                        "1+2+3"
  --debug               Enable debug mode for verbose output
  --debug_file DEBUG_FILE
                        Specify a file to debug (only applies when --debug is enabled)
```

## Folder Comparison Tool

The project also includes a specialized folder comparison tool that focuses on meaningful code changes between different implementations.

```text
usage: compare_folders.py [-h] [--section SECTION] [--debug] [folder1] [folder2]

Compare files between two chart implementation folders, focusing on meaningful changes.

positional arguments:
  folder1            First folder to compare (default: simple-barchart)
  folder2            Second folder to compare (default: simple-scatterplot)

options:
  -h, --help         show this help message and exit
  --section SECTION  Section to compare (e.g., "Annotation", "Data", "Code+Data+Annotation")
  --debug            Enable detailed debug output
```

### Folder Comparison Features

- Compares corresponding files between two folders
- Ignores comments and empty lines for meaningful comparison
- Can focus on specific sections defined in stats.txt (e.g., just Annotation lines)
- Shows the number of meaningful added and removed lines
- Handles various file formats with appropriate comment detection

### Comparison Tool Usage Examples

Basic comparison between two folders:
```bash
python compare_folders.py folder1 folder2
```

Compare only the annotation sections:
```bash
python compare_folders.py folder1 folder2 --section Annotation
```

Use default folders with section filtering:
```bash
python compare_folders.py --section Data
```

Enable debug output for detailed information:
```bash
python compare_folders.py folder1 folder2 --debug
```

### Comparison Output Format

The tool produces output in the following format:
```
filename.ext: +XX | -YY || MMM
        │      │     │     │
        │      │     │     └─ Total meaningful lines in original file (excludes comments & empty lines)
        │      │     └─ Removed meaningful lines
        │      └─ Added meaningful lines
        └─ Filename being compared
```

When a section is specified:
```
filename.ext: +XX | -YY || SSS / MMM
        │      │     │     │     │
        │      │     │     │     └─ Total meaningful lines in original file
        │      │     │     └─ Meaningful lines in the specified section
        │      │     └─ Removed meaningful lines
        │      └─ Added meaningful lines
        └─ Filename being compared
```

Where:
- `filename.ext` is the name of the file being compared
- `+XX` is the number of meaningful added lines
- `-YY` is the number of meaningful removed lines
- `SSS` is the number of meaningful lines in the specified section (only shown when a section is specified)
- `MMM` is the total number of meaningful lines in the original file (ignoring comments and empty lines)

## Usage Examples

### Basic Usage
```bash
python line_counter.py
```

### Custom Stats File
```bash
python line_counter.py --stats_file my_stats.txt
```

### Adding Calculated Columns
```bash
# Add a column showing Code as a percentage of total
python line_counter.py --col_process "Code%" "3/2*100"

# Add multiple calculation columns
python line_counter.py --col_process "Pure Code" "3-1" --col_process "Total" "1+2+3"

# Calculate annotation overhead
python line_counter.py --col_process "Annotation %" "1/(1+3)*100"
```

### Debugging
```bash
# Enable debug output for all files
python line_counter.py --debug

# Debug a specific file
python line_counter.py --debug --debug_file "bar-chart/ggplot2-annotate.R"
```

## Output Format

The output is displayed in tabular format, grouped by chart type:

```
bar-chart:
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| File               |   Annotation |   Code+Data+Annotation |   Data |   Code |   Code+Data |   Code+Annotation |
+====================+==============+========================+========+========+=============+===================+
| highchart.html     |           50 |                     93 |     11 |     32 |          43 |                82 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| d3.html            |           70 |                    162 |     11 |     81 |          92 |               151 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| vega.json          |          354 |                    584 |     69 |    161 |         230 |               515 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| vega-lite.json     |          236 |                    308 |     49 |     23 |          72 |               259 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| vl-annotation.json |           82 |                    150 |     49 |     19 |          68 |               101 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| d3-annotate.html   |           80 |                    172 |     11 |     81 |          92 |               161 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| ggplot2.R          |           98 |                    125 |      5 |     22 |          27 |               120 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| ggplot2-annotate.R |           53 |                     78 |      5 |     20 |          25 |                73 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+

line-chart:
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| File               |   Annotation |   Code+Data+Annotation |   Data |   Code |   Code+Data |   Code+Annotation |
+====================+==============+========================+========+========+=============+===================+
| highchart.html     |          149 |                    232 |      1 |     82 |          83 |               231 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| d3.html            |           99 |                    176 |      1 |     76 |          77 |               175 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| vega.json          |          272 |                    532 |     41 |    219 |         260 |               491 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| vega-lite.json     |          224 |                    254 |      1 |     29 |          30 |               253 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| vl-annotation.json |           70 |                     96 |      1 |     25 |          26 |                95 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| d3-annotate.html   |           97 |                    175 |      1 |     77 |          78 |               174 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| ggplot2.R          |           83 |                    127 |      1 |     43 |          44 |               126 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| ggplot2-annotate.R |           75 |                    118 |      1 |     42 |          43 |               117 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+

scatter-chart:
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| File               |   Annotation |   Code+Data+Annotation |   Data |   Code |   Code+Data |   Code+Annotation |
+====================+==============+========================+========+========+=============+===================+
| highchart.html     |           90 |                    170 |      1 |     79 |          80 |               169 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| d3.html            |           66 |                    171 |      1 |    104 |         105 |               170 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| vega.json          |          201 |                    410 |     23 |    186 |         209 |               387 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| vega-lite.json     |          143 |                    178 |      1 |     34 |          35 |               177 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| vl-annotation.json |           48 |                     80 |      1 |     31 |          32 |                79 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| d3-annotate.html   |           78 |                    178 |      1 |     99 |         100 |               177 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| ggplot2.R          |          107 |                    209 |      1 |    101 |         102 |               208 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
| ggplot2-annotate.R |           77 |                    179 |      1 |    101 |         102 |               178 |
+--------------------+--------------+------------------------+--------+--------+-------------+-------------------+
```

## Example Folder Comparison Output

When comparing folders with the `compare_folders.py` tool, the output will look like:

```
Comparing only the 'Annotation' section in each file:

File                | Changes | Section | Total
                      Added | Removed  Lines   Lines
-------------------+-------+---------+-------+------
d3-annotate.html  : +  8 | -  9 || 80 / 172
d3.html           : + 11 | - 12 || 70 / 162
ggplot2-annotate.R: +  9 | -  9 || 53 / 78
ggplot2.R         : + 20 | - 20 || 98 / 125
highchart.html    : +  9 | - 10 || 50 / 93
vega-lite.json    : + 11 | - 12 || 236 / 308
vega.json         : + 11 | - 11 || 354 / 584
vl-annotation.json: +  0 | -  0 || 82 / 150
```

And without section specified:

```
File                | Changes | Total
                      Added | Removed  Lines
-------------------+-------+---------+------
d3-annotate.html  : +  8 | -  9 || 172
d3.html           : + 11 | - 12 || 162
ggplot2-annotate.R: +  9 | -  9 || 78
ggplot2.R         : + 20 | - 20 || 125
```

## Comment Detection

The tool automatically detects and excludes comments based on file extensions:
- `.html`: HTML comments (`<!-- -->`) and JavaScript comments (`//`)
- `.json`: JavaScript-style comments (`//`) - although technically not standard JSON
- `.R`, `.r`: R comments (`#`)
- `.py`: Python comments (`#`, `"""`, `'''`)

## Analyzing Results

The tabular output helps compare:
- Annotation overhead across different chart libraries
- Code-to-annotation ratios
- Implementation efficiency
- Custom calculations using the `--col_process` feature

The folder comparison tool helps analyze:
- Meaningful differences between similar implementations
- Section-specific changes (like annotation modifications)
- Real code changes excluding comments and whitespace

## Implementation Details

- Written in Python 3
- Uses the `tabulate` library for formatting tabular output
- Handles multi-line and single-line comments
- Supports custom column calculations with simple expressions
- Excludes empty lines from counts
- Supports section-specific analysis

## Dependencies

- Python 3.6+
- tabulate library (`pip install tabulate`)

## License

This project is released under the MIT License.

