#A quick overview of the project structure and build system

```
.
├── doc
│   └── dev
├── obj
└── src
    ├── boot
    │   └── i386
    │       └── pc
    ├── kernel
    │   ├── i386 -> x86_64
    │   └── x86_64
    │       ├── efi
    │       └── pc
    ├── lib
    ├── modules
    └── utils
```


#Directory Description

##doc
Our documentation directory. Documenation for developers/hackers on the project will live in doc/dev


##obj
This direcory will serve as our build directory.

##src

###boot
the boot directory contains the first code to be executed on a given $ARCH-PLAT. There are some caveats however, for example, on EFI systems an EFI binary is generated and there is no nessecity for any specific boot code. This directory will mainly serve for i386 and x86 BIOS boot code

###kernel
This is where the core code for our bootloaders kernel will live. Any architecture specific code will live in $ARCH/$PLAT

###lib
Common library code which is used in the kernel will live here.

###modules
The kernel will contain a dynamic linker to support flexibility, and also because writing a dynamic loader is a fun exercise!

##utils
A set of utilities to install our bootloader

#Boot execution sequence
boot/$ARCH/PLAT/Stage1.s (BIOS ONLY)
boot/$ARCH/PLAT/Stage1_5.s (BIOS ONLY)
kernel/$ARCH/$PLAT/startup.s
kernel/main.c




