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

BUILD_TARGETS=("afl-fuzz" "afl-fuzz-noaffin" "afl-fuzz-print" "afl-fuzz-noaffin-print" "afl-fuzz-noaffin-coredump" "afl-fuzz-long" "afl-fuzz-noaffin-long")
BUILD_FLAGS=("" "-DNOAFFIN_BENCH=1" "-DPRINT_BENCH=1" "-DNOAFFIN_BENCH=1 -DPRINT_BENCH=1" "-DNOAFFIN_BENCH=1 -DCORE_BENCH=1 -DLONG_BENCH=1" "-DLONG_BENCH=1" "-DNOAFFIN_BENCH=1 -DLONG_BENCH=1")

git clone https://github.com/andronat/aflnet.git --branch mymaster --single-branch aflnet
cd aflnet

IT=0
for TARGET in "${BUILD_TARGETS[@]}"; do
  echo "Building target: ${TARGET}"

  export CFLAGS="-O3 -funroll-loops ${BUILD_FLAGS[${IT}]}"
  touch afl-fuzz.c && touch debug.h
  make -j all && cd llvm_mode/ && make -j && echo $? && cd ..

  cp "./afl-fuzz" "${FINISH_DIR}/${TARGET}"
  cp "./aflnet-replay" "${FINISH_DIR}/aflnet-replay"
  ((IT = IT + 1))
done

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

cmake -DCMAKE_BUILD_TYPE=RELEASE -DSF_MEMFS=OFF -DSF_STDIO=OFF -DSF_SLEEP=OFF -DSF_SMARTDEFER=OFF ..
make -j
cp ./sabre "${FINISH_DIR}/sabre"
cp ./plugins/sbr-afl/libsbr-afl.so "${FINISH_DIR}/libsbr-afl-only-protocol.so"
cp ./plugins/sbr-afl/libsbr-afl.so "${FINISH_DIR}/libsbr-afl-and-affin.so"

cmake -DCMAKE_BUILD_TYPE=RELEASE -DSF_MEMFS=OFF -DSF_STDIO=OFF -DSF_SLEEP=ON -DSF_SMARTDEFER=OFF ..
make -j
cp ./sabre "${FINISH_DIR}/sabre"
cp ./plugins/sbr-afl/libsbr-afl.so "${FINISH_DIR}/libsbr-afl-and-sleep.so"

cmake -DCMAKE_BUILD_TYPE=RELEASE -DSF_MEMFS=OFF -DSF_STDIO=ON -DSF_SLEEP=ON -DSF_SMARTDEFER=OFF ..
make -j
cp ./sabre "${FINISH_DIR}/sabre"
cp ./plugins/sbr-afl/libsbr-afl.so "${FINISH_DIR}/libsbr-afl-and-stdio.so"

cmake -DCMAKE_BUILD_TYPE=RELEASE -DSF_MEMFS=OFF -DSF_STDIO=ON -DSF_SLEEP=ON -DSF_SMARTDEFER=ON ..
make -j
cp ./sabre "${FINISH_DIR}/sabre"
cp ./plugins/sbr-afl/libsbr-afl.so "${FINISH_DIR}/libsbr-afl-and-defer.so"

cmake -DCMAKE_BUILD_TYPE=RELEASE -DSF_MEMFS=ON -DSF_STDIO=ON -DSF_SLEEP=ON -DSF_SMARTDEFER=ON ..
make -j
cp ./sabre "${FINISH_DIR}/sabre"
cp ./plugins/sbr-afl/libsbr-afl.so "${FINISH_DIR}/libsbr-afl-and-fs.so"

cd $RETURN_PWD
