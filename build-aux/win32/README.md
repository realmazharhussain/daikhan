# Steps to build Daikhan on Windows

1. Install MSYS2 (preferebly with UCRT64 environment)
2. In MSYS, make sure you have python-pyalpm installed
3. Install NSIS
4. From inside the MSYS environment with this directory as the current working directory,
   run the following commands

   ```bash
   makepkg-mingw -fsi       # Builds & Installs Daikhan inside MSYS
   ./msys-deploy.py         # Copies all Daikhan files into "AppDir" folder
   makensisw daikhan.nsi    # Creates a setup.exe out of "AppDir" folder
   ```
