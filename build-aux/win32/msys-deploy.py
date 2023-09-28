#!/usr/bin/python3

import os
import shutil
import pathlib
import tomllib
import fnmatch
import subprocess

import pyalpm as alpm

_db = alpm.Handle('/', '/var/lib/pacman').get_localdb()
_MINGW_PACKAGE_PREFIX = os.environ.get('MINGW_PACKAGE_PREFIX')
PKGNAME_PREFIX = _MINGW_PACKAGE_PREFIX + '-' if _MINGW_PACKAGE_PREFIX else ''
PREFIX = pathlib.Path(os.environ.get('MSYSTEM_PREFIX', '/'))

def list_pkg(pkgname):
    return [pathlib.Path('/', file)
            for file, _a, _b in _db.get_pkg(PKGNAME_PREFIX + pkgname).files
            if not file.endswith('/')]

def expand_glob(glob, scope=None):
    if scope:
        return (pathlib.Path(x)
                for x in scope
                if fnmatch.fnmatch(x, PREFIX / glob))
    else:
        return PREFIX.glob(glob)

def expand_glob_list(glob_list, scope=None):
    result = []
    for glob in glob_list:
        if '*' in glob:
            result += expand_glob(glob, scope)
        else:
            result.append(PREFIX / glob)
    return result

def add_deps(files):
    for file in files.copy():
        if file.suffix in ('.dll', '.exe'):
            stdout = subprocess.run(['ldd', file], capture_output=True).stdout.decode()
            for line in stdout.strip().split('\n'):
                dll = line.strip().split()[2]
                if dll.startswith('/c/Windows/'):
                    continue
                if dll.endswith(':'):
                    dll = dll[:-1]

                files.add(pathlib.Path(dll))

def copy(paths):
    i, l, s = 0, len(paths), len(str(len(paths)))
    for path in sorted(paths):
        i += 1
        print(f"{i:{s}}/{l} {path}")
        src = pathlib.Path(path)
        dst = pathlib.Path('AppDir') / src.relative_to(PREFIX)
        dst.parent.mkdir(parents=True, exist_ok=True)
        if src.is_dir():
            shutil.copytree(src, dst, symlinks=True)
        else:
            shutil.copyfile(src, dst, follow_symlinks=False)


def main(filename):
    print("Reading manifest ...")

    with open(filename, 'rb') as f:
        manifest = tomllib.load(f)

    files = set()

    print("Determining files of intererest ...")

    for section in manifest:
        scope = None if section == 'global' else list_pkg(section)
        if file_list := manifest[section].get('install'):
            files.update(expand_glob_list(file_list, scope))
        else:
            file_list = manifest[section]['skip']
            files.update(filename for filename in scope
                         if filename not in expand_glob_list(file_list, scope))

    print("Discovering dependencies of exe/dll files ...")
    add_deps(files)
    print("Copying files ...")
    copy(files)

    if post_deploy := manifest.get("global", {}).get("post_deploy"):
        print("Running post_deploy")
        subprocess.run([pathlib.Path(post_deploy).absolute()], cwd="AppDir")


if __name__ == '__main__':
    try:
        shutil.rmtree('AppDir')
    except FileNotFoundError:
        pass

    main('msys-deploy.toml')
