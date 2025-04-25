#!/usr/bin/env python3
"""
File Comparison Tool for Chart Annotations

This script compares files between two specified folders,
counting meaningful differences while ignoring empty lines and comments.

The tool can focus on specific sections (like "Annotation" or "Data") defined in a stats.txt
file, which allows for targeted analysis of semantic components in visualization code.

Usage examples:
  - Basic comparison: ./compare_folders.py folder1 folder2
  - Section comparison: ./compare_folders.py folder1 folder2 --section Annotation
  - Debug mode: ./compare_folders.py folder1 folder2 --section Data --debug
  - Default folders: ./compare_folders.py --section Annotation

Output format:
  filename.ext: +XX | -YY / SSS / MMM
  Where:
    +XX = Added meaningful lines
    -YY = Removed meaningful lines
    SSS = Meaningful lines in section (if a section is specified)
    MMM = Total meaningful lines in original file
"""
import os
import subprocess
import tempfile
import shlex
import sys
import re
import argparse

# Parse command line arguments
parser = argparse.ArgumentParser(
    description='Compare files between two chart implementation folders, focusing on meaningful changes.',
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog="""
Examples:
  %(prog)s folder1 folder2               # Compare files between two folders
  %(prog)s folder1 folder2 --section Annotation  # Compare only annotation sections
  %(prog)s                               # Use default folders (simple-barchart and simple-scatterplot)
  %(prog)s --section Data                # Use default folders, compare only Data sections
  %(prog)s --section Code+Data+Annotation  # Compare all functional content
  %(prog)s --debug                       # Show detailed debugging information
    
The script reads section definitions from stats.txt in the current directory.
Section ranges like "13-22,39-71" define which lines to include in analysis.
Comments and empty lines are automatically filtered out based on file type.
"""
)
parser.add_argument('folder1', nargs='?', default='simple-barchart', 
                   help='First folder to compare (default: simple-barchart)')
parser.add_argument('folder2', nargs='?', default='simple-scatterplot', 
                   help='Second folder to compare (default: simple-scatterplot)')
parser.add_argument('--section', type=str, 
                   help='Section to compare (e.g., "Annotation", "Data", "Code+Data+Annotation")')
parser.add_argument('--debug', action='store_true', 
                   help='Enable detailed debug output')
args = parser.parse_args()

section_value = args.section
debug_enabled = args.debug
folder1 = args.folder1
folder2 = args.folder2

if debug_enabled:
    print(f"Debug mode enabled, section_value: {section_value}")
    print(f"Comparing folders: {folder1} and {folder2}")

# Print section header if a section is specified
if section_value:
    print(f"\nComparing only the '{section_value}' section in each file:\n")

# Define comment patterns for different file types (reused from line_counter.py)
COMMENT_PATTERNS = {
    '.html': r'<!--.*?-->|//.*?$',  # HTML comments and JS single-line comments
    '.json': r'//.*?$',             # JSON comments (technically not valid, but sometimes used)
    '.R': r'#.*?$',                # R comments
    '.r': r'#.*?$',                # R comments
    '.py': r'#.*?$|""".*?"""|\'\'\'.*?\'\'\'',  # Python comments
}

def get_comment_pattern(file_path):
    """Return the comment pattern based on file extension"""
    ext = os.path.splitext(file_path)[1].lower()
    return COMMENT_PATTERNS.get(ext, '')

def is_comment_or_empty(line, file_path):
    """Check if a line is a comment or empty"""
    line = line.strip()
    if not line:
        return True
    
    comment_pattern = get_comment_pattern(file_path)
    if comment_pattern and re.match(comment_pattern, line):
        return True
    
    return False

def parse_range(range_str, file_path):
    """Parse a range string like '67-167,214' into a list of line numbers"""
    ranges = []
    if range_str.lower() == 'all':
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.readlines()
        return list(range(1, len(content) + 1))
    for part in range_str.split(','):
        if '-' in part:
            start, end = map(int, part.split('-'))
            ranges.extend(range(start, end + 1))
        else:
            ranges.append(int(part))
    return ranges

