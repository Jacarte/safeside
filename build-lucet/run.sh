#!/bin/bash

if [[ $1 == "pht_sa" ]]; then
  SO=spectre_v1_pht_sa.so
elif [[ $1 == "ret2spec_sa" ]]; then
  SO=ret2spec_sa.so
else
  echo "error: First argument should be either pht_sa or ret2spec_sa"
  exit 1
fi

if [[ $2 == "" ]]; then
  echo "error: Requires a second argument, which should be the name of a directory in build/"
  exit 1
elif [ ! -d "./build/$2" ]; then
  echo "error: Second argument should be the name of a directory in build/"
  exit 1
fi

if [[ $2 == *aslr ]]; then
  ASLR_FLAGS="--spectre-mitigation-aslr"
else
  ASLR_FLAGS=
fi

../../lucet-spectre-repro/target/release/lucet-wasi \
    --heap-address-space "8GiB" \
    --max-heap-size "4GiB" \
    --stack-size "128MiB" \
    --dir /:/ \
    $ASLR_FLAGS \
    ./build/$2/$SO
