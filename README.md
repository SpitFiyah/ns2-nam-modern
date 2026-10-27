# ns2-nam-modern

> **Fixed & Working Network Simulator (NS-2) and Network Animator (NAM) for Modern Linux (Ubuntu 20.04, 22.04, 24.04, 26.04+).**

![NAM Screenshot](https://github.com/SpitFiyah/ns2-nam-modern/blob/main/screenshot.png?raw=true)

---

## 🎯 The Problem

If you've tried running **NS-2** and **NAM** for networking labs on modern Ubuntu, you've likely hit one of these fatal blockers:
1. `nam` exits immediately with `nam: ` (exit code 1) and no GUI opens.
2. `nam: Duplicate element Combobox.downarrow` crash.
3. Segmentation fault (`SIGSEGV`) when rendering the canvas or colors on 64-bit systems.
4. `nam` was removed or broken in modern official package repositories due to legacy Tcl/Tk dependencies.

This repository provides **pre-patched, tested packages**, a **1-command installer**, and **automatic update protection** so future system updates will never break your lab setup.

---

## 🚀 Quick Install (1 Command)

Clone this repository and run the installer:

```bash
git clone https://github.com/SpitFiyah/ns2-nam-modern.git
cd ns2-nam-modern
sudo ./install.sh
```

### What `install.sh` Does:
* Installs `ns2` and all required shared libraries (`tcl8.6`, `tk8.6`, `libotcl1`, `libtclcl1`).
* Installs the patched `nam` package (`.deb`) and standalone binary to `/usr/local/bin/nam`.
* **Locks the packages (`apt-mark hold nam ns2`)** so running `sudo apt upgrade` will never replace or break them.
* Sets up APT pinning priority in `/etc/apt/preferences.d/pin-nam.pref`.

---

## 🧪 Testing Your Installation

Run the included demonstration script to verify both simulation and graphical animation:

```bash
cd examples
ns lab_demo.tcl
```

This simulates a 4-node topology with TCP (FTP) and UDP (CBR) traffic and automatically launches the NAM animator.

You can also open any existing trace file:
```bash
nam out.nam
```

---

## 🛠️ What Was Fixed (Technical Summary)

* **TclCL `source` Parameter Collision:** TclCL overrides `proc source {fileName}` to accept only 1 argument. Tk 8.6 invokes `source -encoding utf-8 ...` on startup, crashing unpatched NAM before windows can open. We restore native Tcl `source` immediately after initialization.
* **TTK Duplicate Elements:** In Tk 8.6, themes are loaded during `Tk_Init()`. NAM previously re-evaluated `et_tk.load()`, attempting to register already-existing theme elements. Disabled redundant re-initialization.
* **Null Pointer Dereference:** In `paint.cc`, `Tk_GetOption()` queries for `viewBackground` that return NULL were passed directly to `Tk_GetColor()`, causing a 64-bit segfault. Added safe color fallbacks (`gray90`).
* **Dummy `TkpInit` Override:** Excluded legacy `tkUnixInit.c` stub so Tk's official platform initialization is used.

---

## ⚙️ Building From Source (Optional)

If you are on an architecture other than `amd64` (e.g. ARM64 / Apple Silicon VM):

```bash
sudo ./build-from-source.sh
```

---

## 🗑️ Uninstalling

To remove the locks and custom binary:

```bash
sudo ./uninstall.sh
```

---

## 👤 Author

* **SpitFiyah** ([mirafnan619@gmail.com](mailto:mirafnan619@gmail.com))
