#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 -b main https://github.com/RooGhz720/perfx_sweet_kernel kernel
cd kernel
git clone --depth=1 -b master https://github.com/MASTERGUY/proton-clang clang
git clone --depth=1 -b incog https://github.com/RooGhz720/Anykernel3 AnyKernel
echo "Done"
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
export CONFIG_PATH=$PWD/arch/arm64/configs/sweet_defconfig
PATH="${PWD}/clang/bin:$PATH"
export ARCH=arm64
export KBUILD_BUILD_HOST="MyLabs"
export KBUILD_BUILD_USER="RooGhz720"
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$BOT_API/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="perf kernel sweet builbot drone herness"
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$BOT_API/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Redmi Note 10 Pro/Max (sweet)</b>"
}
# Fin Error
function finerr() {
    curl -F document=@$LOG "https://api.telegram.org/bot$BOT_API/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build logs"
}
# Compile plox
function compile() {
 make sweet_defconfig O=out
    make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      NM=llvm-nm \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip
  cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 perf-kernel-sweet-${TANGGAL}.zip *
    cd ..
}
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
finerr
push
