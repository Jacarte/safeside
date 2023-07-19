echo This script generates 100*1000 variants of the ret2spec_sa.wasm and spectre_v1_pht_sa.wasm files.
echo Downloading the stacking tool...
# Download the stacking tool
VERSION="0.8.0"
if [[ ! -f stacking.${VERSION}.gz ]]; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
        exit 1
    else
        curl --fail --location --silent https://github.com/Jacarte/tawasco/releases/download/${VERSION}/stacking-all-x86_64-linux-${VERSION}.gz --output stacking.${VERSION}.gz || exit 1
    fi
    7z x stacking.${VERSION}.gz || exit 1
    chmod +x stacking
fi

echo "Wiping pool..."
rm -rf ret2_pool
rm -rf pht_pool

RANDOM=1
rm -rf cache

echo "Generating variants..."

mkdir -p ret2_pool
mkdir -p pht_pool

cp original_wasms/ret2spec_sa.wasm ret2_pool/ret2spec_sa.wasm
cp original_wasms/spectre_v1_pht_sa.wasm pht_pool/spectre_v1_pht_sa.wasm
# We generate 1000 with 100 different seeds
# We have a total of 100*1000 variants :)
# Generate the breakout variants
for seed in $(seq 1 100)
do
    S=$RANDOM

    echo $seed
    RUST_LOG=wasm_mutate=debug ./stacking build/spectre_v1_pht_sa.wasm pht_pool/pht.stack.$S.wasm --seed $S -c 1000 --save 1  2> pht_pool/logs.$S.break.txt
#    RUST_LOG=wasm_mutate=debug ./stacking build/ret2spec_sa.wasm ret2_pool/ret2.stack.$S.wasm --seed $S -c 1000 --save 1  2> ret2_pool/logs.$S.break.txt


done

echo "Done!"
# Generate the leakage variants
