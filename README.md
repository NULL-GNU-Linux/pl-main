# `main`
The official package repository for [`pkglet`](https://github.com/NULL-GNU-Linux/pkglet), the NULL GNU/Linux package manager.

## How does the repo work?
A `pkglet` repo is basically a git repo. with [`repo.lua`](repo.lua) and directories representing the package names 
(replace `.` with `/`).

## I dont have this repo somehow, how do i add it?
To add any repo to `pkglet` just run:
```bash 
pl u path/to/downloaded/repo.lua    # if you have downloaded the file
pl u https://example.com/repo.lua   # using a URL
```
