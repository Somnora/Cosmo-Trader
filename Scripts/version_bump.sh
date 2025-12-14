#!/bin/bash

# version_bump.sh
# Cosmo Trader
#
# Semantic versioning script for major/minor/patch updates.
# Updates Xcode project version and optionally creates git tags.
#
# USAGE:
# ------
# ./Scripts/version_bump.sh patch      # 1.0.0 → 1.0.1
# ./Scripts/version_bump.sh minor      # 1.0.0 → 1.1.0
# ./Scripts/version_bump.sh major      # 1.0.0 → 2.0.0
# ./Scripts/version_bump.sh set 2.0.0  # Set specific version
#
# OPTIONS:
# --------
# --no-tag          Skip git tag creation
# --no-commit       Skip git commit
# --push            Push tags to remote after creation
# --dry-run         Show what would be done without making changes

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
PBXPROJ_PATH="${PROJECT_DIR}/Cosmo Trader.xcodeproj/project.pbxproj"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Default options
CREATE_TAG=true
CREATE_COMMIT=true
PUSH_TAGS=false
DRY_RUN=false

# Functions
print_header() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  ${BOLD}Cosmo Trader Version Bump${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

show_usage() {
    echo -e "${BOLD}Usage:${NC} $0 <command> [options]"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo "  patch           Increment patch version (1.0.0 → 1.0.1)"
    echo "  minor           Increment minor version (1.0.0 → 1.1.0)"
    echo "  major           Increment major version (1.0.0 → 2.0.0)"
    echo "  set <version>   Set specific version (e.g., set 2.0.0)"
    echo "  current         Show current version"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  --no-tag        Skip git tag creation"
    echo "  --no-commit     Skip git commit"
    echo "  --push          Push tags to remote after creation"
    echo "  --dry-run       Show what would happen without making changes"
    echo "  -h, --help      Show this help message"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  $0 patch                    # Bump patch version"
    echo "  $0 minor --no-tag           # Bump minor, skip tag"
    echo "  $0 major --push             # Bump major and push"
    echo "  $0 set 2.0.0 --dry-run      # Preview setting version"
    echo ""
}

get_current_version() {
    grep -m 1 "MARKETING_VERSION" "${PBXPROJ_PATH}" | sed 's/.*= //' | sed 's/;//'
}

get_current_build() {
    grep -m 1 "CURRENT_PROJECT_VERSION" "${PBXPROJ_PATH}" | sed 's/.*= //' | sed 's/;//'
}

parse_version() {
    local version=$1
    # Handle versions with or without patch number
    if [[ $version =~ ^([0-9]+)\.([0-9]+)(\.([0-9]+))?$ ]]; then
        MAJOR="${BASH_REMATCH[1]}"
        MINOR="${BASH_REMATCH[2]}"
        PATCH="${BASH_REMATCH[4]:-0}"
        return 0
    else
        log_error "Invalid version format: $version"
        log_info "Expected format: X.Y or X.Y.Z"
        return 1
    fi
}

bump_version() {
    local bump_type=$1
    local current_version=$(get_current_version)

    parse_version "$current_version"

    case $bump_type in
        major)
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            ;;
        minor)
            MINOR=$((MINOR + 1))
            PATCH=0
            ;;
        patch)
            PATCH=$((PATCH + 1))
            ;;
        *)
            log_error "Unknown bump type: $bump_type"
            exit 1
            ;;
    esac

    # Return new version (without patch if it's 0)
    if [ $PATCH -eq 0 ]; then
        echo "${MAJOR}.${MINOR}"
    else
        echo "${MAJOR}.${MINOR}.${PATCH}"
    fi
}

update_project_version() {
    local new_version=$1
    local current_version=$(get_current_version)

    if [ "${DRY_RUN}" == "true" ]; then
        log_info "[DRY RUN] Would update MARKETING_VERSION: ${current_version} → ${new_version}"
        return 0
    fi

    # Update all occurrences of MARKETING_VERSION
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/MARKETING_VERSION = ${current_version};/MARKETING_VERSION = ${new_version};/g" "${PBXPROJ_PATH}"
    else
        sed -i "s/MARKETING_VERSION = ${current_version};/MARKETING_VERSION = ${new_version};/g" "${PBXPROJ_PATH}"
    fi

    log_success "Updated MARKETING_VERSION: ${current_version} → ${new_version}"
}

reset_build_number() {
    local current_build=$(get_current_build)

    if [ "${DRY_RUN}" == "true" ]; then
        log_info "[DRY RUN] Would reset CURRENT_PROJECT_VERSION: ${current_build} → 1"
        return 0
    fi

    # Reset build number to 1 on version bump
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/CURRENT_PROJECT_VERSION = ${current_build};/CURRENT_PROJECT_VERSION = 1;/g" "${PBXPROJ_PATH}"
    else
        sed -i "s/CURRENT_PROJECT_VERSION = ${current_build};/CURRENT_PROJECT_VERSION = 1;/g" "${PBXPROJ_PATH}"
    fi

    log_success "Reset CURRENT_PROJECT_VERSION: ${current_build} → 1"
}

create_git_commit() {
    local version=$1

    if [ "${DRY_RUN}" == "true" ]; then
        log_info "[DRY RUN] Would create commit: 'Bump version to ${version}'"
        return 0
    fi

    # Check if git is available and we're in a repo
    if ! command -v git &> /dev/null; then
        log_warning "git not found, skipping commit"
        return 0
    fi

    if [ ! -d "${PROJECT_DIR}/.git" ]; then
        log_warning "Not a git repository, skipping commit"
        return 0
    fi

    # Stage the project file
    git -C "${PROJECT_DIR}" add "${PBXPROJ_PATH}"

    # Create commit
    git -C "${PROJECT_DIR}" commit -m "Bump version to ${version}

🚀 Version ${version}
• Updated MARKETING_VERSION
• Reset build number to 1

🤖 Generated with version_bump.sh"

    log_success "Created git commit for version ${version}"
}

