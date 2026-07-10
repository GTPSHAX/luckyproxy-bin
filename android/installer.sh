#!/bin/sh
# LuckyProxy Android Installer (Termux-compatible)
# Auto-detects arch, downloads binary + items.dat
# Usage: ./installer.sh [-d|--debug] [-a|--arch <arch>]

BASE_URL="https://luckyproxy.web.id"

# ANSI colors (no tput dependency)
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m'

# --- parse flags ---
DEBUG=0
ARCH_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    -d|--debug)
      DEBUG=1
      shift
      ;;
    -a|--arch)
      ARCH_OVERRIDE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [ "$DEBUG" -eq 1 ]; then
  BIN_NAME="LuckyProxy-debug"
  BIN_SUBPATH="LuckyProxy-debug"   # adjust if debug path on server differs
  echo -e "${YELLOW}[INFO] Debug mode enabled, will download ${BIN_NAME}${NC}"
else
  BIN_NAME="LuckyProxy"
  BIN_SUBPATH="LuckyProxy"
fi

# ensure curl is available
if ! command -v curl >/dev/null 2>&1; then
  echo -e "${RED}[ERROR] curl required. Install: pkg install curl${NC}" >&2
  exit 1
fi

detect_arch() {
  local arch
  arch=$(uname -m 2>/dev/null)

  # fallback: Android property
  [ -z "$arch" ] && arch=$(getprop ro.product.cpu.abi 2>/dev/null)

  case "$arch" in
    aarch64|arm64-v8a)            echo "arm64-v8a" ;;
    armv7l|armv8l|armeabi-v7a|armeabi)   echo "armeabi-v7a" ;;
    x86_64|amd64)                 echo "x86_64" ;;
    i686|i386|x86)                echo "x86" ;;
    *)
      echo -e "${RED}[ERROR] unsupported arch: $arch${NC}" >&2
      exit 1
      ;;
  esac
}

# maps ARCH (Android-style) -> asan suffix used in libclang_rt filenames
asan_arch_suffix() {
  case "$1" in
    arm64-v8a)    echo "aarch64" ;;
    armeabi-v7a)  echo "arm" ;;
    x86_64)       echo "x86_64" ;;
    x86)          echo "i686" ;;
    *)
      echo -e "${RED}[ERROR] no ASan runtime mapping for arch: $1${NC}" >&2
      exit 1
      ;;
  esac
}

rm -f "$BIN_NAME"
if [ -n "$ARCH_OVERRIDE" ]; then
  case "$ARCH_OVERRIDE" in
    arm64-v8a|armeabi-v7a|x86_64|x86) ARCH="$ARCH_OVERRIDE" ;;
    *)
      echo -e "${RED}[ERROR] invalid arch: $ARCH_OVERRIDE (valid: arm64-v8a, armeabi-v7a, x86_64, x86)${NC}" >&2
      exit 1
      ;;
  esac
else
  ARCH=$(detect_arch)
fi
echo -e "${CYAN}[INFO] Architecture: ${ARCH}${NC}"

# download binary
BIN_URL="$BASE_URL/android/$ARCH/bin/$BIN_SUBPATH"
echo -e "${CYAN}[INFO] Downloading ${BIN_NAME} ...${NC}"
curl -fsSL -o "$BIN_NAME" "$BIN_URL" || {
  echo -e "${RED}[ERROR] Download failed (arch $ARCH / variant $BIN_NAME not available?)${NC}" >&2
  exit 1
}
chmod +x "$BIN_NAME"
echo -e "${GREEN}[SUCCESS] Saved: $(pwd)/$BIN_NAME${NC}"

# download ASan runtime lib for debug builds
if [ "$DEBUG" -eq 1 ]; then
  ASAN_ARCH=$(asan_arch_suffix "$ARCH")
  ASAN_LIB="libclang_rt.asan-${ASAN_ARCH}-android.so"
  ASAN_URL="$BASE_URL/resources/bin/$ASAN_LIB"

  rm -f "$ASAN_LIB"
  echo -e "${CYAN}[INFO] Downloading ${ASAN_LIB} ...${NC}"
  curl -fsSL -o "$ASAN_LIB" "$ASAN_URL" || {
    echo -e "${RED}[ERROR] Failed to download $ASAN_LIB${NC}" >&2
    exit 1
  }
  echo -e "${GREEN}[SUCCESS] Saved: $(pwd)/$ASAN_LIB${NC}"
fi

# download items.dat if missing
if [ ! -f items.dat ]; then
  echo -e "${YELLOW}[INFO] items.dat not found, downloading ...${NC}"
  curl -fsSL -o items.dat "$BASE_URL/resources/items.dat" || {
    echo -e "${RED}[ERROR] Failed to download items.dat, check your internet connection${NC}" >&2
    exit 1
  }
  echo -e "${GREEN}[SUCCESS] Saved: $(pwd)/items.dat${NC}"
else
  echo -e "${YELLOW}[WARNING] items.dat exists, skipping.${NC}"
fi

# download cert + key if missing
for f in cert.pem key.pem; do
  if [ ! -f "$f" ]; then
    echo -e "${YELLOW}[INFO] $f not found, downloading ...${NC}"
    curl -fsSL -o "$f" "$BASE_URL/resources/certs/$f" || {
      echo -e "${RED}[ERROR] Failed to download $f${NC}" >&2
      exit 1
    }
    echo -e "${GREEN}[SUCCESS] Saved: $(pwd)/$f${NC}"
  else
    echo -e "${YELLOW}[WARNING] $f exists, skipping.${NC}"
  fi
done

chmod +x "$BIN_NAME"

if [ "$DEBUG" -eq 1 ]; then
  echo -e "${GREEN}[SUCCESS] Done, now you can run ${CYAN}LD_LIBRARY_PATH=. ./$BIN_NAME${NC}"
else
  echo -e "${GREEN}[SUCCESS] Done, now you can run ${CYAN}./$BIN_NAME${NC}"
fi
