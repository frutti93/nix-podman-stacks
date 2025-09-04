{
  pkgs,
  lib,
  datDir,
  inputDir,
  outputDir,
}:
pkgs.writeShellApplication {
  name = "igir-romm-cleanup";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.nodejs
  ];
  text = ''
    datDirDefault=${lib.escapeShellArg (toString datDir)}
    inputDirDefault=${lib.escapeShellArg (toString inputDir)}
    outputDirDefault=${lib.escapeShellArg (toString outputDir)}

    datDir="$datDirDefault"
    inputDir="$inputDirDefault"
    outputDir="$outputDirDefault"
    copyRemaining=false
    groupMultiDisk=false
    skipCleanup=false

    usage() {
    cat >&2 <<EOF
    Usage: igir-romm-cleanup [options]

    Options:
      --dat-dir DIR         Path to DAT files (default: $datDirDefault)
      --input-dir DIR       Path to input ROMs (default: $inputDirDefault)
      --output-dir DIR      Path to output ROMs (default: $outputDirDefault)
      --copy-remaining      Also mirror unrecognized ROMs
      --group-multi-disk    Reorganize multi-disc games into single folders
      --skip-cleanup        Skip initial Igir cleanup (move/extract/test)
      -h, --help            Show this help
    EOF
    exit 1
    }

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --dat-dir) datDir="$2"; shift 2 ;;
        --input-dir) inputDir="$2"; shift 2 ;;
        --output-dir) outputDir="$2"; shift 2 ;;
        --copy-remaining) copyRemaining=true; shift ;;
        --group-multi-disk) groupMultiDisk=true; shift ;;
        --skip-cleanup) skipCleanup=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; usage ;;
      esac
    done

    mkdir -p "$outputDir"

    echo "Running Igir cleanup:"
    echo "  DAT dir:           $datDir"
    echo "  Input dir:         $inputDir"
    echo "  Output dir:        $outputDir"
    echo "  Copy remaining:    $copyRemaining"
    echo "  Group multi-disk:  $groupMultiDisk"
    echo "  Skip cleanup:      $skipCleanup"

    # Base Igir run (skip if requested)
    if [[ "$skipCleanup" == false ]]; then
      XDG_CACHE_HOME="$(mktemp -d)" \
      npm_config_yes=true \
      npx --silent -y igir@latest \
        move \
        extract \
        test \
        -d "$datDir" \
        -i "$inputDir/" \
        -o "$outputDir/{romm}/" \
        --input-checksum-quick false \
        --input-checksum-min CRC32 \
        --input-checksum-max SHA256 \
        --only-retail
    else
      echo "Skipping initial cleanup step."
    fi

    # Copy remaining items if requested
    if [[ "$copyRemaining" == true ]]; then
      echo "Mirroring remaining files into output while preserving structure…"
      XDG_CACHE_HOME="$(mktemp -d)" \
      npm_config_yes=true \
      npx --silent -y igir@latest \
        move \
        -i "$inputDir/" \
        -o "$outputDir/" \
        --dir-mirror
    fi

    # Group multi-disc games if requested
    if [[ "$groupMultiDisk" == true ]]; then
      echo "Reorganizing multi-disc games…"
      find "$outputDir" -type d -name "*Disc*" | while read -r dir; do
        game="$(echo "''${dir}" | sed -r 's/ \(Disc [0-9]+\)//')"
        mkdir -p "''${game}"
        mv "''${dir}"/* "''${game}/"
        rm -rf "''${dir}"
      done
    fi

    echo "Done."
  '';
}
