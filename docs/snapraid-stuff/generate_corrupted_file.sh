#!/usr/bin/env bash

# Quick and Dumb Bash Script to Delibrately Generate a Corrupted
# file that will be flagged by scrub operation, useful for testing.
#
# I advise against doing this unless you know what you are doing!
#
# Run it from somewhere in the array is the easiest
#
# Note the snapraid commands are commented out below - Uncomment to run
#

# File Name
file_name="test_file.txt"
file_timestamps="test_file.txt.timestamps"

# Create a new text file
echo "line1" > "${file_name}"

# Now sync the array
#snapraid sync

# Capture the Timestamps in a file
touch -r "${file_name}" "${file_timestamps}"

# Now Modify the File by Changing the number above to zero,
# and then restoring the old timestamps. This changes the file,
# but fools SnapRAID into thinking the file has not changed, so
# the scrub should flag it as an error.
echo "line0" > "${file_name}"
touch -r "${file_timestamps}" "${file_name}"

# Remove the Timestamps
rm "${file_timestamps}"

# Now Run a Diff operation, it should show no changes.
#snapraid diff

echo ""
echo "If the diff operation above shows no changes, you are the"
echo "proud owner of a corrupted file"
echo ""
echo "A Scrub operation should now find it."
echo ""

