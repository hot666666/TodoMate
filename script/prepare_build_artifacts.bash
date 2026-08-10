#!/bin/bash

set -euo pipefail

usage() {
  echo "usage: $0 validate-directory|prepare-directory|prepare-managed-directory|prepare-result|finalize-result PATH" >&2
  exit 2
}

validate_path() {
  local path="$1"
  local label="$2"
  local parent

  if [[ -z "${path}" ]]; then
    echo "error: ${label} path must not be empty" >&2
    exit 2
  fi

  if [[ "${path}" == *$'\n'* || "${path}" == *$'\r'* ]]; then
    echo "error: ${label} path must not contain a newline" >&2
    exit 2
  fi

  if [[ "${path}" == //* ]]; then
    echo "error: ${label} path must not start with repeated '/': ${path}" >&2
    exit 2
  fi

  if [[ "${path}" == */ ]]; then
    echo "error: ${label} path must not end with '/': ${path}" >&2
    exit 2
  fi

  case "/${path}/" in
    *"/../"* | *"/./"*)
      echo "error: ${label} path must not contain '.' or '..' components: ${path}" >&2
      exit 2
      ;;
  esac

  if [[ "${path}" == "/" || "${path}" == "." || "${path}" == ".." ]]; then
    echo "error: refusing unsafe ${label} path: ${path}" >&2
    exit 2
  fi

  parent="$(dirname -- "${path}")"
  if [[ -z "${parent}" || "${parent}" == "/" || "${parent}" == "//" ]]; then
    echo "error: refusing ${label} path directly below the filesystem root: ${path}" >&2
    exit 2
  fi
}

if [[ "$#" -ne 2 ]]; then
  usage
fi

readonly COMMAND="$1"
readonly ARTIFACT_PATH="$2"

case "${COMMAND}" in
  validate-directory)
    validate_path "${ARTIFACT_PATH}" "artifact directory"
    ;;

  prepare-directory)
    validate_path "${ARTIFACT_PATH}" "artifact directory"
    mkdir -p -- "${ARTIFACT_PATH}"
    ;;

  prepare-managed-directory)
    validate_path "${ARTIFACT_PATH}" "managed artifact directory"
    if [[ -L "${ARTIFACT_PATH}" ]]; then
      echo "error: managed artifact directory must not be a symbolic link: ${ARTIFACT_PATH}" >&2
      exit 2
    fi

    managed_marker="${ARTIFACT_PATH}/.todomate-managed-output"
    readonly managed_marker
    if [[ -e "${ARTIFACT_PATH}" && ! -d "${ARTIFACT_PATH}" ]]; then
      echo "error: managed artifact path is not a directory: ${ARTIFACT_PATH}" >&2
      exit 2
    fi

    if [[ -L "${managed_marker}" ]]; then
      echo "error: managed artifact marker must not be a symbolic link: ${managed_marker}" >&2
      exit 2
    fi

    if [[ -d "${ARTIFACT_PATH}" && ! -f "${managed_marker}" ]]; then
      first_existing_entry="$(find "${ARTIFACT_PATH}" -mindepth 1 -maxdepth 1 -print -quit)"
      readonly first_existing_entry
      if [[ -n "${first_existing_entry}" ]]; then
        echo "error: refusing non-empty unowned artifact directory: ${ARTIFACT_PATH}" >&2
        exit 2
      fi
    fi

    mkdir -p -- "${ARTIFACT_PATH}"
    touch -- "${managed_marker}"
    ;;

  prepare-result)
    validate_path "${ARTIFACT_PATH}" "result bundle"
    if [[ "${ARTIFACT_PATH}" != *.xcresult ]]; then
      echo "error: result bundle path must end in .xcresult: ${ARTIFACT_PATH}" >&2
      exit 2
    fi

    result_parent="$(dirname -- "${ARTIFACT_PATH}")"
    readonly result_parent
    previous_result="${ARTIFACT_PATH%.xcresult}.previous.xcresult"
    readonly previous_result
    completion_marker="${ARTIFACT_PATH}.todomate-complete"
    readonly completion_marker
    in_progress_marker="${ARTIFACT_PATH}.todomate-in-progress"
    readonly in_progress_marker
    previous_marker="${previous_result}.todomate-complete"
    readonly previous_marker

    mkdir -p -- "${result_parent}"

    if [[ -e "${ARTIFACT_PATH}" ]]; then
      if [[ -f "${completion_marker}" && ! -f "${in_progress_marker}" ]]; then
        rm -rf -- "${previous_result}"
        rm -f -- "${previous_marker}"
        mv -- "${ARTIFACT_PATH}" "${previous_result}"
        mv -- "${completion_marker}" "${previous_marker}"
      else
        rm -rf -- "${ARTIFACT_PATH}"
        rm -f -- "${completion_marker}" "${in_progress_marker}"
      fi
    fi

    rm -f -- "${completion_marker}" "${in_progress_marker}"
    touch -- "${in_progress_marker}"
    ;;

  finalize-result)
    validate_path "${ARTIFACT_PATH}" "result bundle"
    if [[ "${ARTIFACT_PATH}" != *.xcresult ]]; then
      echo "error: result bundle path must end in .xcresult: ${ARTIFACT_PATH}" >&2
      exit 2
    fi

    completion_marker="${ARTIFACT_PATH}.todomate-complete"
    readonly completion_marker
    in_progress_marker="${ARTIFACT_PATH}.todomate-in-progress"
    readonly in_progress_marker

    if [[ ! -d "${ARTIFACT_PATH}" || ! -f "${ARTIFACT_PATH}/Info.plist" ]]; then
      echo "error: xcodebuild did not produce an initialized result bundle: ${ARTIFACT_PATH}" >&2
      exit 2
    fi
    rm -f -- "${in_progress_marker}"
    touch -- "${completion_marker}"
    ;;

  *)
    usage
    ;;
esac
