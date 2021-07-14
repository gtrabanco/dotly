#!/usr/bin/env bash
export PACKAGE_MANAGERS_SRC=(
  "${SLOTH_PATH:-$DOTLY_PATH}/scripts/package/src/package_managers"
  "${DOTFILES_PATH:-}/package_managers"
  "${PACKAGE_MANAGERS_SRC[@]:-}"
)

if [[ -z "${SLOTH_PACKAGE_MANAGERS_PRECEDENCE:-}" ]]; then
  if platform::is_macos; then
    export SLOTH_PACKAGE_MANAGERS_PRECEDENCE=(
      brew cargo pip volta npm mas
    )
  else
    export SLOTH_PACKAGE_MANAGERS_PRECEDENCE=(
      apt snap brew dnf pacman yum cargo pip gem volta npm
    )
  fi
fi

#;
# package::manager_exists()
# Check if a given package manager exists in PACKAGE_MANAGERS_SRC
# @param string package_manager
# @return string|void Full path to package manager or nothing
#"
package::manager_exists() {
  local package_manager_src
  local -r package_manager="${1:-}"
  for package_manager_src in "${PACKAGE_MANAGERS_SRC[@]}"; do
    [[ -f "${package_manager_src}/${package_manager}.sh" ]] &&
      head -n 1 "${package_manager_src}/${package_manager}.sh" | grep -q "^#\!/" &&
      echo "${package_manager_src}/${package_manager}.sh" &&
      return
  done
}

#;
# package::load_manager()
# Load a package manager library if exists, if not, exit the script with a critical warning. Recommended to use first package::manager_exists() if is not critical
# @param string package_manager
# @return void
#"
package::load_manager() {
  local package_manager_file_path
  local -r package_manager="${1:-}"

  package_manager_file_path="$(package::manager_exists "$package_manager")"

  if [[ -n "$package_manager_file_path" ]]; then
    dot::load_library "$package_manager_file_path"
  else
    output::error "🚨 Package Manager \`$package_manager\` does not exists"
    exit 4
  fi
}

#;
# package::get_available_package_managers()
# Output a full list of available package managers
#"
package::get_available_package_managers() {
  local package_manager_src package_manager
  find "${PACKAGE_MANAGERS_SRC[@]}" -maxdepth 1 -mindepth 1 -print0 2> /dev/null | xargs -0 -I _ echo _ | while read -r package_manager_src; do
    # Get package manager name
    #shellcheck disable=SC2030
    package_manager="$(basename "$package_manager_src")"
    package_manager="${package_manager%%.sh}"

    # Check if it is a valid package manager
    [[ -z "$(package::manager_exists "$package_manager")" ]] && continue

    # Load package manager
    package::load_manager "$package_manager"

    # Check if package manager is available
    if command -v "${package_manager}::is_available" &> /dev/null && "${package_manager}::is_available"; then
      echo "$package_manager"
    fi
  done
}

