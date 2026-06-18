#!/bin/sh
set -e

case "$(uname -s)" in Darwin)
    case "$(uname -m)" in "x86_64" | "amd64")
        cc -O2 -c main.c
        ar -rcs sqlite3_darwin_amd64.a main.o
        ;;
    *)
        cc -O2 -c main.c
        ar -rcs sqlite3_darwin_arm64.a main.o
        ;;
    esac
    ;;
*)
    cc -O2 -c main.c
    ar -rcs sqlite3.a main.o
	;;
esac

rm *.o