#!/bin/sh
# LuckyProxy Android Installer (Termux-compatible)
# Auto-detects arch, downloads binary + items.dat

BASE_URL="https://luckyproxy.web.id"

# ANSI colors (no tput dependency)
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m'

# ensure curl is available
if ! command -v curl >/dev/null 2>&1; then
  echo -e "${RED}curl required. Install: pkg install curl${NC}" >&2
  exit 1
fi

detect_arch() {
  local arch
  arch=$(uname -m 2>/dev/null)

  # fallback: Android property
  [ -z "$arch" ] && arch=$(getprop ro.product.cpu.abi 2>/dev/null)

  case "$arch" in
    aarch64|arm64-v8a)            echo "arm64-v8a" ;;
    armv7l|armeabi-v7a|armeabi)   echo "armeabi-v7a" ;;
    x86_64|amd64)                 echo "x86_64" ;;
    i686|i386|x86)                echo "x86" ;;
    *)
      echo -e "${RED}unsupported arch: $arch${NC}" >&2
      exit 1
      ;;
  esac
}

ARCH=$(detect_arch)
echo -e "${CYAN}[*] Architecture: ${ARCH}${NC}"

# download binary
BIN_URL="$BASE_URL/android/$ARCH/bin/LuckyProxy"
echo -e "${CYAN}[*] Downloading LuckyProxy ...${NC}"
curl -fsSL -o LuckyProxy "$BIN_URL" || {
  echo -e "${RED}[!] Download failed (arch $ARCH not available?)${NC}" >&2
  exit 1
}
chmod +x LuckyProxy
echo -e "${GREEN}[+] Saved: $(pwd)/LuckyProxy${NC}"

# download items.dat if missing
if [ ! -f items.dat ]; then
  echo -e "${YELLOW}[*] items.dat not found, downloading ...${NC}"
  curl -fsSL -o items.dat "$BASE_URL/resources/items.dat" || {
    echo -e "${RED}[!] Failed to download items.dat${NC}" >&2
    exit 1
  }
  echo -e "${GREEN}[+] Saved: $(pwd)/items.dat${NC}"
else
  echo -e "${YELLOW}[-] items.dat exists, skipping.${NC}"
fi

echo -e "${GREEN}[+] Done.${NC}"
