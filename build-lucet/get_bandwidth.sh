
# while true execute make
echo "" > results_ret2.txt
# echo "" > results_pht.txt

safeside_SOURCE_DIR=./..
LUCET_WASI_DIR=./../../lucet-spectre-repro/lucet-wasi
LUCET_DIR=./../../lucet-spectre-repro
WASI_SDK_DIR=./../../wasi-sdk-custom/build/install/opt/wasi-sdk
WASI_SYSROOT_DIR=${WASI_SDK_DIR}/share/wasi-sysroot
WASICLANG=${WASI_SDK_DIR}/bin/clang
WASICLANG++=${WASI_SDK_DIR}/bin/clang++
LUCETC=${LUCET_DIR}/target/release/lucetc
WASI_BINDINGS_JSON=${safeside_SOURCE_DIR}/build-lucet/bindings.json
NATIVE_CLANG++=/usr/bin/clang++


CMAKE_C_FLAGS="--sysroot ${WASI_SYSROOT_DIR} --target=wasm32-wasi"
CMAKE_CXX_FLAGS="--sysroot ${WASI_SYSROOT_DIR} -fno-exceptions --target=wasm32-wasi"
# Link flags are set by default on Mac - clearing this
CMAKE_C_LINK_FLAGS=""
CMAKE_EXE_LINKER_FLAGS="-Wl,--export-all"

LUCETC_FLAGS="--bindings ${WASI_BINDINGS_JSON}  --pinned-heap-reg --guard-size 4GiB --min-reserved-size 4GiB --max-reserved-size 4GiB"

echo 0 | sudo tee /proc/sys/kernel/randomize_va_space

function evaluate(){
    POOL=$1
    WASM=$2
    
    LIMIT=$3
    RESULT_FILE=$4
    NAME=$5

    rm -rf ${NAME}_out
    mkdir -p ${NAME}_out

    while true
    do
        
        # select one random file from the pool
        bash get_random_wasm.sh $POOL $WASM $LIMIT >> $RESULT_FILE 
        # sanity step, remove the stock folder
        rm $NAME.so

        # Compile to .so
        echo ${LUCETC} ${LUCETC_FLAGS} $WASM -o $NAME.so
        ${LUCETC} ${LUCETC_FLAGS} $WASM -o $NAME.so
        cp $NAME.so ${NAME}_out/$(sha256sum $NAME.so | cut -d " " -f 1).so



        echo "======================= EVALUATING PHT ======================="

        echo $(md5sum $NAME.so)
        echo $(md5sum $NAME.so) >> $RESULT_FILE
        echo $(md5sum $NAME.wasm) >> $RESULT_FILE
        echo "======================= EVALUATING PHT =======================" >> $RESULT_FILE
        # Compile to .so
        echo ../../lucet-spectre-repro/target/release/lucet-wasi \
            --heap-address-space "8GiB" \
            --max-heap-size "4GiB" \
            --stack-size "8MiB" \
            --dir /:/ \
            $ASLR_FLAGS \
            ./$NAME.so

        # Call this several times, for some reason the first call is always faster and unsuccesfull
        i=0
        while true
        do
            echo "==== $i START" 
            echo "==== $i START" >> $RESULT_FILE
            NOW=$(date +"%T")
            { time ../../lucet-spectre-repro/target/release/lucet-wasi --heap-address-space "8GiB" --max-heap-size "4GiB" --stack-size "128MiB" --dir /:/ ./$NAME.so; } >> $RESULT_FILE 2>&1
            ELAPSED=$(($(date +"%s") - $(date -d "$NOW" +"%s")))

             
            EXIT_CODE=$?
            
	    

            # sleep 1

            if [ $EXIT_CODE -eq 0 ]; then
                echo "SUCCESS" >> $RESULT_FILE
            else
                echo "FAILURE" >> $RESULT_FILE
            fi

            
            if [ $ELAPSED -gt 10 ]; then
                echo "======== REAL" >> $RESULT_FILE 
                echo "==== $i END" >> $RESULT_FILE
                break
            fi
            i=$((i+1))

            if [ $NAME != "spectre_v1_pht_sa" ]; then
                # just check i and break if larger than 10
                if [ $i -gt 7 ]; then 
                    echo "==== $i END" >> $RESULT_FILE
                    break
                fi
            else
                if [ $i -gt 100 ]; then 
                    echo "==== $i END" >> $RESULT_FILE
                    break
                fi
            fi
        done

        echo "======================= DONE ======================="
        echo "======================= DONE =======================" >> $RESULT_FILE
    done
}

evaluate pht_pool/ spectre_v1_pht_sa.wasm pht.stack.8913.wasm.1000.wasm  results_pht.txt spectre_v1_pht_sa
#evaluate ret2_pool/ ret2spec_sa.wasm ret2.stack.3114.wasm.3000.wasm  ret2.stack.txt ret2spec_sa
# evaluate pht_pool/ spectre_v1_pht_sa.wasm pht.stack.3114.wasm.3000.wasm  results_pht.txt spectre_v1_pht_sa

