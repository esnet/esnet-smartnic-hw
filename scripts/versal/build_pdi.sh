#!/usr/bin/env bash
# Build firmware and generate final flashable PDI for ESnet SmartNIC Versal.
#
# Stages the completed hardware build outputs (PDI + XSA) into the AVED
# reference design directory, strips the hardware synthesis step from the
# AVED build_all.sh script, runs the remaining steps (firmware build, FPT
# generation, bootgen, FPT+PDI merge), and copies the results back to the
# hardware output directory.
#
# Usage:
#   build_pdi.sh -p <project_root> -o <output_dir> [-d <aved_design>] [-t <top>]
#
#   -p  Project root directory (SMARTNIC_ROOT)
#   -o  Hardware build output directory (contains <top>.pdi and <top>.xsa)
#   -d  AVED base design name (default: amd_v80_gen5x8_25.1)
#   -t  Top-level module name (default: esnet_smartnic)
#
set -Eeuo pipefail

# --- Defaults ---
AVED_BASE_DESIGN="amd_v80_gen5x8_25.1"
TOP="esnet_smartnic"
PROJECT_ROOT=""
OUTPUT_DIR=""

# --- Helpers ---
die() { echo "ERROR: $*" >&2; exit 1; }

banner() {
    echo "----------------------------------------------------------"
    echo "  $*"
    echo "----------------------------------------------------------"
}

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p) PROJECT_ROOT="$2"; shift 2 ;;
        -o) OUTPUT_DIR="$2";   shift 2 ;;
        -d) AVED_BASE_DESIGN="$2"; shift 2 ;;
        -t) TOP="$2";          shift 2 ;;
        -h|--help)
            sed -n '/^# Usage:/,/^#$/p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -n "${PROJECT_ROOT}" ]] || die "-p <project_root> is required"
[[ -n "${OUTPUT_DIR}" ]]   || die "-o <output_dir> is required"

PROJECT_ROOT=$(realpath "${PROJECT_ROOT}")
OUTPUT_DIR=$(realpath "${OUTPUT_DIR}")

AVED_HW_DIR="${PROJECT_ROOT}/src/xilinx/aved/hw/${AVED_BASE_DESIGN}"
BUILD_ALL="${AVED_HW_DIR}/build_all.sh"

# --- Validate prerequisites ---
[[ -d "${AVED_HW_DIR}" ]]  || die "AVED HW directory not found: ${AVED_HW_DIR}"
[[ -f "${BUILD_ALL}" ]]    || die "AVED build_all.sh not found: ${BUILD_ALL}"
[[ -f "${OUTPUT_DIR}/${TOP}.pdi" ]] || die "HW PDI not found: ${OUTPUT_DIR}/${TOP}.pdi"
[[ -f "${OUTPUT_DIR}/${TOP}.xsa" ]] || die "HW XSA not found: ${OUTPUT_DIR}/${TOP}.xsa"

echo "============================================================"
echo "ESnet SmartNIC Versal PDI Generation"
echo "  Project root  : ${PROJECT_ROOT}"
echo "  Output dir    : ${OUTPUT_DIR}"
echo "  AVED design   : ${AVED_BASE_DESIGN}"
echo "  Top module    : ${TOP}"
echo "============================================================"

# ============================================================
# Stage HW outputs into the AVED directory structure
# ============================================================
banner "Staging HW outputs into AVED build directory..."

mkdir -p "${AVED_HW_DIR}/build/prj.runs/impl_1"

# BIF expects PDI at ./build/prj.runs/impl_1/top_wrapper.pdi
cp "${OUTPUT_DIR}/${TOP}.pdi" \
   "${AVED_HW_DIR}/build/prj.runs/impl_1/top_wrapper.pdi"

# build_all.sh uses XSA at ./build/${DESIGN}.xsa
cp "${OUTPUT_DIR}/${TOP}.xsa" \
   "${AVED_HW_DIR}/build/${AVED_BASE_DESIGN}.xsa"

echo "Staged: ${OUTPUT_DIR}/${TOP}.pdi -> ${AVED_HW_DIR}/build/prj.runs/impl_1/top_wrapper.pdi"
echo "Staged: ${OUTPUT_DIR}/${TOP}.xsa -> ${AVED_HW_DIR}/build/${AVED_BASE_DESIGN}.xsa"

# ============================================================
# Generate modified build script (remove # Step HW section)
# ============================================================
banner "Generating build_all_no_hw.sh..."

NO_HW_SCRIPT="${AVED_HW_DIR}/build_all_no_hw.sh"

# Remove lines from '# Step HW' up to (but not including) '# Step FW'
sed '/^# Step HW$/,/^# Step FW$/{/^# Step FW$/!d}' "${BUILD_ALL}" \
    > "${NO_HW_SCRIPT}"
chmod +x "${NO_HW_SCRIPT}"

echo "Generated: ${NO_HW_SCRIPT}"

# ============================================================
# Locate ARM R5 cross-compiler and add it to PATH
# ============================================================
# The armr5-none-eabi toolchain ships with Vitis (not Vivado).
# Try XILINX_VITIS first, then fall back to glob detection.
ARMR5_BIN=""
if [[ -n "${XILINX_VITIS:-}" ]]; then
    ARMR5_BIN="${XILINX_VITIS}/gnu/armr5/lin/gcc-arm-none-eabi/bin"
fi
if [[ -z "${ARMR5_BIN}" || ! -d "${ARMR5_BIN}" ]]; then
    ARMR5_BIN=$(ls -d /tools/Xilinx/*/gnu/armr5/lin/gcc-arm-none-eabi/bin 2>/dev/null | sort -V | tail -1)
fi
[[ -n "${ARMR5_BIN}" && -d "${ARMR5_BIN}" ]] \
    || die "ARM R5 toolchain not found. Set XILINX_VITIS or install Vitis under /tools/Xilinx."
echo "Using ARM R5 toolchain: ${ARMR5_BIN}"
export PATH="${ARMR5_BIN}:${PATH}"

# ============================================================
# Run modified script from the AVED HW directory
# ============================================================
banner "Running firmware build and PDI generation..."

cd "${AVED_HW_DIR}"
./build_all_no_hw.sh

# ============================================================
# Copy results back to the output directory
# ============================================================
banner "Copying results to output directory..."

# Final PDI lands in $AVED_HW_DIR (CWD when fpt_pdi_gen.py ran with --output ${DESIGN}.pdi)
cp "${AVED_HW_DIR}/${AVED_BASE_DESIGN}.pdi" \
   "${OUTPUT_DIR}/${TOP}_app.pdi"

cp "${AVED_HW_DIR}/build/${AVED_BASE_DESIGN}_nofpt.pdi" \
   "${OUTPUT_DIR}/${TOP}_nofpt.pdi"

echo "============================================================"
echo "PDI generation complete."
echo "  Final PDI   : ${OUTPUT_DIR}/${TOP}_app.pdi"
echo "  No-FPT PDI  : ${OUTPUT_DIR}/${TOP}_nofpt.pdi"
echo "============================================================"
