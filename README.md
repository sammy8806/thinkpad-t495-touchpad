# thinkpad-t495-touchpad

DKMS package that runs the ThinkPad T495 (AMD) Synaptics touchpad (`LEN2062`, TM3471) over **RMI4/SMBus** instead of PS/2 on Linux.

Tested on a T495 with Fedora 44, kernel 7.2.9, Hyprland/libinput 1.31. Survives reboot and suspend/resume.

## Why

In PS/2 mode the pad is "semi-multitouch": two-finger scroll updates arrive every ~25 ms, irregularly, and fingers are sometimes lost. The pad can also speak RMI4 over SMBus (Windows does this), but stock `i2c-piix4` has no SMBus Host Notify on AMD, so `psmouse` never hands over (`SMbus companion is not ready yet`). The AMD FCH provides Host Notify through its ASF block (ACPI `SMB0001`); these patches use it.

Measured with `libinput debug-events` on repeated two-finger flicks:

| | PS/2 | RMI4/SMBus |
|---|---|---|
| Time between scroll events | ~25 ms, irregular | 15.5 ms, steady |
| Events per flick | 1-3 | 15+ |
| "Touch jump" kernel errors | 6 | 0 |

## What it contains

Pristine kernel **v7.2.9** sources of `i2c-piix4` and `rmi_smbus` plus two patches from [orospakr/thinkpad-t14-amd-touchpad](https://github.com/orospakr/thinkpad-t14-amd-touchpad) (same `1022:790b` controller, written for the T14 Gen 2 AMD):

- `0001` i2c-piix4: SMBus Host Notify through the ASF block on `SMB0001` platforms
- `0002` rmi_smbus: let the device settle after the PS/2 reset on resume

Upstream's `psmouse` patches are not used, because `psmouse` is built into Fedora's kernel. The allowlist is replaced by a kernel argument.

## Install

```
sudo dnf install dkms kernel-devel
sudo cp -r . /usr/src/thinkpad-t495-touchpad-0.1
sudo dkms install thinkpad-t495-touchpad/0.1
sudo grubby --update-kernel=ALL --args="psmouse.synaptics_intertouch=1"
```

Also add the argument to `/etc/kernel/cmdline` and `GRUB_CMDLINE_LINUX` in `/etc/default/grub` so new kernels get it. Reboot.

Secure Boot must be off, or enroll the DKMS MOK key (`/var/lib/dkms/mok.pub`).

## Verify

```
grep 'N: Name' /proc/bus/input/devices    # "Synaptics TM3471-020"
journalctl -k -b | grep -E 'Host Notify|rmi4'
dkms status
```

If the pad is back to `SynPS/2 Synaptics TouchPad`, check the DKMS build log for the running kernel.

## Uninstall

```
sudo dkms remove thinkpad-t495-touchpad/0.1 --all
sudo rm -rf /usr/src/thinkpad-t495-touchpad-0.1
sudo grubby --update-kernel=ALL --remove-args="psmouse.synaptics_intertouch=1"
```

## Caveats

- Sources are from v7.2.9. Building for another kernel series prints a warning; refresh the sources if the pad falls back to PS/2.
- The kernel is tainted by the out-of-tree modules.
- Known glitch: the lighter-pressed finger sometimes holds its position for one frame mid-flick (5.4% of frames with fingers stacked vertically, 1.8% side by side).
- Only the T495 (`LEN2062`) has been tested. The E495 (`LEN205D`) uses the same Windows driver group and may work too.

## License

GPL-2.0, same as the kernel sources and the upstream patches. See `LICENSE`.
