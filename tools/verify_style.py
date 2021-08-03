import os
import sys
import re

FORBIDDEN_CHARS = {
    '\u2014': "em dash (U+2014)",
    '\u2013': "en dash (U+2013)",
}

# Distinct forbidden words: recruiter, recruiters, faang, quant, quants
FORBIDDEN_WORDS = [
    r'\brecruiter\b',
    r'\brecruiters\b',
    r'\brecruiting\b',
    r'\bfaang\b',
    r'\bquant\b',
    r'\bquants\b',
]

def check_file(filepath):
    errors = []
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        for idx, line in enumerate(f, 1):
            for char, name in FORBIDDEN_CHARS.items():
                if char in line:
                    errors.append(f"{filepath}:{idx}: contains {name}: {line.strip()}")
            if not filepath.endswith("verify_style.py"):
                lower_line = line.lower()
                for pattern in FORBIDDEN_WORDS:
                    if re.search(pattern, lower_line):
                        errors.append(f"{filepath}:{idx}: contains forbidden pattern '{pattern}': {line.strip()}")
    return errors

def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    all_errors = []
    for dirpath, dirnames, filenames in os.walk(root):
        if '.git' in dirpath or '__pycache__' in dirpath or 'venv' in dirpath:
            continue
        for fname in filenames:
            if fname.endswith(('.qs', '.py', '.md', '.json', '.sh', 'Makefile', '.txt', '.yml', '.yaml')):
                fpath = os.path.join(dirpath, fname)
                all_errors.extend(check_file(fpath))
    
    if all_errors:
        print("Style verification FAILED:")
        for err in all_errors:
            print("  ", err)
        sys.exit(1)
    else:
        print("Style verification PASSED: Zero forbidden characters or words found.")

if __name__ == '__main__':
    main()
