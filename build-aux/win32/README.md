# Steps to build Daikhan on Windows

## Prepare

1. Install **NSIS**

   ```powershell
   winget install NSIS.NSIS
   ```
2. Install **MSYS2**

   ```powershell
   winget install MSYS2.MSYS2
   ```
3. In MSYS2 (Open "**MSYS2 UCRT64**" from "MSYS2" folder in start menu)
   1. Update all packages (Repeat the following command till everything is up-to-date)

      ```bash
      pacman -Syu
      ```
   2. Install **git** and **python-pyalpm**

      ```bash
      pacman -S --needed git python-pyalpm
      ```
   3. Clone Daikhan's git repository

      ```bash
      git clone --depth=1 https://gitlab.com/daikhan/daikhan.git ~/daikhan
      ```

## Build

1. Open MSYS2 ("MSYS2 UCRT64" from "MSYS2" folder in the start menu)
3. cd into this folder

   ```bash
   cd ~/daikhan/build-aux/win32
   ```

4. Run the following commands

   ```bash
   makepkg-mingw -fsi       # Builds & Installs Daikhan inside MSYS
   ./msys-deploy.py         # Copies all Daikhan files into "AppDir" folder
   makensis daikhan.nsi     # Creates a setup.exe out of "AppDir" folder
   ```
