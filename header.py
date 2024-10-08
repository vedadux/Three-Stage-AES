# 
# Copyright (C) 2024 Vedad Hadžić
# 
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# 

import argparse
from datetime import datetime
import os

license_header_text = """
Copyright (C) {{YEAR}} {{AUTHOR}}


This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""

license_marker_text = "https://www.gnu.org/licenses/"
assert(license_header_text.find(license_marker_text) != -1)

def parse_arguments():
    parser = argparse.ArgumentParser(description="Header application program")

    # Add the --style argument
    parser.add_argument('--style',  type=str, default="//", help='Line comment style')
    parser.add_argument('--year',   type=str, default=str(datetime.now().year), help='Copyright year')
    parser.add_argument('--author', type=str, required=True, help='Copyright holder')
    parser.add_argument('file',     type=str, help="The file with code")

    # Parse the arguments
    args = parser.parse_args()
    if (not os.path.exists(args.file)):
        print(f"File \"{args.file}\" does not exist.")
        exit(1)
    return args

if __name__ == "__main__":
    args = parse_arguments()
    try:
        f = open(args.file, "r")
        code = f.read()
    except Exception as e:
        print(e)
        exit(2)
    finally:
        f.close()
    
    if code.find(license_marker_text) != -1:
        print(f"{args.file}: License already applied, skipping!")
        exit(0)
    
    license_text = license_header_text.replace("{{YEAR}}", args.year).replace("{{AUTHOR}}", args.author)
    license_text = "\n".join((args.style + " " + l) for l in license_text.split("\n")) + "\n\n"
    
    try:
        f = open(args.file, "w")
        f.write(license_text + code)
        print(f"{args.file}: Done!")
    except Exception as e:
        print(e)
        exit(2)
    finally:
        f.close()
    
    