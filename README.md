# Shizuku Rish Setup (Termux)

## Overview

This repository provides a **safe and consistent PackageManager** for setting up **rish** for **Shizuku** inside **Termux**.

The installer handles:
- Correct file placement
- Permission setup
- Basic validation to prevent silent failures

Using the installer is the **recommended and supported** installation method for **Termux**.

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

## Notes

Only installs performed using the official installer are supported

Modified scripts or manual installs may result in undefined behavior
