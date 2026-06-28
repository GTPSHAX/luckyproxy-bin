#!/bin/sh
# LuckyProxy Android Installer (Termux-compatible)
# Auto-detects arch, downloads binary + items.dat

BASE_URL="https://luckyproxy.web.id"

# Color definitions
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
NC=$(tput sgr0)

# ensure curl is available
if ! command -v curl >/dev/null 2>&1; then
  echo "${RED}curl required. Install: pkg install curl${NC}" >&2
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
      echo "${RED}unsupported arch: $arch${NC}" >&2
      exit 1
      ;;
  esac
}

ARCH=$(detect_arch)
echo "${CYAN}Architecture: ${ARCH}${NC}"

# download binary
BIN_URL="$BASE_URL/android/$ARCH/bin/LuckyProxy"
echo "${CYAN}Downloading ${BIN_URL} ...${NC}"
curl -fSL -o LuckyProxy "$BIN_URL" || {
  echo "${RED}Download failed (arch $ARCH not available?)${NC}" >&2
  exit 1
}
chmod +x LuckyProxy
echo "${GREEN}LuckyProxy saved: $(pwd)/LuckyProxy${NC}"

# download items.dat if missing
if [ ! -f items.dat ]; then
  echo "${YELLOW}items.dat not found, downloading ...${NC}"
  curl -fSL -o items.dat "$BASE_URL/resources/items.dat" || {
    echo "${RED}Failed to download items.dat${NC}" >&2
    exit 1
  }
  echo "${GREEN}items.dat saved: $(pwd)/items.dat${NC}"
else
  echo "${YELLOW}items.dat exists, skipping.${NC}"
fi

echo "${GREEN}Done.${NC}"
