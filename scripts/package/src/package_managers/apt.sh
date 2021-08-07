#!/usr/bin/env bash

apt_title='@ APT'

apt::require_sudo_elevation() {
  return 0
}

apt::is_available() {
  platform::command_exists apt-get && platform::command_exists apt-cache && platform::command_exists dpkg
}

apt::install() {
  [[ $# -gt 0 ]] && apt::is_available && sudo apt-get -y install "$@"
}

apt::cleanup() {
  if platform::command_exists apt; then
    sudo apt clean
    sudo apt autoremove --purge
    sudo apt -f install
  fi
}

apt::uninstall() {
  sudo -v
  apt::is_available && sudo apt-get -y purge "$@"
  apt::cleanup
}

apt::is_installed() {
  #apt list -a "$@" | grep -q 'installed'
  [[ -n "${1:-}" ]] && apt::is_available && dpkg --list "$1" &> /dev/null
}

apt::package_exists() {
  [[ -n "${1:-}" ]] && apt::is_available && apt-cache show "$1" &> /dev/null
}

apt::outdated_list() {
  apt::is_available && apt-get -s dist-upgrade | awk '/^Inst/ {print $2}'
}

apt::update_apps() {
  local outdated_app app_old_version app_new_version app_info app_url description_start description_end description_lines
  if ! apt::is_available; then
    return 1
  fi

  apt::outdated_list | while read -r outdated_app; do
    app_old_version="$(apt-cache policy "$outdated_app" | grep 'Installed' | awk '{print $2}')"
    app_new_version="$(apt-cache policy "$outdated_app" | grep 'Candidate' | awk '{print $2}')"
    app_url="$(apt-cache show "$outdated_app" | grep 'Homepage' | awk '{print $2}')"
    description_start="$(apt-cache show "$outdated_app" | grep -n 'Description-en' | head -n 1 | awk '{print $1}')"
    description_end="$(apt-cache show "$outdated_app" | grep -n 'Description-md5' | head -n 1 | awk '{print $1}')"
    description_lines=$((description_end - description_start))
    description_end=$((description_end - 1))
    app_info="$(apt-cache show "$outdated_app" | head -n "$description_end" | tail -n "$description_lines" | sed 's/Description-en: //g' | xargs)"

    output::write "@ $outdated_app"
    output::write "├ $app_old_version -> $app_new_version"
    output::write "├ $app_info"
    output::write "└ $app_url"
    output::empty_line

    sudo apt-get --only-upgrade "$outdated_app" | log::file "Updating ${apt_title} app: $outdated_app"

    # Reset variables
    app_old_version=""
    app_new_version=""
    app_url=""
    app_info=""
    description_start=""
    description_end=""
    description_lines=""
  done
}

apt::self_update() {
  platform::command_exists sudo && platform::command_exists hwclock && sudo hwclock --hctosys
  apt::is_available && platform::command_exists sudo && sudo apt-get update | log::file "Updating ${apt_title}"
}

apt::update_all() {
  apt::self_update
  apt::update_apps
}

apt::dump() {
  APT_DUMP_FILE_PATH="${1:-$APT_DUMP_FILE_PATH}"

  if package::common_dump_check apt "$APT_DUMP_FILE_PATH"; then
    apt-mark showmanual | tee "$APT_DUMP_FILE_PATH" | log::file "Exporting ${apt_title} packages"

    return 0
  fi

  return 1
}

apt::import() {
  APT_DUMP_FILE_PATH="${1:-$APT_DUMP_FILE_PATH}"

  if package::common_import_check apt "$APT_DUMP_FILE_PATH"; then
    xargs sudo apt-get install -y < "$APT_DUMP_FILE_PATH" | log::file "Importing ${apt_title} packages"
  fi
}
