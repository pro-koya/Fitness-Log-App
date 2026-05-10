#!/bin/sh

# Collect or generate dSYM files for embedded Flutter/Pod frameworks.
# This script should be run as a build phase after "[CP] Embed Pods Frameworks".

# Only run for Archive builds
if [ "${CONFIGURATION}" = "Release" ] || [ "${CONFIGURATION}" = "Profile" ]; then
  if [ "${ACTION}" = "install" ]; then
    echo "Collecting embedded framework dSYMs..."

    DSYMS_DIR="${DWARF_DSYM_FOLDER_PATH}"
    FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
    mkdir -p "${DSYMS_DIR}"

    if [ -d "${FRAMEWORKS_DIR}" ]; then
      find "${FRAMEWORKS_DIR}" -maxdepth 1 -name "*.framework" -type d | while read -r framework_path; do
        framework_name=$(basename "${framework_path}" .framework)
        framework_binary="${framework_path}/${framework_name}"
        dsym_dest="${DSYMS_DIR}/${framework_name}.framework.dSYM"
        dsym_source="${framework_path}/../${framework_name}.framework.dSYM"

        if [ -d "${dsym_dest}" ]; then
          echo "dSYM already present: ${framework_name}.framework.dSYM"
        elif [ -d "${dsym_source}" ]; then
          echo "Copying dSYM: ${framework_name}.framework.dSYM"
          cp -R "${dsym_source}" "${dsym_dest}"
        elif [ -f "${framework_binary}" ]; then
          echo "Generating dSYM: ${framework_name}.framework.dSYM"
          dsymutil "${framework_binary}" -o "${dsym_dest}" || true
        fi
      done
    fi

    echo "dSYM collection complete."
  fi
fi
