# elf2flt binutils prebuilts

This repo holds prebuilt binutils for use with the elf2flt project.  Only the
files needed for elf2flt are saved here.  These should not be used for anything
else.

These are built for Linux/x86_64 with recent glibc versions.  YMMV if you try
to use these yourself.  You've been warned!

## Usage

When building elf2flt, simply point the configure script to this repo:

`./configure --with-binutils-build-dir=.../prebuilts-binutils-libs/output/2.26.1/ ...`

## Building

The prebuilts in here were created with the build.sh script.  For more details,
see that file.
