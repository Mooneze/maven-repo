#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"
: "${GITHUB_ACTOR:?GITHUB_ACTOR is required}"

MAVEN_CENTRAL="${MAVEN_CENTRAL:-https://repo1.maven.org/maven2}"
GITHUB_MAVEN="${GITHUB_MAVEN:-https://maven.pkg.github.com/Mooneze/maven-repo}"
NUGET_SOURCE="${NUGET_SOURCE:-https://nuget.pkg.github.com/Mooneze/index.json}"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

upload() {
    local file="$1" url="$2" code
    code="$(curl -sS -o "$work/resp" -w '%{http_code}' \
        -u "${GITHUB_ACTOR}:${GITHUB_TOKEN}" \
        --upload-file "$file" "$url")"
    echo "    $(basename "$file") -> HTTP $code"
    case "$code" in
        200|201|204) ;;
        409) echo "    already exists, skipping" ;;
        *)
            cat "$work/resp"
            return 1
            ;;
    esac
}

publish_maven() {
    local group_path="$1" artifact="$2" version="$3" lower_artifact="$4"
    local remote_dir="$group_path/$artifact/$version"
    local local_dir="$group_path/$lower_artifact/$version"
    local ext base

    echo "==> ${group_path//\//.}:${lower_artifact}:${version}"
    mkdir -p "$work/$local_dir"

    for ext in pom jar; do
        base="${lower_artifact}-${version}.${ext}"
        curl -fsSL --retry 5 --retry-delay 2 \
            "$MAVEN_CENTRAL/$remote_dir/${artifact}-${version}.${ext}" \
            -o "$work/$local_dir/$base"
    done

    # GitHub Packages 的 Maven 仓库不接受大写 artifactId。
    sed -i \
        -e "s|<artifactId>${artifact}</artifactId>|<artifactId>${lower_artifact}</artifactId>|g" \
        -e "s|<name>${artifact}</name>|<name>${lower_artifact}</name>|g" \
        "$work/$local_dir/${lower_artifact}-${version}.pom"

    # 把 POM 里的上游地址换成我们的镜像。
    case "$artifact" in
        HelloNBT)
            sed -i 's|https://github.com/HMCL-dev/HelloNBT|https://github.com/Mooneze/HelloNBT|g' \
                "$work/$local_dir/${lower_artifact}-${version}.pom"
            ;;
        HMCLauncher)
            sed -i 's|https://github.com/HMCL-dev/HMCLauncher|https://github.com/Mooneze/HMCLauncher|g' \
                "$work/$local_dir/${lower_artifact}-${version}.pom"
            ;;
        lwjgl-unsafe-agent)
            sed -i 's|https://github.com/Glavo/lwjgl-unsafe-agent|https://github.com/Mooneze/lwjgl-unsafe-agent|g' \
                "$work/$local_dir/${lower_artifact}-${version}.pom"
            ;;
        mesa-loader-windows)
            sed -i 's|https://github.com/Glavo/mesa-loader-windows|https://github.com/Mooneze/mesa-loader-windows|g' \
                "$work/$local_dir/${lower_artifact}-${version}.pom"
            ;;
    esac

    upload "$work/$local_dir/${lower_artifact}-${version}.pom" \
        "$GITHUB_MAVEN/$local_dir/${lower_artifact}-${version}.pom"
    upload "$work/$local_dir/${lower_artifact}-${version}.jar" \
        "$GITHUB_MAVEN/$local_dir/${lower_artifact}-${version}.jar"
}

publish_maven org/glavo HelloNBT 0.4.0 hellonbt
publish_maven org/glavo/hmcl HMCLauncher 3.7.0.1 hmclauncher
publish_maven org/glavo lwjgl-unsafe-agent 2.0 lwjgl-unsafe-agent
publish_maven org/glavo mesa-loader-windows 26.0.4 mesa-loader-windows

echo "==> nuget PlainToolkit.CngProtectedData:2.1.0"
curl -fsSL --retry 5 --retry-delay 2 \
    "https://api.nuget.org/v3-flatcontainer/plaintoolkit.cngprotecteddata/2.1.0/plaintoolkit.cngprotecteddata.2.1.0.nupkg" \
    -o "$work/PlainToolkit.CngProtectedData.2.1.0.nupkg"
dotnet nuget push "$work/PlainToolkit.CngProtectedData.2.1.0.nupkg" \
    --source "$NUGET_SOURCE" \
    --api-key "$GITHUB_TOKEN" \
    --skip-duplicate

# 尽量把包设为公开；失败也不影响发布（公开仓库通常已经继承 public）。
set +e
for package in hellonbt hmclauncher lwjgl-unsafe-agent mesa-loader-windows; do
    code="$(curl -sS -o "$work/vis-resp" -w '%{http_code}' -X PATCH \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/orgs/Mooneze/packages/maven/${package}" \
        -d '{"visibility":"public"}')"
    echo "==> visibility ${package}: HTTP ${code}"
done
code="$(curl -sS -o "$work/vis-resp" -w '%{http_code}' -X PATCH \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/orgs/Mooneze/packages/nuget/plaintoolkit.cngprotecteddata" \
    -d '{"visibility":"public"}')"
echo "==> visibility plaintoolkit.cngprotecteddata: HTTP ${code}"
set -e

echo "Done."
