#!/bin/sh
# LuckyProxy Android Installer (Termux-compatible)
# Auto-detects arch, downloads binary + items.dat
# Usage: ./id.installer.sh [-d|--debug]

BASE_URL="https://luckyproxy.web.id"

# ANSI colors (no tput dependency)
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m'

# --- parse flags ---
DEBUG=0
for arg in "$@"; do
  case "$arg" in
    -d|--debug)
      DEBUG=1
      ;;
  esac
done

if [ "$DEBUG" -eq 1 ]; then
  BIN_NAME="LuckyProxy-debug"
  BIN_SUBPATH="LuckyProxy-debug"   # sesuaikan kalau path debug di server berbeda
  echo -e "${YELLOW}[INFO] Mode debug aktif, akan mengunduh ${BIN_NAME}${NC}"
else
  BIN_NAME="LuckyProxy"
  BIN_SUBPATH="LuckyProxy"
fi

# ensure curl is available
if ! command -v curl >/dev/null 2>&1; then
  echo -e "${RED}[ERROR] curl tidak ditemukan. Install: pkg install curl${NC}" >&2
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
      echo -e "${RED}[ERROR] arsitektur belum didukung: $arch${NC}" >&2
      exit 1
      ;;
  esac
}

# mapping ARCH (gaya Android) -> suffix asan pada nama file libclang_rt
asan_arch_suffix() {
  case "$1" in
    arm64-v8a)    echo "aarch64" ;;
    armeabi-v7a)  echo "arm" ;;
    x86_64)       echo "x86_64" ;;
    x86)          echo "i686" ;;
    *)
      echo -e "${RED}[ERROR] tidak ada mapping runtime ASan untuk arch: $1${NC}" >&2
      exit 1
      ;;
  esac
}

rm -f "$BIN_NAME"
ARCH=$(detect_arch)
echo -e "${CYAN}[INFO] Arsitektur: ${ARCH}${NC}"

# download binary
BIN_URL="$BASE_URL/android/$ARCH/bin/$BIN_SUBPATH"
echo -e "${CYAN}[INFO] Mengunduh ${BIN_NAME} ...${NC}"
curl -fsSL -o "$BIN_NAME" "$BIN_URL" || {
  echo -e "${RED}[ERROR] Download gagal (arch $ARCH / varian $BIN_NAME tidak tersedia?)${NC}" >&2
  exit 1
}
chmod +x "$BIN_NAME"
echo -e "${GREEN}[SUCCESS] Disimpan di: $(pwd)/$BIN_NAME${NC}"

# download ASan runtime lib untuk debug build
if [ "$DEBUG" -eq 1 ]; then
  ASAN_ARCH=$(asan_arch_suffix "$ARCH")
  ASAN_LIB="libclang_rt.asan-${ASAN_ARCH}-android.so"
  ASAN_URL="$BASE_URL/resources/bin/$ASAN_LIB"

  rm -f "$ASAN_LIB"
  echo -e "${CYAN}[INFO] Mengunduh ${ASAN_LIB} ...${NC}"
  curl -fsSL -o "$ASAN_LIB" "$ASAN_URL" || {
    echo -e "${RED}[ERROR] Gagal mengunduh $ASAN_LIB${NC}" >&2
    exit 1
  }
  echo -e "${GREEN}[SUCCESS] Disimpan di: $(pwd)/$ASAN_LIB${NC}"
fi

# download items.dat if missing
if [ ! -f items.dat ]; then
  echo -e "${YELLOW}[INFO] items.dat not found, downloading ...${NC}"
  curl -fsSL -o items.dat "$BASE_URL/resources/items.dat" || {
    echo -e "${RED}[ERROR] Failed to download items.dat, check your internet connection${NC}" >&2
    exit 1
  }
  echo -e "${GREEN}[SUCCESS] Disimpan di: $(pwd)/items.dat${NC}"
else
  echo -e "${YELLOW}[WARNING] items.dat sudah ada, melewati download.${NC}"
fi

# download cert + key if missing
for f in cert.pem key.pem; do
  if [ ! -f "$f" ]; then
    echo -e "${YELLOW}[INFO] $f tidak ditemukan, mengunduh ...${NC}"
    curl -fsSL -o "$f" "$BASE_URL/resources/certs/$f" || {
      echo -e "${RED}[ERROR] Gagal mengunduh $f${NC}" >&2
      exit 1
    }
    echo -e "${GREEN}[SUCCESS] Disimpan di: $(pwd)/$f${NC}"
  else
    echo -e "${YELLOW}[WARNING] $f sudah ada, melewati download.${NC}"
  fi
done

chmod +x "$BIN_NAME"

if [ "$DEBUG" -eq 1 ]; then
  echo -e "${GREEN}[SUCCESS] Selesai, sekarang Anda bisa menjalankan ${CYAN}LD_LIBRARY_PATH=. ./$BIN_NAME${NC}"
else
  echo -e "${GREEN}[SUCCESS] Selesai, sekarang Anda bisa menjalankan ${CYAN}./$BIN_NAME${NC}"
fi