create_git_tag() {
    local version=$1
    local tag_name="v${version}"

    if [ "${DRY_RUN}" == "true" ]; then
        log_info "[DRY RUN] Would create tag: ${tag_name}"
        return 0
    fi

    # Check if git is available
    if ! command -v git &> /dev/null; then
        log_warning "git not found, skipping tag"
        return 0
    fi

    if [ ! -d "${PROJECT_DIR}/.git" ]; then
        log_warning "Not a git repository, skipping tag"
        return 0
    fi

    # Check if tag already exists
    if git -C "${PROJECT_DIR}" tag -l | grep -q "^${tag_name}$"; then
        log_warning "Tag ${tag_name} already exists"
        return 1
    fi

    # Create annotated tag
    git -C "${PROJECT_DIR}" tag -a "${tag_name}" -m "Release ${version}

Cosmo Trader v${version}
Released: $(date +"%Y-%m-%d")

🤖 Generated with version_bump.sh"

    log_success "Created git tag: ${tag_name}"
}

push_git_tags() {
    if [ "${DRY_RUN}" == "true" ]; then
        log_info "[DRY RUN] Would push tags to remote"
        return 0
    fi

    if ! command -v git &> /dev/null; then
        log_warning "git not found, skipping push"
        return 0
    fi

    git -C "${PROJECT_DIR}" push origin --tags

    log_success "Pushed tags to remote"
}

show_current_version() {
    local version=$(get_current_version)
    local build=$(get_current_build)

    echo -e "\n${BOLD}Current Version:${NC}"
    echo -e "  Version: ${GREEN}${version}${NC}"
    echo -e "  Build:   ${BLUE}${build}${NC}"
    echo -e "  Full:    ${CYAN}${version} (${build})${NC}\n"

    # Show git info if available
    if command -v git &> /dev/null && [ -d "${PROJECT_DIR}/.git" ]; then
        local git_commit=$(git -C "${PROJECT_DIR}" rev-parse --short HEAD 2>/dev/null || echo "unknown")
        local git_branch=$(git -C "${PROJECT_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        local git_tag=$(git -C "${PROJECT_DIR}" describe --tags --exact-match 2>/dev/null || echo "none")

        echo -e "${BOLD}Git Info:${NC}"
        echo -e "  Branch:  ${git_branch}"
        echo -e "  Commit:  ${git_commit}"
        echo -e "  Tag:     ${git_tag}\n"
    fi
}

# Parse arguments
COMMAND=""
SET_VERSION=""
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case $1 in
        major|minor|patch|current)
            COMMAND="$1"
            shift
            ;;
        set)
            COMMAND="set"
            SET_VERSION="$2"
            shift 2
            ;;
        --no-tag)
            CREATE_TAG=false
            shift
            ;;
        --no-commit)
            CREATE_COMMIT=false
            shift
            ;;
        --push)
            PUSH_TAGS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

# Validate command
if [ -z "${COMMAND}" ]; then
    print_header
    show_usage
    exit 1
fi

# Execute command
print_header

if [ "${DRY_RUN}" == "true" ]; then
    log_warning "DRY RUN MODE - No changes will be made"
    echo ""
fi

case $COMMAND in
    current)
        show_current_version
        ;;

    set)
        if [ -z "${SET_VERSION}" ]; then
            log_error "Version required for 'set' command"
            echo "Usage: $0 set <version>"
            exit 1
        fi

        # Validate version format
        if ! parse_version "${SET_VERSION}"; then
            exit 1
        fi

        log_info "Setting version to: ${SET_VERSION}"
        echo ""

        CURRENT=$(get_current_version)
        log_info "Current version: ${CURRENT}"

        update_project_version "${SET_VERSION}"
        reset_build_number

        if [ "${CREATE_COMMIT}" == "true" ]; then
            create_git_commit "${SET_VERSION}"
        fi

        if [ "${CREATE_TAG}" == "true" ]; then
            create_git_tag "${SET_VERSION}"
        fi

        if [ "${PUSH_TAGS}" == "true" ] && [ "${CREATE_TAG}" == "true" ]; then
            push_git_tags
        fi

        echo ""
        log_success "Version updated to ${SET_VERSION}"
        ;;

    major|minor|patch)
        CURRENT=$(get_current_version)
        NEW_VERSION=$(bump_version "${COMMAND}")

        log_info "Bump type: ${COMMAND}"
        log_info "Current version: ${CURRENT}"
        log_info "New version: ${NEW_VERSION}"
        echo ""

        update_project_version "${NEW_VERSION}"
        reset_build_number

        if [ "${CREATE_COMMIT}" == "true" ]; then
            create_git_commit "${NEW_VERSION}"
        fi

        if [ "${CREATE_TAG}" == "true" ]; then
            create_git_tag "${NEW_VERSION}"
        fi

        if [ "${PUSH_TAGS}" == "true" ] && [ "${CREATE_TAG}" == "true" ]; then
            push_git_tags
        fi

        echo ""
        log_success "Version bumped: ${CURRENT} → ${NEW_VERSION}"
        ;;

    *)
        log_error "Unknown command: ${COMMAND}"
        show_usage
        exit 1
        ;;
esac

echo ""
