<p align="center">
  <img src="https://img.shields.io/badge/version-1.2-indigo?style=for-the-badge" alt="Version">
  <img src="https://img.shields.io/badge/arch-aarch64%20%7C%20arm-success?style=for-the-badge" alt="Architecture">
  <img src="https://img.shields.io/github/license/Apex-Studio-Dev/ApexStudio-Packages?style=for-the-badge&color=purple" alt="License">
  <img src="https://img.shields.io/github/actions/workflow/status/Apex-Studio-Dev/ApexStudio-Packages/build-packages.yml?style=for-the-badge&label=build" alt="Build Status">
</p>

<h1 align="center">Apex Studio Packages</h1>

<p align="center">
  APT package repository for <strong>Apex Studio</strong> on Termux.<br>
  Pre-built packages for Android development — Java, Gradle, Android SDK, NDK, and more.
</p>

---

## Features

- **74+ packages** ready to install via APT
- **Dual architecture** — AArch64 (64-bit) and ARM (32-bit) support
- **Bootstrap archives** — minimal (~50MB) for fast initial setup
- **Custom MOTD** — Apex Studio-branded terminal welcome message
- **GPG signed** — secure package verification
- **Auto-updated** — CI/CD pipeline builds packages from upstream sources
- **Web dashboard** — browse packages at [apex-studio-dev.github.io/ApexStudio-Packages](https://apex-studio-dev.github.io/ApexStudio-Packages)

## Quick Setup

```bash
# Install prerequisites
pkg install apt-transport-https

# Add Apex Studio repository
echo "deb https://apex-studio-dev.github.io/ApexStudio-Packages stable main" \
  > $PREFIX/etc/apt/sources.list.d/apexstudio.list

# Update and install
pkg update && pkg upgrade
```

## Packages

### Core System
| Package | Description |
|---------|-------------|
| `apt` | Package manager |
| `bash` | Bourne Again Shell |
| `coreutils` | Core GNU utilities |
| `dash` | POSIX-compliant shell |
| `diffutils` | File comparison tools |
| `findutils` | File search utilities |
| `gawk` | GNU Awk |
| `grep` | Pattern matching |
| `gzip` | Compression |
| `less` | Pager |
| `sed` | Stream editor |
| `tar` | Archiver |

### Termux Essentials
| Package | Description |
|---------|-------------|
| `termux-core` | Core Termux utilities |
| `termux-exec` | Execution environment |
| `termux-keyring` | GPG key management |
| `termux-tools` | System tools |
| `util-linux` | System utilities |

### Development Tools
| Package | Description |
|---------|-------------|
| `openjdk-17` | OpenJDK 17 |
| `openjdk-21` | OpenJDK 21 |
| `gradle` | Build automation |
| `cmake` | Cross-platform build system |
| `make` | Build automation |
| `aapt2` | Android Asset Packaging Tool |
| `binutils` | Binary utilities |
| `glibc` | GNU C Library |

### Libraries
| Package | Description |
|---------|-------------|
| `libcurl` | URL transfer library |
| `libbz2` | Bzip2 compression |
| `liblzma` | XZ compression |
| `ncurses` | Terminal handling |
| `libandroid-support` | Android compatibility |
| `libandroid-glob` | Glob pattern matching |
| `libllvm` | LLVM compiler infrastructure |
| `libprotobuf` | Protocol Buffers |
| `libsqlite` | SQLite database |
| `zlib` | Compression library |

### Audio (for OpenJDK)
| Package | Description |
|---------|-------------|
| `libogg` | Ogg container format |
| `libflac` | FLAC audio codec |
| `libmp3lame` | MP3 encoder |
| `libmpg123` | MPEG audio decoder |
| `libopus` | Opus audio codec |
| `libvorbis` | Vorbis audio codec |
| `libsndfile` | Sound file I/O |

### CLI & Utilities
| Package | Description |
|---------|-------------|
| `git` | Version control |
| `nano` | Text editor |
| `vim` | Vi IMproved |
| `wget` | Network downloader |
| `aria2` | Download accelerator |
| `python` | Python interpreter |
| `python-pip` | Python package manager |
| `jq` | JSON processor |
| `which` | Command locator |
| `patch` | Apply diffs |
| `unzip` | ZIP extractor |
| `zip` | ZIP archiver |

## Architecture Support

| Architecture | Status | Packages |
|-------------|--------|----------|
| **AArch64** (64-bit) | Stable | Full support |
| **ARM** (32-bit) | Stable | Full support |
| **All** (arch-independent) | Stable | Scripts, configs, data |

## Building from Source

### Prerequisites
- Termux on Android (API 28+)
- ~2GB free storage
- Internet connection

### Build Packages
```bash
# Clone repository
git clone --recurse-submodules https://github.com/Apex-Studio-Dev/ApexStudio-Packages.git
cd ApexStudio-Packages

# Build all packages (AArch64)
./build.sh -a aarch64 --keep-going

# Build specific package
./build.sh -a aarch64 -e openjdk-21

# Build for ARM
./build.sh -a arm --keep-going
```

### Generate Bootstrap
```bash
# Generate bootstrap archive
./generate-bootstrap-archive.sh -r "https://apex-studio-dev.github.io/ApexStudio-Packages" aarch64
```

### Generate APT Repository
```bash
# Generate local APT repo
./generate-apt-repo.sh
```

## GitHub Actions

| Workflow | Description | Trigger |
|----------|-------------|---------|
| `build-packages.yml` | Build all packages | Manual dispatch |
| `generate-bootstraps.yml` | Generate bootstrap archives | Manual dispatch |
| `update-packages.yml` | Check for upstream updates | Cron / Manual |

### Build Options
- **Architecture**: `aarch64`, `arm`, or `both`
- **Packages**: `all` or space-separated list
- **Keep-going**: Continue build on failure

## Repository Structure

```
ApexStudio-Packages/
├── build.sh                    # Main build script
├── packages.sh                 # Package definitions
├── common.sh                   # Shared configuration
├── utils.sh                    # Utility functions
├── generate-bootstrap-archive.sh
├── generate-apt-repo.sh
├── generate-packages-json.sh
├── pages-index.html            # Web dashboard
├── apexstudio.gpg              # GPG signing key
├── patches/                    # Build patches
│   ├── termux-keyring.patch.in
│   ├── termux-tools-motd.patch
│   ├── openjdk-21-cleanup.patch
│   └── ...
├── termux-packages/            # Upstream termux-packages (submodule)
└── .github/workflows/
    ├── build-packages.yml
    ├── generate-bootstraps.yml
    └── update-packages.yml
```

## Packages JSON

The `packages.json` file provides a machine-readable list of all packages:

```json
[
  {
    "name": "openjdk-21",
    "version": "21.0.4",
    "desc": "OpenJDK 21 Java development kit",
    "arch": "aarch64"
  }
]
```

### Architecture Values
- `aarch64` — 64-bit ARM only
- `arm` — 32-bit ARM only
- `both` — Available for both architectures
- `all` — Architecture-independent (scripts, configs)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'feat: add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open a Pull Request

### Commit Convention
We use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` — New feature
- `fix:` — Bug fix
- `docs:` — Documentation
- `chore:` — Maintenance
- `refactor:` — Code refactoring

## Security

If you discover a security vulnerability, please report it via [GitHub Issues](https://github.com/Apex-Studio-Dev/ApexStudio-Packages/issues).

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2026 Apex Studio Dev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<p align="center">
  Built with ❤️ by <a href="https://github.com/Apex-Studio-Dev/ApexStudio-Packages">Apex Studio Dev</a>
</p>
