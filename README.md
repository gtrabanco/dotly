<p align="center">
  <a href="https://github.com/gtrabanco/sloth">
    <img src="sloth.svg" alt="Sloth Logo" width="256px" height="256px" />
  </a>
</p>

<h1 align="center">
  .Sloth
</h1>

<p align="center">
  Dotfiles for laziness
</p>

<p align="right">
  Original idea is <a href="https://github.com/codelytv/dotly" alt="Dotly repository">Dotly Framework</a> by <a href="https://github.com/rgomezcasas" alt="Dotly orginal developer">Rafa Gomez</a>
</p>

- [About this](#about-this)
- [Features & differences with Dotly Framework](#features--differences-with-dotly-framework)
- [INSTALLATION](#installation)
  - [Linux, macOS, FreeBSD](#linux-macos-freebsd)
- [Restoring dotfiles](#restoring-dotfiles)
  - [Linux, macOS, FreeBSD](#linux-macos-freebsd-1)
- [Migration from Dotly](#migration-from-dotly)
- [Roadmap](#roadmap)

## About this
[.Sloth](https://github.com/gtrabanco/sloth) is a [Dotly fork](https://github.com/CodelyTV/dotly) which widely changes from original project.

Dotly is a [@rgomezcasas](https://github.com/rgomezcasas) idea (supported by [CodelyTV](https://pro.codely.tv)) with the help of a lot of people (see [Dotly Contributors](https://github.com/CodelyTV/dotly/graphs/contributors)).

## Features & differences with Dotly Framework

* Abstraction from Framework loader you only need to add in your `.bashrc` or `.zshrc` (it will be done automatically but make a backup first).
 ```bash
 DOTFILES_PATH="${HOME}/.dotfiles"
 SLOTH_PATH="${DOTFILES_PATH}/modules/sloth"
. "${SLOTH_PATH:-${DOTLY_PATH:-}}/shell/init-sloth.sh"
 ```
* Init scripts [see (init-scripts](https://github.com/gtrabanco/dotfiles/tree/master/shell/init.scripts) in [gtrabanco/dotfiles](https://github.com/gtrabanco/dotfiles)). This provides many possibilities as modular loading of custom variables or aliases by machine, loading secrets... Whatever you can imagine.
* Per machine (or whatever name you want to) export packages `sloth packages dump` (you can use `dot` instead of `sloth`, we also have aliases for this command like `lazy` and `s`).
* Non opinionated `git` scripts.
* Compatibility with all Dotly features and scripts.
* When you install SLOTH a backup of all files that well be linked is done (`.bashrc`, `.zshrc`, `.zshenv`... All files in symlinks/conf.yaml and equivalent files that are applied with `sloth core install`). So you won't loose any old data if you migrate to SLOTH.
* Easy way to create new scripts from Terminal `sloth script create --help`
* Easy way to install scripts from Terminal `sloth script install_remote --help`
```
* Scripts marketplace (Coming soon...)
* Auto update (Coming soon...)
* We promise to reply all issues and support messages and review PRs.

## INSTALLATION

### Linux, macOS, FreeBSD

Using wget
```bash
bash <(wget -qO- https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/installer)
```

Using curl
```bash
bash <(curl -s https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/installer)
```

## Restoring dotfiles

In your repository you see a way to restore your dotfiles, anyway you can restory by using the restoration script.

### Linux, macOS, FreeBSD

Using wget
```bash
bash <(wget -qO- https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/restorer)
```

Using curl
```bash
bash <(curl -s https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/restorer)
```
### Windows

```PowerShell
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/install.ps1"))
```

<!--
Source PowerShell:
 . ([Scriptblock]::Create((([System.Text.Encoding]::ASCII).getString((Invoke-WebRequest -Uri "${FUNCTIONS_URI}").Content))))
-->

<hr>

## Migration from Dotly

If you have currently dotly in your .dotfiles you can migrate.

Using wget
```bash
bash <(wget -qO- https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/dotly-migrator)
```

Using curl
```bash
bash <(curl -s https://raw.githubusercontent.com/gtrabanco/sloth/HEAD/dotly-migrator)
```

## Roadmap

View [Wiki](https://github.com/gtrabanco/sloth/wiki#roadmap) if you want to contribute and you do not know what to do or maybe is already a WIP (Work in Progress).
