#!/usr/bin/env python3
"""
Line Counter - A tool for counting and analyzing lines of code in chart files.

This script processes a stats.txt file containing information about chart files,
counts the non-comment, non-empty lines of code in specified ranges, and outputs
tabular results. It can also perform calculations on columns in the output tables.
"""
import os
import re
import argparse
from tabulate import tabulate

# Default debug settings - will be overridden by command line arguments
DEBUG_FILE = None
DEBUG_ENABLED = False

# Define comment patterns for different file types
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

def count_lines_in_range(file_path, line_range):
    """Count actual lines in the file within the specified range"""
    ranges = parse_range(line_range, file_path)
    
    is_debug = file_path == DEBUG_FILE and DEBUG_ENABLED
    
    if is_debug:
        print(f"\n=== DEBUG: Processing range {line_range} in {file_path} ===")
        print(f"Parsed line ranges: {ranges}")
    
    total_lines = 0
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.readlines()
            
        if is_debug:
            print(f"Total file lines: {len(content)}")
        
        for line_num in ranges:
            if 1 <= line_num <= len(content):
                # Check if the line is not a comment and not empty
                line = content[line_num - 1]
                line_stripped = line.strip()
                
                # Skip empty lines
                if not line_stripped:
                    if is_debug:
                        print(f"Line {line_num} is empty, skipping")
                    continue
                
                comment_pattern = get_comment_pattern(file_path)
                
                if comment_pattern:
                    # Fix for f-string escape sequence error
                    match = re.match(comment_pattern, line_stripped)
                    
                    if match:
                        if is_debug:
                            print(f"Line {line_num} is a comment, skipping: {line_stripped}")
                    else:
                        if is_debug:
                            print(f"Line {line_num} counted: {line_stripped}")
                        total_lines += 1
                else:
                    if is_debug:
                        print(f"Line {line_num} counted (no comment pattern): {line_stripped}")
                    total_lines += 1
                
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
    
    if is_debug:
        print(f"Total counted lines in range: {total_lines}")
    
    return total_lines


def process_stats_file(stats_file):
    """Process the stats.txt file and count lines in each referenced file"""
    with open(stats_file, 'r') as f:
        lines = f.readlines()
    
    current_chart_type = None
    current_file = None
    results = {}
    
    for line in lines:
        if not line.strip():
            continue
            
        # Check indentation level to determine what we're looking at
        indent_level = len(line) - len(line.lstrip())
        line = line.strip()
        
        # Chart type (no indent, ends with colon)
        if indent_level == 0:
            current_chart_type = line[:-1]
            results[current_chart_type] = {}
            if DEBUG_ENABLED:
                print(f"Processing chart type: {current_chart_type}")
            
        # File name (1 indent, ends with colon)
        elif indent_level == 4:
            current_file = line.strip()[:-1]
            if DEBUG_ENABLED:
                print(f"Processing file: {current_file}")
            if current_chart_type:  # Ensure current_chart_type is not None
                results[current_chart_type][current_file] = {}
            
        # Line numbers section (2 indents, contains colon)
        elif indent_level == 8 and ':' in line and current_chart_type and current_file:
            section, range_str = [part.strip() for part in line.strip().split(':', 1)]
            if DEBUG_ENABLED:
                print(f"Found section: {section} with range: {range_str}")
            
            # Build file path
            file_path = os.path.join(current_chart_type, current_file)
            if DEBUG_ENABLED:
                print(f"Full file path: {file_path}")
            
            if DEBUG_ENABLED:
                print(f"Processing section: {section}, range: {range_str}")
            
            # Count actual lines
            if range_str.lower() == 'all':
                # Count all non-comment lines in the file
                if DEBUG_ENABLED:
                    print(f"Counting all lines in {file_path}")
                actual_count = count_lines_in_range(file_path, range_str)
                if DEBUG_ENABLED:
                    print(f"Total non-comment lines in {file_path}: {actual_count}")
                if DEBUG_ENABLED:
                    print(f"Section {section} total count: {actual_count}")
            else:
                # Count lines in the specified range
                if DEBUG_ENABLED:
                    print(f"Counting lines in range {range_str} for {file_path}")
                actual_count = count_lines_in_range(file_path, range_str)
                if DEBUG_ENABLED:
                    print(f"Total non-comment lines in range {range_str}: {actual_count}")
                if DEBUG_ENABLED:
                    print(f"Section {section} count in range {range_str}: {actual_count}")
                
            results[current_chart_type][current_file][section] = {
                'range': range_str,
                'count': actual_count
            }
    
    return results


