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





#!/bin/bash

kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
anykernel=$HOME/anykernel
builddir="${kernel_dir}/build"
ZIMAGE=$kernel_dir/out/arch/arm64/boot/Image.gz-dtb
kernel_name="perfx-sweet"
zip_name="$kernel_name-$(date +"%d%m%Y-%H%M").zip"
TC_DIR=$HOME/tc/
CLANG_DIR=$TC_DIR/clang-r458507
export CONFIG_FILE="sweet_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=MyLabs
export KBUILD_BUILD_USER=RooGhz720

export PATH="$CLANG_DIR/bin:$PATH"

if ! [ -d "$TC_DIR" ]; then
    echo "Toolchain not found! Cloning to $TC_DIR..."
    if ! git clone -q --depth=1 --single-branch https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 -b master $TC_DIR; then
        echo "Cloning failed! Aborting..."
        exit 1
    fi
fi

# Colors
NC='\033[0m'
RED='\033[0;31m'
LRD='\033[1;31m'
LGR='\033[1;32m'

make_defconfig()
{
    START=$(date +"%s")
    echo -e ${LGR} "########### Generating Defconfig ############${NC}"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc --all)
}
compile()
{
    cd ${kernel_dir}
    echo -e ${LGR} "######### Compiling kernel #########${NC}"
    make -j$(nproc --all) \
    O=out \
    ARCH=${ARCH}\
    CC="ccache clang" \
    CLANG_TRIPLE="aarch64-linux-gnu-" \
    CROSS_COMPILE="aarch64-linux-gnu-" \
    CROSS_COMPILE_ARM32="arm-linux-gnueabi-" \
    LLVM=1 \
    LLVM_IAS=1
}

completion()
{
    cd ${objdir}
    COMPILED_IMAGE=arch/arm64/boot/Image.gz-dtb
    COMPILED_DTBO=arch/arm64/boot/dtbo.img
    if [[ -f ${COMPILED_IMAGE} && ${COMPILED_DTBO} ]]; then

        git clone -q https://github.com/RooGhz720/Anykernel3 -b incog $anykernel

        mv -f $ZIMAGE ${COMPILED_DTBO} $anykernel

        cd $anykernel
        find . -name "*.zip" -type f
        find . -name "*.zip" -type f -delete
        zip -r AnyKernel.zip *
        mv AnyKernel.zip $zip_name
        mv $anykernel/$zip_name $HOME/$zip_name
        rm -rf $anykernel
        END=$(date +"%s")
        DIFF=$(($END - $START))
        curl --upload-file $HOME/$zip_name https://free.keep.sh; echo
        rm $HOME/$zip_name
        echo -e ${LGR} "############################################"
        echo -e ${LGR} "############# OkThisIsEpic!  ##############"
        echo -e ${LGR} "############################################${NC}"
        exit 0
    else
        echo -e ${RED} "############################################"
        echo -e ${RED} "##         This Is Not Epic :'(           ##"
        echo -e ${RED} "############################################${NC}"
        exit 1
    fi
}
make_defconfig
compile
completion
cd ${kernel_dir}

