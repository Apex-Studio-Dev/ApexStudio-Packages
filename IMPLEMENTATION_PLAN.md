# Implementation Plan: Workflow Improvements

Based on analysis of upstream termux-packages workflows.

## Status: IMPLEMENTED ✓

### 1. Linting ✓
- Validasi syntax build.sh sebelum build
- Cek error sebelum Docker start
- Implementasi di `build-packages.yml` (build job + retry-failed job)

### 2. Zram ✓
- Kompresi memori di RAM
- Cegah OOM saat build package besar
- Implementasi di `build-packages.yml` (build job + retry-failed job)

### 3. Disk Space Management ✓
- Bebaskan disk space sebelum build
- Hapus file tidak perlu (~20GB)
- Implementasi di `build-packages.yml` (build job + retry-failed job)

### 4. Dry-Run Check ✓
- Cek apakah package valid untuk architecture
- Info package mana yang akan di-build/di-skip
- Implementasi di `build-packages.yml` (build job)

### 5. Scheduled Updates (TODO)
- Otomatis cek update packages secara berkala
- Trigger: weekly atau setiap 6 jam
- Implementasi: Modifikasi `update-packages.yml`

## Perbandingan dengan Upstream

| Aspek | Upstream | Kita | Status |
|-------|----------|------|--------|
| Build | Docker via run-docker.sh | Langsung di container | ✓ Cukup |
| Lint | Ya | Ya | ✓ Implementasi |
| Zram | 16GB | Ya | ✓ Implementasi |
| Disk | Free space script | Ya | ✓ Implementasi |
| Dry-run | Via run-docker.sh | Simple check | ✓ Implementasi |
| APT Host | Aptly API | GitHub Pages | ✓ Cukup |
| Large Files | Tidak handle | GitHub Releases | ✓ Cukup |
| Notifications | Tidak ada | Telegram | ✓ Cukup |
| Auto Update | Every 6 jam | Manual only | TODO |
| Retry | Tidak ada | Retry with -I | ✓ Cukup |

## Yang Sudah Diimplementasi

1. **Free disk space** - Hapus /usr/share/dotnet, android SDK, ghc
2. **Enable zram** - Setup compressed memory
3. **Lint packages** - Validasi syntax build.sh
4. **Dry-run check** - Cek architecture exclusion

## Yang Masih TODO

1. **Scheduled updates** - Modifikasi update-packages.yml dengan cron trigger

## References

- `termux-packages/.github/workflows/packages.yml`
- `termux-packages/.github/workflows/package_updates.yml`
- `termux-packages/.github/workflows/bootstrap_archives.yml`
- `termux-packages/scripts/run-docker.sh`
- `termux-packages/scripts/bin/build-package-dry-run-simulation.sh`
- `termux-packages/scripts/lint-packages.sh`
