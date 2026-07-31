# Rish Package Manager (Termux)

## Overview

This repository provides a **safe and consistent, open-source PackageManager** for setting up **rish** for **Shizuku** inside **Termux**.

Using my PackageManager is the **recommended and fully supported** installation/uninstallation method for **Termux** via 3rd party.

---

## Package Manager

Run this command for info (requires Bash).
For other shells, use the appropriate command below.

```sh
# Bash (recommended)
bash <(curl -fsSL https://tinyurl.com/rish-pm)

# Zsh
zsh <(curl -fsSL https://tinyurl.com/rish-pm)

# Fish (process substitution not supported, use pipe)
curl -fsSL https://tinyurl.com/rish-pm | bash

# Ksh
ksh <(curl -fsSL https://tinyurl.com/rish-pm)

# Any POSIX shell (explicitly invoke Bash)
bash -c "$(curl -fsSL https://tinyurl.com/rish-pm)"

---

## Shizuku Repository

This is required.

🔗 https://github.com/RikkaApps/Shizuku

---

## Notes

Only installs performed using the official installer are supported.

Modified scripts or manual installs may result in undefined behavior.

If installation/uninstallation fails re-running the PackageManager is recommended.
