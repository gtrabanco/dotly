#!/usr/bin/env bash
#shellcheck disable=SC2034

# TODO Add variables to export and document the variables below.

# Maybe this should be in a different file or provide them in exports.sh
# .Sloth will be always a submodule so we need that configuration for update
SLOTH_SUBMODULES_DIRECTORY="$(realpath -qms --relative-to="$DOTFILES_PATH" "${SLOTH_PATH:-${DOTLY_PATH:-}}")"
SLOTH_SUBMODULES_DIRECTORY="${SLOTH_SUBMODULES_DIRECTORY:-modules/sloth}"
SLOTH_GITMODULES_URL="$(git::get_submodule_property "${DOTFILES_PATH:-}/.gitmodules" "$SLOTH_SUBMODULES_DIRECTORY" "url")"
SLOTH_GITMODULES_URL="${SLOTH_GITMODULES_URL:-$SLOTH_DEFAULT_GIT_HTTP_URL}"
SLOTH_GITMODULES_BRANCH="$(git::get_submodule_property "${DOTFILES_PATH:-}/.gitmodules" "$SLOTH_SUBMODULES_DIRECTORY" "branch")"
SLOTH_GITMODULES_BRANCH="${SLOTH_GITMODULES_BRANCH:-master}"

# Defaults values if no values are provided
[[ -z "${SLOTH_DEFAULT_GIT_HTTP_URL:-}" ]] && readonly SLOTH_DEFAULT_GIT_HTTP_URL="https://github.com/gtrabanco/sloth"
[[ -z "${SLOTH_DEFAULT_GIT_SSH_URL:-}" ]] && readonly SLOTH_DEFAULT_GIT_SSH_URL="git@github.com:gtrabanco/sloth.git"
[[ -z "${SLOTH_DEFAULT_REMOTE:-}" ]] && readonly SLOTH_DEFAULT_REMOTE="origin"
# SLOTH_DEFAULT_BRANCH is not the same as SLOTH_GITMODULES_BRANCH
# SLOTH_GITMODULES_BRANCH is the branch we want to use if we are using always latest version
# SLOTH_GITMODULES_BRANCH is the HEAD branch of remote repository were Pull Request are merged
[[ -z "${SLOTH_DEFAULT_BRANCH:-}" ]] && readonly SLOTH_DEFAULT_BRANCH="master"

SLOTH_DEFAULT_URL=${SLOTH_GITMODULES_URL:-$SLOTH_DEFAULT_GIT_HTTP_URL}

#
# .Sloth update strategy Configuration
#
export SLOTH_UPDATE_VERSION="${SLOTH_UPDATE_VERSION:-latest}" # stable, minor, latest, or any specified version
export SLOTH_ENV="${SLOTH_ENV:-production}"                   # production or development. If you define development
# all updates must be manually or when you have a clean working directory and
# pushed your commits.
# This is done to avoid conflicts and lost changes.
# For development all other configuration will be ignored and every time it
# can be updated you will get the latest version.

if [[ -z "${SLOTH_UPDATE_GIT_ARGS[*]:-}" ]]; then
  readonly SLOTH_UPDATE_GIT_ARGS=(
    -C "${SLOTH_PATH:-${DOTLY_PATH:-}}"
  )
fi

#;
# update::sloth_repository_set_ready()
# Default repository initilisation and first fetch if is not ready to have updates
# @return void
#"
update::sloth_repository_set_ready() {
  local remote

  if ! git::check_remote_exists "${SLOTH_DEFAULT_REMOTE:-origin}" "${SLOTH_UPDATE_GIT_ARGS[@]}" && [[ -n "${url:-}" ]]; then
    git::init_repository_if_necessary "${SLOTH_DEFAULT_URL:-${SLOTH_DEFAULT_GIT_HTTP_URL:-https://github.com/gtrabanco/sloth}}" "${SLOTH_DEFAULT_REMOTE:-origin}" "${SLOTH_DEFAULT_BRANCH:-master}" "${SLOTH_UPDATE_GIT_ARGS[@]}"
  fi
}

#;
# update::get_current_version()
# Get which one is your current version or latest downloaded version
# @return string|void
#"
update::get_current_version() {
  git::git "${SLOTH_UPDATE_GIT_ARGS[@]}" describe --tags --abbrev=0 2> /dev/null
}

