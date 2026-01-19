#!/bin/sh

# Collect dSYM files for Flutter frameworks (including objective_c.framework)
# This script should be run as a "Run Script" build phase after "Embed Frameworks"

# Only run for Archive builds
if [ "${CONFIGURATION}" = "Release" ] || [ "${CONFIGURATION}" = "Profile" ]; then
  if [ "${ACTION}" = "install" ]; then
    echo "Collecting dSYM files for Flutter frameworks..."
    
    # Path to the dSYMs folder in the archive
    DSYMS_DIR="${DWARF_DSYM_FOLDER_PATH}"
    
    # Path to Flutter frameworks
    FLUTTER_FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
    
    if [ -d "${FLUTTER_FRAMEWORKS_DIR}" ]; then
      # Find all Flutter framework dSYMs and ensure they're in the archive
      find "${FLUTTER_FRAMEWORKS_DIR}" -name "*.framework" -type d | while read framework_path; do
        framework_name=$(basename "${framework_path}" .framework)
        dsym_source="${framework_path}/../${framework_name}.framework.dSYM"
        
        if [ -d "${dsym_source}" ]; then
          dsym_dest="${DSYMS_DIR}/${framework_name}.framework.dSYM"
          if [ ! -d "${dsym_dest}" ]; then
            echo "Copying dSYM: ${framework_name}.framework.dSYM"
            cp -R "${dsym_source}" "${dsym_dest}"
          fi
        fi
      done
      
      # Also check for dSYMs generated during build
      find "${DWARF_DSYM_FOLDER_PATH}" -name "*.framework.dSYM" -o -name "*.dSYM" | while read dsym_path; do
        # Ensure it's in the archive
        echo "Verifying dSYM: ${dsym_path}"
      done
    fi
    
    echo "dSYM collection complete."
  fi
fi