def parse_column_expression(expr):
    """Parse a column expression like '1+3' or '1-3' or '1+2+3'"""
    if not expr:
        return None
    
    # Tokenize the expression into numbers and operators
    tokens = []
    current_num = ""
    
    for char in expr:
        if char.isdigit():
            current_num += char
        elif char in "+-" and current_num:
            tokens.append(int(current_num))
            tokens.append(char)
            current_num = ""
    
    # Add the last number if there is one
    if current_num:
        tokens.append(int(current_num))
    
    # If no valid tokens were found, return None
    if not tokens:
        return None
    
    # Create the operations list starting with the first column
    operations = [('column', tokens[0])]
    
    # Process the rest of the tokens in pairs (operator, column)
    for i in range(1, len(tokens), 2):
        if i + 1 < len(tokens):
            op = tokens[i]
            col = tokens[i + 1]
            
            if op == '+':
                operations.append(('add', col))
            elif op == '-':
                operations.append(('subtract', col))
    
    return operations


def format_tabular_results(results, column_processes=None):
    """Format results as a table using tabulate library"""
    tables = []
    
    # Parse the column expressions if provided
    processed_operations = []
    if column_processes:
        for title, expr in column_processes:
            ops = parse_column_expression(expr)
            if ops:
                processed_operations.append((title, expr, ops))
    
    for chart_type, files in results.items():
        # Get all unique section names across all files in this chart type
        all_sections = set()
        for file_data in files.values():
            all_sections.update(file_data.keys())
        
        # Create headers with 'File' first, then all sections
        headers = ['File'] + sorted(list(all_sections))
        
        # Add columns for the calculated results if column_processes is provided
        calc_column_indices = []
        if processed_operations:
            for title, expr, _ in processed_operations:
                headers.append(title if title else f"Calc({expr})")
                calc_column_indices.append(len(headers) - 1)
        
        table_data = []
        
        for file_name, sections in files.items():
            row = [file_name]
            
            # Add counts for each section in order
            for section in headers[1:len(headers)-len(processed_operations)] if processed_operations else headers[1:]:
                if section in sections:
                    row.append(sections[section]['count'])
                else:
                    row.append('-')
            
            # Calculate the result of column operations if requested
            if processed_operations:
                for _, expr, operations in processed_operations:
                    # Apply operations
                    result = None
                    for op in operations:
                        if op[0] == 'column':
                            # Column indices are 1-based in the expression, but 0-based in our row list
                            # Also need to account for the 'File' column (at position 0)
                            col_idx = op[1]
                            if 1 <= col_idx < len(row):
                                if row[col_idx] != '-':
                                    result = row[col_idx]
                        elif result is not None:
                            col_idx = op[1]
                            if 1 <= col_idx < len(row) and row[col_idx] != '-':
                                if op[0] == 'add':
                                    result += row[col_idx]
                                elif op[0] == 'subtract':
                                    result -= row[col_idx]
                    
                    row.append(result if result is not None else '-')
            
            table_data.append(row)
        
        # Add a title and the table for this chart type
        tables.append(f"\n{chart_type}:")
        tables.append(tabulate(table_data, headers=headers, tablefmt="grid"))
    
    return "\n".join(tables)


def main():
    # Set up command line argument parsing
    parser = argparse.ArgumentParser(
        description="""
        Line Counter - Analyze and count lines of code in chart files.
        
        This tool reads a stats.txt file containing chart file information,
        counts non-comment, non-empty lines in specified ranges, and presents
        the results in tabular format. It can also perform calculations on 
        the resulting data columns.
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('--stats_file', type=str, default='stats.txt',
                        help='Path to the stats file (default: stats.txt)')
    
    parser.add_argument('--col_process', nargs=2, action='append', metavar=('TITLE', 'EXPR'), 
                        help="""Add a calculated column with custom TITLE using the expression EXPR.
                        EXPR format examples: "1+2", "1-3", "1+2-3+4"
                        Column indices start at 1, where 1 is the first data column after the file name.
                        Can be used multiple times to add multiple calculated columns.
                        Example: --col_process "Code" "1+2" --col_process "Total" "1+2+3" """)
    
    parser.add_argument('--debug', action='store_true',
                        help='Enable debug mode for verbose output')
    
    parser.add_argument('--debug_file', type=str,
                        help='Specify a file to debug (only applies when --debug is enabled)')
    
    args = parser.parse_args()

    # Update debug settings based on command line arguments
    global DEBUG_ENABLED, DEBUG_FILE
    DEBUG_ENABLED = args.debug
    if DEBUG_ENABLED and args.debug_file:
        DEBUG_FILE = args.debug_file
        print(f"Debug mode enabled for file: {DEBUG_FILE}")
    elif DEBUG_ENABLED:
        print("Debug mode enabled for all files")

    stats_file = os.path.join(args.stats_file)
    if not os.path.exists(stats_file):
        print(f"Stats file not found: {stats_file}")
        return
    
    results = process_stats_file(stats_file)
    
    # Output tabular results
    tabular_output = format_tabular_results(results, args.col_process)
    print("\nTabular Format:")
    print(tabular_output)

if __name__ == "__main__":
    main() 