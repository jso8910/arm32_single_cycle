#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="${ROOT_DIR}/cores"
TIMEOUT_SECONDS="${TEST_TIMEOUT:-90}"

if ! command -v iverilog >/dev/null 2>&1; then
    echo "error: iverilog was not found in PATH" >&2
    exit 2
fi

if ! command -v vvp >/dev/null 2>&1; then
    echo "error: vvp was not found in PATH" >&2
    exit 2
fi

if ! command -v timeout >/dev/null 2>&1; then
    echo "error: timeout was not found in PATH" >&2
    exit 2
fi

mapfile -t testbenches < <(
    find "${ROOT_DIR}" -maxdepth 1 -type f -name '*_tb.v' -print | sort
)

if ((${#testbenches[@]} == 0)); then
    echo "No *_tb.v files found in ${ROOT_DIR}" >&2
    exit 2
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

declare -a passed=()
declare -a failed=()
declare -a skipped=()

for testbench in "${testbenches[@]}"; do
    tb_filename="$(basename -- "${testbench}")"
    test_name="${tb_filename%_tb.v}"
    core_file="${CORE_DIR}/${test_name}.v"

    echo
    echo "===== ${test_name} ====="

    if [[ ! -f "${core_file}" ]]; then
        echo "SKIP: no corresponding core found at cores/${test_name}.v"
        skipped+=("${test_name}: missing core")
        continue
    fi

    tb_module="$(
        sed -nE 's/^[[:space:]]*module[[:space:]]+([[:alnum:]_$]+).*/\1/p' \
            "${testbench}" | head -n 1
    )"
    core_module="$(
        sed -nE 's/^[[:space:]]*module[[:space:]]+([[:alnum:]_$]+).*/\1/p' \
            "${core_file}" | head -n 1
    )"

    if [[ -z "${tb_module}" ]]; then
        echo "FAIL: could not identify the testbench module in ${tb_filename}"
        failed+=("${test_name}: testbench module not found")
        continue
    fi

    if [[ -z "${core_module}" ]]; then
        echo "FAIL: could not identify the core module in cores/${test_name}.v"
        failed+=("${test_name}: core module not found")
        continue
    fi

    echo "Testbench: ${tb_filename} (${tb_module})"
    echo "Core:      cores/${test_name}.v (${core_module})"

    executable="${tmp_dir}/${test_name}.out"
    log="${tmp_dir}/${test_name}.log"

    compile_sources=()
    while IFS= read -r source; do
        compile_sources+=("${source}")
    done < <(find "${ROOT_DIR}" -maxdepth 1 -type f -name '*.v' -print | sort)

    if ! iverilog \
        -I "${ROOT_DIR}" \
        "-DARM32_CORE_IMPL=${core_module}" \
        -o "${executable}" \
        "${compile_sources[@]}" \
        "${core_file}" \
        -s "${tb_module}"; then
        echo "FAIL: compilation failed"
        failed+=("${test_name}: compilation failed")
        continue
    fi

    (
        cd "${ROOT_DIR}" || exit 1
        timeout "${TIMEOUT_SECONDS}s" vvp "${executable}"
    ) 2>&1 | tee "${log}"
    simulation_status=${PIPESTATUS[0]}

    if ((simulation_status == 124)); then
        echo "FAIL: timed out after ${TIMEOUT_SECONDS} seconds"
        failed+=("${test_name}: timeout")
    elif ((simulation_status != 0)); then
        echo "FAIL: simulation exited with status ${simulation_status}"
        failed+=("${test_name}: simulation status ${simulation_status}")
    elif grep -Eq \
        '^\[FAIL\]|Test failed|completed with [1-9][0-9]* failure' \
        "${log}"; then
        echo "FAIL: testbench reported a failure"
        failed+=("${test_name}: testbench failure")
    else
        echo "PASS"
        passed+=("${test_name}")
    fi
done

echo
echo "===== Summary ====="
printf 'Passed:  %d\n' "${#passed[@]}"
printf 'Failed:  %d\n' "${#failed[@]}"
printf 'Skipped: %d\n' "${#skipped[@]}"

if ((${#passed[@]} > 0)); then
    printf '  PASS  %s\n' "${passed[@]}"
fi

if ((${#failed[@]} > 0)); then
    printf '  FAIL  %s\n' "${failed[@]}"
fi

if ((${#skipped[@]} > 0)); then
    printf '  SKIP  %s\n' "${skipped[@]}"
fi

if ((${#failed[@]} > 0 || ${#skipped[@]} > 0)); then
    exit 1
fi
