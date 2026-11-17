```text
        __    ____    __            ╭────────────╮ 
       /  \   \   \  /  \           │  user     │ Nguyen Hoang
       \   \   \   \/   /           ├────────────┤ 
     ___\   \___\      /            │  OS       │ NixOS 26.05 (Yarara) 
    /            \    /   /\        │  Kernel   │ Linux 7.2.9
   /______________\   \  /  \       │  WM       │ niri 26.04 (Wayland)
        /   /      \   \/   /       │ 󰏗 Packages │ 1 (appimage), 15 (flatpak), 1772 (nix-sys)
 ______/   /        \  /   /___     ╰────────────╯ 
/         /          \/        \    ╭────────────╮ 
\____    /\          /   ______/    │  Memory   │ 3.32 GiB / 15.37 GiB ( 22%% )  
    /   /  \        /   /           │  Disk     │ 178.05 GiB / 228.67 GiB ( 78%% ) 
   /   /\   \______/___/_____       │  Swap     │ 0 B / 16.48 GiB ( 0%% )
   \  /  \   \              /       │  CPU      │ 11th Gen Intel(R) Core(TM) i5-11320H (8)
    \/   /    \____    ____/        │  GPU      │ Intel Iris Xe Graphics (Integrated)
        /      \   \   \            │  OS age   │ 
       /   /\   \   \   \           ╰────────────╯
       \__/  \___\   \__/            
```


---

## Auto Install & Machine Migration 

### Quick Install

```bash
git clone https://github.com/ngKHoang-atDN/my-dotfile-Niri-noctalia.git
cd my-dotfile-Niri-noctalia
./install.sh
```

By default, `./install.sh`:
- Symlinks dotfiles into `~/.config` (backing up any existing files to `~/.config-backup-<timestamp>`).
- Copies `configuration.nix` and `npins/` to `/etc/nixos/` (backing up existing `/etc/nixos` files to `/etc/nixos/backup-<timestamp>`).
- **Preserves** the target machine's `/etc/nixos/hardware-configuration.nix` (or runs `sudo nixos-generate-config` if missing).
- Ensures the `unstable` nix-channel is added (required by `configuration.nix`).

### Options

| Flag | Description |
| :--- | :--- |
| `--dotfiles-only` | Only install dotfiles to `~/.config` |
| `--nixos-only` | Only install NixOS config to `/etc/nixos` |
| `--copy` | Copy dotfiles instead of creating symlinks |
| `--rebuild` | Automatically run `sudo nixos-rebuild switch` after copying NixOS config |
| `-h, --help` | Show help message |

### Notes for other hardware

1. **Hardware config**: Do **not** overwrite `/etc/nixos/hardware-configuration.nix` with the old machine's file. `install.sh` keeps the your generated `hardware-configuration.nix` automatically.
2. **GPU / NVIDIA (if applicable)**: If your hardware has a discrete NVIDIA GPU, review `configuration.nix` to enable `services.xserver.videoDrivers = [ "nvidia" ];` and `hardware.nvidia` options before running `sudo nixos-rebuild switch`.
3. **Apply system config**:
   ```bash
   sudo nixos-rebuild switch
   ```
   (or run `./install.sh --rebuild`).
