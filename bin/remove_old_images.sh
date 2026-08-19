#!/usr/bin/env bash
set -Eeu

# Keeps :latest, which local tooling refers to, and this commit's tag, which
# names the build just made. Every older tag goes, and an earlier build whose
# last tag was one of those goes with it.
function remove_old_images()
{
  echo Removing old images
  local -r name="$(image_name)"
  # grep exits non-zero when the machine holds no image of this name, eg one
  # whose images have just been cleared, so an empty list must not end the build.
  local tagged_name
  for tagged_name in $(docker image ls --format '{{.Repository}}:{{.Tag}}' | grep "^${name}:" || true)
  do
    if [ "${tagged_name}" != "${name}:latest" ] \
    && [ "${tagged_name}" != "${name}:$(git_commit_tag)" ]; then
      # Removing by name:tag untags, so this succeeds even while a container
      # references the image, leaving it dangling until that container goes.
      # The guard is for a genuine daemon error: report it rather than abort the
      # whole build under set -Eeu.
      docker image rm --force "${tagged_name}" || echo "  ${tagged_name} not removed"
    fi
  done
}