#;
# package::manager_preferred()
# Get the first avaible of the preferred package managers
# @return string package manager
#"
package::manager_preferred() {
  local all_available_pkgmgrs

  readarray -t all_available_pkgmgrs < <(package::get_available_package_managers)
  eval "$(array::uniq_unordered "${SLOTH_PACKAGE_MANAGERS_PRECEDENCE[@]}" "${all_available_pkgmgrs[@]}")"

  if [[ ${#uniq_values[@]} -gt 0 ]]; then
    echo "${uniq_values[0]}"
  fi
}

#;
# package::command_exists()
# Execute if a command (function) is defined for a given package manager
# @param string package_manager
# @param string command The function to be check
# @return boolean
#"
package::command_exists() {
  local -r package_manager="${1:-}"
  local -r command="${2:-}"

  if [[ "$package_manager" == "none" ]] ||
    [[ -z "$(package::manager_exists "$package_manager")" ]]; then
    return 1
  fi

  package::load_manager "$package_manager"

  # If function does not exists for the package manager it will return 0 (true) always
  if declare -F "${package_manager}::${command}" &> /dev/null; then
    return
  fi

  return 1
}

#;
# package::command()
# Execute if exists a function for package_manager (example: execute install command for a package manager if that function is defined for the given package manager). If execute install, the output is send also to the log.
# @param string package_manager
# @param string command The function to be executed
# @param array args Arguments for command
# @return void
#"
package::command() {
  local -r package_manager="${1:-}"
  local -r command="${2:-}"
  local -r args=("${@:3}")

  # If function does not exists for the package manager it will return 0 (true) always
  if package::command_exists "$package_manager" "${command}"; then
    if [[ "$command" == "install" ]]; then
      "${package_manager}::${command}" "${args[@]}" | log::file "Trying to install ${args[*]} using $package_manager" || return
    else
      "${package_manager}::${command}" "${args[@]}"
    fi
  fi
}

#;
# package::managers_self_update()
# Update packages manager list of packages (no packages). Should not be a upgrade of all apps
# @param string package_manager If this value is empty update all available package managers
# @return void
#"
package::manager_self_update() {
  local package_manager="${1:-}"

  if [[ -n "$package_manager" ]]; then
    package::command_exists "$package_manager" self_update && package::command "$package_manager" self_update
  else
    for package_manager in $(package::get_available_package_managers); do
      [[ -n "$package_manager" ]] && package::manager_self_update "$package_manager"
    done
  fi
}

#;
# package::is_installed()
# Check if a package is installed with a recipe or any of the available package managers. It does not check if a binary package_name is available
# @param string package_name
# @return boolean
#"
package::is_installed() {
  local package_manager
  local -r package_name="${1:-}"
  [[ -z "$package_name" ]] && return 1

  registry::is_installed "$package_name" && return

  for package_manager in $(package::get_available_package_managers); do
    if package::command_exists "$package_manager" "is_installed"; then
      package::command "$package_manager" is_installed "$package_name" && return
    fi
  done

  return 1
}

#;
# package::_install()
# "Private" function for package::install that do the repetive task of installing a package
# @param string package_manager
# @param string package
# @return boolean
#"
package::_install() {
  local package_manager package
  package_manager="${1:-}"
  package="${2:-}"

  [[ -z "$package_manager" || -z "$package" ]] && return 1

  if
    ! package::command_exists "$package_manager" "package_exists" &&
      package::command_exists "$package_manager" "is_installed" &&
      package::command_exists "$package_manager" "is_available" &&
      package::command_exists "$package_manager" "install" &&
      package::command "$package_manager" "is_available" &&
      package::command "$package_manager" "install" "$package"
  then

    if package::command "$package_manager" "is_installed" "$package"; then
      return
    fi

  elif
    package::command_exists "$package_manager" "is_available" &&
      package::command_exists "$package_manager" "install" &&
      package::command "$package_manager" "is_available" &&
      package::command "$package_manager" "package_exists" "$package"
  then

    package::command "$package_manager" "install" "$package"
    return

  fi

  return 1
}

#;
# package::install()
# Try to install with any available package manager, but if you provided a package manager (second param) it will only try to use that package manager
# @param string package Package to install
# @param string package_manager Force to use only package manager if define this param
# @return boolen
#"
package::install() {
  local all_available_pkgmgrs uniq_values package_manager package
  [[ -z "${1:-}" ]] && return 1
  package="$1"

  if [[ -n "${2:-}" ]]; then
    package_manager="$2"
    package::_install "$package_manager" "$package"
    return $?
  else
    if platform::command_exists readarray; then
      readarray -t all_available_pkgmgrs < <(package::get_available_package_managers)
    else
      #shellcheck disable=SC2207
      all_available_pkgmgrs=($(package::get_available_package_managers))
    fi
    eval "$(array::uniq_unordered "${SLOTH_PACKAGE_MANAGERS_PRECEDENCE[@]}" "${all_available_pkgmgrs[@]}")"

    # Try to install from package managers precedence
    for package_manager in "${uniq_values[@]}"; do
      if
        [[ -n "$(package::manager_exists "$package_manager")" ]] &&
          package::load_manager "$package_manager" &&
          package::_install "$package_manager" "$package"
      then
        return
      fi
    done

    return 1
  fi
}

#;
# package::install_recipe_first()
# Try to install package with recipe and if not use package::install()
# @param string package_name
# @param string package_manager Only used if there is no recipe
# @return boolen
#"
package::install_recipe_first() {
  local -r package_name="${1:-}"
  local -r package_manager="${2:-}"
  if [[ -n "$(registry::recipe_exists "$package_name")" ]]; then
    registry::install "$package_name" && registry::is_installed "$package_name"
  else
    package::install "$package_name" "$package_manager"
  fi
}

#;
# package::which_file()
# Askt to user for a file in given files_path and output it. Used to get the file to import packages
# @param string files_path
# @param string header For fzf
# @return string|void
#"
package::which_file() {
  local files_path header answer files
  [[ $# -lt 3 ]] && return
  files_path="$(realpath -sm "$1")"
  header="$2"

  #shellcheck disable=SC2207
  files=($(find "$files_path" -not -iname ".*" -maxdepth 1 -type f,l -print0 2> /dev/null | xargs -0 -I _ basename _ | sort -u))

  if [[ -d "$files_path" && ${#files[@]} -gt 0 ]]; then
    answer="$(printf "%s\n" "${files[@]}" | fzf -0 --filepath-word -d ',' --prompt "$(hostname -s) > " --header "$header" --preview "[[ -f $files_path/{} ]] && cat $files_path/{} || echo No import a file for this package manager")"
    [[ -f "$files_path/$answer" ]] && answer="$files_path/$answer" || answer=""
  fi
  echo "$answer"
}

#;
# package::command_dump_check()
# Used to check if package manager exists and create the subdir where the dump file will be placed
# @param string package_manager
# @param string file_path The directory where the dump file will be created
# @return void
#"
package::common_dump_check() {
  local -r package_manager="${1:-}"
  local -r file_path="${2:-}"

  if
    [[ -n "$package_manager" ]] &&
      [[ -n "$file_path" ]] &&
      [[ -n "$(package::manager_exists "$package_manager")" ]]
  then
    mkdir -p "$(dirname "$file_path")"
  fi
}

#;
# package::common_import_check()
# Check if the file exists for the given package manager
# @param string package_manager
# @param string file_path File to check if exists
# @return boolean
#"
package::common_import_check() {
  local package_manager file_path
  local -r package_manager="${1:-}"
  local -r file_path="${2:-}"

  [[ -n "$package_manager" ]] &&
    [[ -n "$file_path" ]] &&
    [[ -n "$(package::manager_exists "$package_manager")" ]] &&
    [[ -f "$file_path" ]]
}