def count_meaningful_lines(file_path, section_range=None):
    """
    Count meaningful lines (non-empty, non-comment) in a file or section
    
    Args:
        file_path: Path to the file
        section_range: Section range string (e.g. "10-20,30-40") or None for entire file
        
    Returns:
        Number of meaningful lines
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        meaningful_count = 0
        
        for i, line in enumerate(lines, 1):
            # Check if line is in section (if specified)
            if section_range and not is_line_in_section(i, section_range, file_path):
                continue
                
            # Count line if it's not a comment or empty
            if not is_comment_or_empty(line, file_path):
                meaningful_count += 1
        
        return meaningful_count
    except Exception as e:
        if debug_enabled:
            print(f"Error counting meaningful lines in {file_path}: {e}")
        return 0

# Parse stats.txt to get section information
def parse_stats_file():
    with open('stats.txt', 'r') as f:
        content = f.read()
    
    # Split the content by major chart sections
    chart_sections = re.split(r'\n\s*\n', content)
    stats_data = {}
    
    for section in chart_sections:
        if not section.strip():
            continue
        
        # Get chart name (the first line before the colon)
        lines = section.strip().split('\n')
        chart_match = re.match(r'^([^:]+):', lines[0])
        if not chart_match:
            continue
        
        chart_name = chart_match.group(1).strip()
        stats_data[chart_name] = {}
        
        # Process files within this chart section
        current_file = None
        
        for line in lines[1:]:
            # File section line starts with 4 spaces and ends with colon
            file_match = re.match(r'^\s{4}([^:]+):\s*$', line)
            if file_match:
                current_file = file_match.group(1).strip()
                stats_data[chart_name][current_file] = {}
                continue
            
            # Section data line starts with 8 spaces and has colon followed by data
            if current_file:
                section_match = re.match(r'^\s{8}([^:]+):\s*(.+)$', line)
                if section_match:
                    section_name = section_match.group(1).strip()
                    section_range = section_match.group(2).strip()
                    stats_data[chart_name][current_file][section_name] = section_range
    
    return stats_data

def is_line_in_section(line_num, section_range, file_path):
    """Check if a line number is within the specified section range"""
    if not section_range or section_range == "N/A":
        return False
    
    ranges = parse_range(section_range, file_path)
    return line_num in ranges

def compare_files(file1_path, file2_path, section_info1=None, section_info2=None):
    """Compare two files, focusing only on non-comment, non-empty lines within specified sections"""
    if debug_enabled:
        print(f"\nComparing files: {file1_path} vs {file2_path}")
        print(f"Section info 1: {section_info1}")
        print(f"Section info 2: {section_info2}")
    
    # Read both files
    try:
        with open(file1_path, 'r', encoding='utf-8') as f1:
            file1_lines = f1.readlines()
        
        with open(file2_path, 'r', encoding='utf-8') as f2:
            file2_lines = f2.readlines()
    except Exception as e:
        print(f"Error reading files: {e}")
        return 0, 0
    
    # Create unified diff
    with tempfile.NamedTemporaryFile(mode='w+') as diff_file:
        cmd = f"diff -u {shlex.quote(file1_path)} {shlex.quote(file2_path)} > {shlex.quote(diff_file.name)}"
        subprocess.run(cmd, shell=True, check=False)
        diff_file.seek(0)
        diff_lines = diff_file.readlines()
    
    if debug_enabled:
        print(f"Generated diff with {len(diff_lines)} lines")
    
    # Track current line numbers in each file as we process the diff
    file1_line_num = 0
    file2_line_num = 0
    
    # Count added and removed lines (non-empty, non-comment, in section if specified)
    added_lines = 0
    removed_lines = 0
    
    # Skip the first two lines of unified diff (headers)
    for i, line in enumerate(diff_lines):
        if i < 2:  # Skip diff headers
            continue
            
        line = line.rstrip('\n')
        
        # Check the first character to determine line type
        if line.startswith('+'):
            # Added line (in file2 but not file1)
            file2_line_num += 1
            content = line[1:]
            
            # Check if line is in the specified section (if any)
            is_in_section = not section_info2  # If no section specified, consider all lines
            if section_info2:
                is_in_section = is_line_in_section(file2_line_num, section_info2, file2_path)
            
            # Count only if not comment/empty and in section
            if is_in_section and not is_comment_or_empty(content, file2_path):
                added_lines += 1
                if debug_enabled:
                    print(f"Added line {file2_line_num} (in section: {is_in_section}): '{content.strip()}'")
        
        elif line.startswith('-'):
            # Removed line (in file1 but not file2)
            file1_line_num += 1
            content = line[1:]
            
            # Check if line is in the specified section (if any)
            is_in_section = not section_info1  # If no section specified, consider all lines
            if section_info1:
                is_in_section = is_line_in_section(file1_line_num, section_info1, file1_path)
            
            # Count only if not comment/empty and in section
            if is_in_section and not is_comment_or_empty(content, file1_path):
                removed_lines += 1
                if debug_enabled:
                    print(f"Removed line {file1_line_num} (in section: {is_in_section}): '{content.strip()}'")
        
        elif line.startswith(' '):
            # Unchanged line (in both files)
            file1_line_num += 1
            file2_line_num += 1
        
        elif line.startswith('@@ '):
            # Line location marker - update line counters
            matches = re.search(r'@@ -(\d+),\d+ \+(\d+),\d+ @@', line)
            if matches:
                file1_line_num = int(matches.group(1)) - 1
                file2_line_num = int(matches.group(2)) - 1
                if debug_enabled:
                    print(f"Location marker: file1 line {file1_line_num+1}, file2 line {file2_line_num+1}")
    
    if debug_enabled:
        print(f"Total added lines: {added_lines}, total removed lines: {removed_lines}")
    
    return added_lines, removed_lines

# Verify folders exist
for folder in [folder1, folder2]:
    if not os.path.isdir(folder):
        print(f"Error: Folder '{folder}' does not exist")
        sys.exit(1)

# Get stats data
stats_data = parse_stats_file()

# Verify that our folders of interest exist in the stats data
has_folder1 = folder1 in stats_data
has_folder2 = folder2 in stats_data
if section_value:  # Only warn about missing stats if we're using a section
    if not has_folder1:
        print(f"Warning: '{folder1}' not found in stats.txt")
    if not has_folder2:
        print(f"Warning: '{folder2}' not found in stats.txt")

# Get list of files in both directories (excluding directories)
files1 = [f for f in os.listdir(folder1) if os.path.isfile(os.path.join(folder1, f))]
files2 = [f for f in os.listdir(folder2) if os.path.isfile(os.path.join(folder2, f))]

# Find common files
common_files = sorted(set(files1).intersection(set(files2)))

if not common_files:
    print(f"No common files found between '{folder1}' and '{folder2}'")
    sys.exit(1)

# Track the maximum filename length for formatting
max_filename_length = max([len(f) for f in common_files]) if common_files else 0

# Print header with explanation based on whether a section is provided
if section_value:
    print(f"{'File':{max_filename_length}} | Changes | Section | Total")
    print(f"{'':{max_filename_length}}   Added | Removed  Lines   Lines")
    print(f"{'-'*max_filename_length}-+-------+---------+-------+------")
else:
    print(f"{'File':{max_filename_length}} | Changes | Total")
    print(f"{'':{max_filename_length}}   Added | Removed  Lines")
    print(f"{'-'*max_filename_length}-+-------+---------+------")

# Process each common file
for filename in common_files:
    file1_path = os.path.join(folder1, filename)
    file2_path = os.path.join(folder2, filename)
    
    try:
        # If section is specified, get section ranges
        section_info1 = None
        section_info2 = None
        
        if section_value:
            if has_folder1 and filename in stats_data[folder1]:
                section_info1 = stats_data[folder1][filename].get(section_value, None)
            
            if has_folder2 and filename in stats_data[folder2]:
                section_info2 = stats_data[folder2][filename].get(section_value, None)
        
        # Count meaningful lines in file1
        meaningful_total = count_meaningful_lines(file1_path)
        
        # Count meaningful lines in section (if specified)
        section_lines = 0
        if section_value and section_info1:
            section_lines = count_meaningful_lines(file1_path, section_info1)
        
        # Compare files, filtering by section if specified
        added_lines, removed_lines = compare_files(
            file1_path, file2_path, section_info1, section_info2
        )
        
        # Format and print the result
        if section_value:
            print(f"{filename:{max_filename_length}}: +{added_lines:3d} | -{removed_lines:3d} || {section_lines:3d} / {meaningful_total:3d}")
        else:
            print(f"{filename:{max_filename_length}}: +{added_lines:3d} | -{removed_lines:3d} || {meaningful_total:3d}")
    
    except Exception as e:
        print(f"Error processing {filename}: {e}") 