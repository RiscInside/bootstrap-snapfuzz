#!/usr/bin/env bash

RETURN_PWD=$(pwd)

cd "$(dirname "$0")"

FINISH_DIR=$(pwd)

if [ -d "./builds" ]; then
  echo "./builds already exists! Delete it for a fresh build."
  exit 1
fi

mkdir -p "./builds"
cd "./builds"
BUILD_DIR=$(pwd)

#### Build AFLNet ####
cd "${BUILD_DIR}"

BUILD_TARGETS=("afl-fuzz-noaffin" "afl-fuzz-noaffin-long")
BUILD_FLAGS=("-DNOAFFIN_BENCH=1" "-DNOAFFIN_BENCH=1 -DLONG_BENCH=1")

git clone https://github.com/andronat/aflnet.git --branch mymaster --single-branch aflnet
cd aflnet

IT=0
for TARGET in "${BUILD_TARGETS[@]}"; do
  echo "Building target: ${TARGET}"

  export CFLAGS="-O3 -funroll-loops ${BUILD_FLAGS[${IT}]}"
  touch afl-fuzz.c && touch debug.h
  make -j all && cd llvm_mode/ && make -j && echo $? && cd ..

  cp "./afl-fuzz" "${FINISH_DIR}/${TARGET}"
  ((IT = IT + 1))
done

# Profuzzbench always uses binary called afl-fuzz
ln -s ${FINISH_DIR}/afl-fuzz-noaffin-long ${FINISH_DIR}/afl-fuzz

# Copu other binaries
cp ./afl-clang-* ./afl-as ./afl-gcc ./afl-g++ ./aflnet-replay "${FINISH_DIR}/"

#### Build SnapFuzz ####
cd "${BUILD_DIR}"

git clone https://github.com/andronat/SaBRe.git --branch snapfuzz --single-branch sabre
cd sabre

mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=RELEASE ..
make -j
cp ./sabre "${FINISH_DIR}/sabre"
cp ./plugins/sbr-afl/libsbr-afl.so "${FINISH_DIR}/libsbr-afl.so"

cd $RETURN_PWD
