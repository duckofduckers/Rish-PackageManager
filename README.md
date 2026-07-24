# Shizuku Rish Setup (Termux)

## Overview

This repository provides a **safe and consistent installer** for setting up **rish with Shizuku** inside **Termux**.

The installer handles:
- Correct file placement
- Permission setup
- Basic validation to prevent silent failures

Using the installer is the **recommended and supported** installation method.

---

## Package Manager

To install the files run:

```sh
bash <(curl -fsS https://raw.githubusercontent.com/duckofduckers/Shizuku-Rish-Setup/main/PackageManager.sh) -install
```

To uninstall the file run:

```sh
bash <(curl -fsS https://raw.githubusercontent.com/duckofduckers/Shizuku-Rish-Setup/main/PackageManager.sh) -uninstall
```

---

## Releases

The Releases page is provided for reference and transparency:

https://github.com/duckofduckers/Shizuku-Rish-Setup/releases/tag/Release

> ⚠️ Manual installation from release assets is not recommended and is not officially supported.

---

## Notes

Only installs performed using the official installer are supported

Modified scripts or manual installs may result in undefined behavior

If something breaks, re-running the installer is recommended.
