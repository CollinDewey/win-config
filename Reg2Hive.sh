#!/usr/bin/env nix
#! nix shell nixpkgs#hivex nixpkgs#coreutils nixpkgs#zstd nixpkgs#bash nixpkgs#dos2unix -c bash
# shellcheck shell=bash

HKCU_HIVE=CurrentUser.hive
HKLM_HIVE=LocalMachine.hive
HKCU_REG=CurrentUser.reg
HKLM_REG=LocalMachine.reg

# Convert reg to unix type
dos2unix "$HKCU_REG"
dos2unix "$HKLM_REG"

if [ -f "$HKCU_HIVE" ]; then
    rm "$HKCU_HIVE"
fi
if [ -f "$HKLM_HIVE" ]; then
    rm "$HKLM_HIVE"
fi

# Handcrafted Minimal Registry Hive
echo "
KLUv/QRYLQgAYo4qL1B1hjWAKDtnzsKqmJmdIkHa7s6f9dAcMef1TNwXtV1DhLSgmz+vbIN7KL+Y
3TIFBZ8PcNdV/cFdLaxBT86F03OqUwrHNqlLRcipzqR+bX1RAt6X8HuaVNJazctvWHwcQCGQRkan
0/nAqS3gkhLBgG0glVprK99aGnWIpHngaBl6URRiRYoTsyRHSD2OmprMSsQomvX0zFqP/W5+B8NC
oBJzIvP9goR8mAInIOACmiqGOTlOeLC1MC2UwX/S4jDw1sWOL+TEaxt3OvgK/E4Q3GxaeH0zSbjN
Ajsx8eve5Tl44jBA4DjfTwLLo4VgV2QXAAEVHmj+2tcuScU8ZBhvdwhjMdkTtg==
" | base64 -d | zstd -d -o "$HKCU_HIVE"
cp "$HKCU_HIVE" "$HKLM_HIVE"

# Merge
hivexregedit --merge --prefix 'HKEY_LOCAL_MACHINE' "$HKLM_HIVE" "$HKLM_REG"
hivexregedit --merge --prefix 'HKEY_CURRENT_USER' "$HKCU_HIVE" "$HKCU_REG"

# And then you have to go open the hives and deal with the GPO editor's awfulness