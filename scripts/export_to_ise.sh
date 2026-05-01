#!/bin/bash

set -e

PROJECT_NAME="FPGA_CW_6sem_tools"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ROOT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

if [ -z "$1" ]; then
    echo "Usage:"
    echo "  ./export_to_ise.sh <target_dir>"
    echo ""
    echo "Example:"
    echo "  ./export_to_ise.sh /d/VivadoISE/VivadoISEVMProjects/"
    exit 1
fi

TARGET_ROOT="$1"
TARGET_DIR="$TARGET_ROOT/$PROJECT_NAME"

echo "SCRIPT_DIR = $SCRIPT_DIR"
echo "ROOT_DIR   = $ROOT_DIR"
echo "TARGET_DIR = $TARGET_DIR"

if [ -d "$TARGET_DIR" ]; then
    echo "Removing old directory..."
    rm -rf "$TARGET_DIR"
fi

mkdir -p "$TARGET_DIR"

echo "Copying files..."

cp -r "$ROOT_DIR/files" "$TARGET_DIR/"
cp "$ROOT_DIR/scripts/create_ise_project.tcl" "$TARGET_DIR/"

echo "Done!"

echo ""
echo "Run in VM terminal:"
echo "cd ~/VivadoISEVMProjects/$PROJECT_NAME"
echo "xtclsh create_ise_project.tcl"