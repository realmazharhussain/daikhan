# Steps to build Daikhan on Windows

## Prepare

1. Install **NSIS**
2. Install **MSYS2**
3. Update MSYS packages
   1. Open "MSYS2 UCRT64" from MSYS2 folder in the start menu
   2. Run the command `pacman -Syu`
   3. Repeat above 2 steps till everything is up-to-date
4. In MSYS, make sure you have **python-pyalpm** installed
   1. Open "MSYS2 UCRT64" from MSYS2 folder in the start menu
   2. Run the command `pacman -S --needed python-pyalpm`

## Build

From inside the MSYS environment with this directory as the current working directory,
run the following commands

```bash
makepkg-mingw -fsi       # Builds & Installs Daikhan inside MSYS
./msys-deploy.py         # Copies all Daikhan files into "AppDir" folder
makensis daikhan.nsi     # Creates a setup.exe out of "AppDir" folder
```
