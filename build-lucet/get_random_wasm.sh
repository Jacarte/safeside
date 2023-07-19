# This script get a random file from the pool and copy it to the current directory as btb_breakout.wasm
# Then it removes the file from the pool folder
POOL=$1
ORIGINAL=$2
LARGEST_NAME=$3

touch $ORIGINAL

# If btb_breakout.wasm is found, return immediately
if [ -f "$POOL/$ORIGINAL" ]
then
    echo "Taking original"
    mv "$POOL/$ORIGINAL" $ORIGINAL
    exit 0
fi

# If btb_breakout.wasm is found, return immediately
if [ -f "$POOL/*.stack.*.wasm.0.wasm" ]
then
    echo "Taking original again"
    mv "$POOL/$ORIGINAL" $ORIGINAL
    exit 0
fi


# Take the largest file form the pool (name specified) and retunr immediately

if [ -f "$POOL/$LARGEST_NAME" ]
then
    echo "Taking large"
    mv "$POOL/$LARGEST_NAME" $ORIGINAL
    exit 0
fi

# If the pool folder is empty, return immediately
if [ -z "$(ls -A $POOL)" ]
then
    echo "Pool empty"
    exit 1
fi

# Otherwise take a random file from the pool if the file ends with wasm
FILE=$(find $POOL/ -type f -name '*.wasm' | shuf -n 1)
echo "Taking random $FILE"
mv "$FILE" $ORIGINAL
