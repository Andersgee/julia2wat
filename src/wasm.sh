#!/bin/bash

function echo_usage()
{
  echo "Usage: $(basename "$0") file1.wat file2.wasm"
  echo "runs wat2wasm (webassembly binary toolkit)"
  echo "then wasm-opt (binaryen)"
  exit 64
}

if [ $# -lt 2 ]
then
  echo_usage
elif [ $# -lt 3 ]
then
	/home/andy/dev/wabt/bin/wat2wasm "$1" -o "$2"
	/home/andy/dev/wabt/bin/wasm2wat "$2" -o "$1"
else
	/home/andy/dev/wabt/bin/wat2wasm "$1" -o "$2"
	/home/andy/dev/binaryen/bin/wasm-opt "$2" -o "$2" "$3"
	/home/andy/dev/wabt/bin/wasm2wat "$2" -o "$1"
fi