#;
# update::get_latest_version()
# Get the latest stable version available
# @return string
#"
update::get_latest_version() {
  local latest_version
  latest_version="$(git::git "${SLOTH_UPDATE_GIT_ARGS[@]}" ls-remote --tags "${SLOTH_DEFAULT_URL:-${SLOTH_DEFAULT_GIT_HTTP_URL:-https://github.com/gtrabanco/sloth}}" | cut -f2 | sed 's/\^{}//g' | sort -Vru | sed 's#refs/tags/v##g' | head -n1)"
}

#;
# update::local_sloth_repository_can_be_updated()
# Check if we should update based on the configured SLOTH_UPDATE_VERSION and SLOTH_ENV. This takes care in production about pending commits and clean working directory as described in the comments for SLOTH_DEV
# @return boolean
#"
update::local_sloth_repository_can_be_updated() {
  local IS_WORKING_DIRECTORY_CLEAN HAS_UNPUSHED_COMMITS
  ! git::check_unpushed_commits "$SLOTH_DEFAULT_REMOTE" "$head_branch" "${SLOTH_UPDATE_GIT_ARGS[@]}" || ! git::is_clean "${SLOTH_DEFAULT_REMOTE:-origin}" "${SLOTH_DEFAULT_BRANCH:-master}" "${SLOTH_UPDATE_GIT_ARGS[@]}"
}

#;
# update::sloth_update_repositry()
# Gracefully update sloth repository to the latest version. Use defined vars in top as default values if no one is provided. It will use \${SLOTH_UPDATE_GIT_ARGS[@]} as default arguments for git.
# @param string remote
# @param string url Default url for the remote to be configured if not exists
# @param string default_branch Default branch for the remote to be configured if not exists
# @param bool force_update Default false. If true it will force update even if there are pending commits
# @return boolean
#"
update::sloth_update_repository() {
  local remote url default_branch head_branch
  local -r remote="${1:-${SLOTH_DEFAULT_REMOTE:-origin}}"
  local -r remote="${1:-${SLOTH_DEFAULT_REMOTE:-origin}}"
  url="${2:-${SLOTH_GITMODULES_URL:-${SLOTH_DEFAULT_GIT_HTTP_URL:-}}}"
  default_branch="${remote}/${3:-${SLOTH_DEFAULT_BRANCH:-master}}"

  if ! git::check_remote_exists "$remote" "${SLOTH_UPDATE_GIT_ARGS[@]}" && [[ -n "${url:-}" ]]; then
    git::init_repository_if_necessary "$url" "$remote" "${SLOTH_DEFAULT_BRANCH:-master}" "${SLOTH_UPDATE_GIT_ARGS[@]}"
  fi
  ! git::check_remote_exists "$remote" "${SLOTH_UPDATE_GIT_ARGS[@]}" && output::error "Remote \`${remote}\` does not exists" && return 1

  # Automatic convert windows git crlf to lf
  git::git "${SLOTH_UPDATE_GIT_ARGS[@]}" config --bool core.autcrl false

  # Get remote HEAD branch
  head_branch="$(git::get_remote_head_upstream_branch "$remote" "${SLOTH_UPDATE_GIT_ARGS[@]}")"
  if [[ -z "$head_branch" ]]; then
    git::set_remote_head_upstream_branch "$remote" "$default_branch" "${SLOTH_UPDATE_GIT_ARGS[@]}"
    head_branch="$(git::get_remote_head_upstream_branch "$remote" "${SLOTH_UPDATE_GIT_ARGS[@]}")"

    [[ -z "$head_branch" ]] && output::error "Remote \`${remote}\` does not have a default branch and \`${default_branch}\` could not be set" && return 1
  fi

  # Check if current branch has something to push
  if ! ${UPDATE_REPOSITORY_FORCE_UPDATE:-false}; then
    git::check_unpushed_commits "$remote" "$head_branch" "${SLOTH_UPDATE_GIT_ARGS[@]}" &&
      output::write "You have commits to be pushed, update can not be done until they have been pushed" &&
      return 1
  fi

  # Check if working directory is not clean
  if ! ${UPDATE_REPOSITORY_FORCE_UPDATE:-false}; then
    ! git::is_clean "$remote" "$head_branch" "${SLOTH_UPDATE_GIT_ARGS[@]}" &&
      output::write "Working directory is not clean, update can not be done until you have commited and pushed your changes" &&
      return 1
  fi

  # Force unshallow by the way...
  git fetch --unshallow &> /dev/null || true

  git::pull_branch "$remote" "$head_branch" "${SLOTH_UPDATE_GIT_ARGS[@]}" 1>&2 && output::solution "Repository has been updated" || return 1
}
