#!/usr/bin/env bash
# Sourced from a component's build.sh after changing to its own directory.
scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$scripts_dir/../versions.env"

build_images() {
    local mode=$1 arch=$2 version=$3 dockerfile=$4
    local check_defaults=0
    shift 4
    case "$mode" in
        --publish)
            : "${CNB_DOCKER_REGISTRY:?}" "${CNB_REPO_SLUG_LOWERCASE:?}" "${TencentCloud_REGISTRY:?}" "${REGISTRY_ORG:?}"
            check_defaults=1
            ;;
        --local) ;;
        *) echo "Usage: bash build.sh [--local|--publish]" >&2; return 2 ;;
    esac

    local name context ref bindings binding remote cnb tcr
    local -a images=() options=()
    while (( $# > 0 )); do
        name=$1
        context=$2
        shift 2
        ref="$name:$version"
        images+=("$ref")
        bindings=$(awk -v mode=args -v check_defaults="$check_defaults" \
            -f "$scripts_dir/version-args.awk" "$context/$dockerfile") || return 1
        options=()
        while IFS= read -r binding; do
            options+=(--build-arg "$binding")
        done <<< "$bindings"
        if ! docker build --platform "linux/$arch" --pull --no-cache -t "$ref" \
                -f "$context/$dockerfile" "${options[@]}" "$context"; then
            echo "$ref 镜像构建失败" >&2
            if [[ $mode == --publish ]]; then
                echo "$name 镜像构建失败" >> /tmp/CUSTOM_ENV_RESULT_INFO
            fi
            return 1
        fi
    done

    if [[ $mode == --publish ]]; then
        for ref in "${images[@]}"; do
            cnb="$CNB_DOCKER_REGISTRY/$CNB_REPO_SLUG_LOWERCASE/$ref"
            tcr="$TencentCloud_REGISTRY/$REGISTRY_ORG/$ref"
            for remote in "$cnb" "$tcr"; do
                docker tag "$ref" "$remote"
                skopeo copy --insecure-policy "docker-daemon:$remote" "docker://$remote"
            done
            echo "$tcr" >> /tmp/CUSTOM_ENV_RESULT_INFO
        done
    fi
}
