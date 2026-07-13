#!/bin/sh

BASE_URL="https://luckyproxy.web.id"
RESOURCE_DIR="resources"

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m'

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
  BIN_SUBPATH="LuckyProxy-debug"
  echo -e "${YELLOW}[INFO] Debug mode enabled, will download ${BIN_NAME}${NC}"
else
  BIN_NAME="LuckyProxy"
  BIN_SUBPATH="LuckyProxy"
fi

if ! command -v curl >/dev/null 2>&1; then
  echo -e "${RED}[ERROR] curl required. Install: pkg install curl${NC}" >&2
  exit 1
fi

detect_arch() {
  local arch
  arch=$(uname -m 2>/dev/null)

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

rm -f "$BIN_NAME"
mkdir -p "$RESOURCE_DIR"
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

BIN_URL="$BASE_URL/beta/android/$ARCH/bin/$BIN_SUBPATH"
echo -e "${CYAN}[INFO] Downloading ${BIN_NAME} ...${NC}"
curl -fsSL -o "$BIN_NAME" "$BIN_URL" || {
  echo -e "${RED}[ERROR] Download failed (arch $ARCH / variant $BIN_NAME not available?)${NC}" >&2
  exit 1
}
chmod +x "$BIN_NAME"
echo -e "${GREEN}[SUCCESS] Saved: $(pwd)/$BIN_NAME${NC}"

download_resource() {
  resource_path="$1"
  destination="$RESOURCE_DIR/$resource_path"

  if [ ! -f "$destination" ]; then
    mkdir -p "$(dirname "$destination")"
    echo -e "${CYAN}[INFO] Downloading $resource_path ...${NC}"
    curl -fsSL -o "$destination" "$BASE_URL/beta/resources/$resource_path" || {
      echo -e "${RED}[ERROR] Failed to download $resource_path${NC}" >&2
      exit 1
    }
    echo -e "${GREEN}[SUCCESS] Saved: $(pwd)/$destination${NC}"
  else
    echo -e "${YELLOW}[WARNING] $resource_path exists, skipping.${NC}"
  fi
}

for resource_path in \
  config.json \
  items.dat \
  certs/cert.pem \
  certs/key.pem \
  certs/www.growtopia1.com-key.pem \
  certs/www.growtopia1.com-cert.pem \
  bin/libclang_rt.asan-aarch64-android.so \
  bin/libclang_rt.asan-arm-android.so \
  bin/libclang_rt.asan-i686-android.so \
  bin/libclang_rt.asan-riscv64-android.so \
  bin/libclang_rt.asan-x86_64-android.so; do
  download_resource "$resource_path"
done

chmod +x "$BIN_NAME"

if [ "$DEBUG" -eq 1 ]; then
  echo -e "${GREEN}[SUCCESS] Done, now you can run ${CYAN}LD_LIBRARY_PATH=$RESOURCE_DIR ./$BIN_NAME${NC}"
else
  echo -e "${GREEN}[SUCCESS] Done, now you can run ${CYAN}./$BIN_NAME${NC}"
fi
