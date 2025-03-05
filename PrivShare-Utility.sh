#!/usr/bin/env bash
#     ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::       .<- 100    +   120 ->
#     ::                                                                                  ::       .
#     ::      _____     ______   ______     __  __     __   __     ______     ______      ::       .
#     ::     /\  __-.  /\__  _\ /\  == \   /\ \_\ \   /\ "-.\ \   /\  ___\   /\__  _\     ::       .
#     ::     \ \ \/\ \ \/_/\ \/ \ \  __<   \ \  __ \  \ \ \-.  \  \ \  __\   \/_/\ \/     ::       .
#     ::      \ \____-    \ \_\  \ \_\ \_\  \ \_\ \_\  \ \_\\"\_\  \ \_____\    \ \_\     ::       .
#     ::       \/____/     \/_/   \/_/ /_/   \/_/\/_/   \/_/ \/_/   \/_____/     \/_/     ::       .
#     ::                                                                                  ::       .
#     :::::::::::::::::::::::::::::::: [ HTTPS://DTRH.NET ] ::::::::::::::::::::::::::::::::       .
#                                                                                                  .
#          :: PROJECT: . . . . . . . . . . . . . . . . . . . . . . . . . . PrivShare               .
#          :: VERSION: . . . . . . . . . . . . . . . . . . . . . . . . . . 0.4.0                   .
#          :: AUTHOR:  . . . . . . . . . . . . . . . . . . . . . . . . . . KBS                     .
#          :: CREATED: . . . . . . . . . . . . . . . . . . . . . . . . . . 2025-02-17              .
#          :: LAST MODIFIED: . . . . . . . . . . . . . . . . . . . . . . . 2025-03-03              .
#                                                                                                  .
# :: FILE: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  PrivShare-Utility.sh     .
#                                                                                                  .
# :: DESCRIPTION: Utility script for PrivShare project.                                            .
#              ::  - OS Detection; Handle detection and automatically compensate for differences in.
#              ::                  filesystems, paths, package managers, env variables             .
#              ::  - Shell Detection;    Handle shell specific nuances gracefully (sh, bash, zsh)  .
#              :: - Virtual Environment: Detect if one is active -> Detect if one exists       ->  .
#                                     -> activate and update if exists -> create, activate and ->  .
#                                     -> update if not                                             .
#              :: OS & Shell Support: Linux, macOS, Android; sh, bash, zsh, dash (POSIX wip)       .
#              :: for future specific adaptations).                                                .
#                                                                                                  .
# :: USAGE:                                                                                        .
#         ::    -e | --execute   => python -m privshare.privshare_app                              .
#         ::    -t | --test      => python -m pytest privshare                                     .
#         ::    -a | --archive   => tar/gz the project to archives folder                          .
#         ::    -d | --database  => run db.sh                                                      .
#         ::    -h | --help      => usage instructions                                             .
#                                [ All  options handle parameters automatically ]                  .
#                                                                                                  .
# :: NOTES:                                                                                        .
#         :: WARNING - The utility script **must** be run from the PROJECT ROOT! It does not       .
#                      implement checking to ensure its path is correct.                           .
#         :: NOTE - The -d --database option runs separate script, these should be unified in      .
#                   the near future. Ensure you have set appropriate permissions for execution     .
#                   and with respect to postgresql, administration privileges. This can be set     .
#                   up as a user, but was outside the scope of my patience.                        .
#         :: NOTE - The app is not executed directly as this is not good practice in production    .
#                   and requires the use of WSGI Passenger. Locally, load it as a module.          .
#                                                                                                  .
# KBS <admin@dtrh.net>                                                                             .
# ====================                                                                             .
#                                                                                                  .
#                                                                                                  .
# --> [ 1.0 ] ###################################[ VARS & DECLARATIONS ]############################################## #
#
# [ 1.1 - CONSTANTS ] <----------------------------------------------------------------------------------------------
#
#     PROJECT_ROOT : The root of the project. This is set to $(pwd) only if both:
#                      - A file named "VERSION" exists in the current directory.
#                      - A subdirectory with the name given by APP_NAME exists.
#
#     APP_NAME     : The name of the application in lower case (e.g., "privshare").
#
#     APP_ROOT     : The full path to the application directory. Constructed as:
#                    ${PROJECT_ROOT}/${APP_NAME}
#
#     ARCHIVE_DIR  : The directory where generated archives are stored. Set as:
#                    ${PROJECT_ROOT}/Archives
#
#     TEST_DIR     : The directory containing unit tests for the application. Set as:
#                    ${APP_ROOT}/tests
#
#     VERSION      : The version string for the application. Read from the first line
#                    of the ${PROJECT_ROOT}/VERSION file. Expected to be in the format xx.xx.xx.
#
#     ENV_DIR      : The root directory for the Python virtual environment. Set as:
#                    ${PROJECT_ROOT}/.privshare-env
#
SCRIPT_FILE="$(basename $0)"      # I prefer to use the actual name as it is now
APP_NAME="privshare"              # Application name (all lower case)
PROJECT_ROOT="$(pwd)"             # Hopefully in our current directory
APP_ROOT="${PROJECT_ROOT}/${APP_NAME}"     # Set the expected file and directory locations
APP_COMMAND="python -m ${APP_NAME}.${APP_NAME}_app"   # Relative to root project dir
ARCHIVE_DIR="${PROJECT_ROOT}/archives"     # We keep archives outside the app_dir
VERSION="$(head -n 1 "${PROJECT_ROOT}/VERSION" | tr -d '[:space:]')"   # Read version from file, remove whitespace
DATE_STAMP="$(date +'%d.%m.%Y')"          # For unique archive naming
DB_SCRIPT="${PROJECT_ROOT}/db.sh"         # TODO : Integrate with this script
ENV_DIR="${PROJECT_ROOT}/.privshare-env"  # TODO : Configuration can set a different env name. For now, a hard coded
                                          #        virtual environment path will do
# TEST_DIR="${APP_ROOT}/tests"            # TODO : Unit Tests

if [[ -f "$(pwd)/VERSION" && -d "$(pwd)/${APP_NAME}" ]]; then # Determine if $(pwd) is ${PROJECT_ROOT}
  PROJECT_ROOT="$(pwd)"                                       # via rudimentary file expectations
else
  # Using escape characters for coloured output now, but easy colouring is much easier once initialized below.
  echo -e "\033[0;31m[ERROR]\033[0m Not in a valid project root. Must contain a VERSION file and a '${APP_NAME}' directory."
  exit 1
fi

# [ 1.2 - COLOURS ] <---------------------------------------------------------------------------------------------------

# NOTE : Assuming terminal is capable of 256 colours. No checking is implemented. If you have constraints, just ensure
#        the script stays within them.

# [ 1.2.1 flipFlop() ]==================================================================================================
#
#    SUMMARY. Toggle a variable's state between two defined pairs.
#
#              This function accepts the name of a variable as its parameter.
#              It retrieves the current value of the variable using indirect expansion,
#              then toggles the value based on these mappings:
#                - 0  -> 1             #  | F   P ^
#                - 1  -> 0             #  | L   O |
#                - true  -> false      #  | I   L |
#                - false -> true       #  V P   F |
#
# If the variable's value does not match any expected states, an error message is printed to stderr and the function
# returns a non-zero exit status. The variable in question remains with the value it had going in. This addresses
# directly using values in functions like 'cecho()' (below), allowing for gracefully handling invalid input.
#
# With no error, the new value is then assigned back to the original variable.
#
# USAGE:
#   flipFlop variableName
#
function flipFlop() {
  local varName="$1"
  local currentValue="${!varName}"
  local newValue
  case "$currentValue" in
    0) newValue=1 ;;
    1) newValue=0 ;;
    true) newValue=false ;;
    false) newValue=true ;;
    *) echo "Error: invalid input" >&2
       return 1 ;;
  esac
  printf -v "$varName" '%s' "$newValue"
}

# [ 1.2.2 - COLOUR ALIASES ]============================================================================================
# BOLD is used as the first attribute in the ANSI escape sequence.
# When not in use you can clear it via: BOLD="$(cat /dev/null)"
BOLD="0"

# <---[ STANDARD ] ------->  <--- [ LIGHT ] ------------>  <--- [ DARK ] ---------------->  <--- [ SHADES ] ------->
RED="\033[${BOLD};31m"     ; LRED="\033[${BOLD};91m"     ; DRED="\033[${BOLD};2;31m"      ; GRAY1="\033[${BOLD};97m"
GREEN="\033[${BOLD};32m"   ; LGREEN="\033[${BOLD};92m"   ; DGREEN="\033[${BOLD};2;32m"    ; GRAY2="\033[${BOLD};37m"
YELLOW="\033[${BOLD};33m"  ; LYELLOW="\033[${BOLD};93m"  ; DYELLOW="\033[${BOLD};2;33m"   ; GRAY3="\033[${BOLD};90m"
BLUE="\033[${BOLD};34m"    ; LBLUE="\033[${BOLD};94m"    ; DBLUE="\033[${BOLD};2;34m"     ; GRAY4="\033[${BOLD};30m"
CYAN="\033[${BOLD};36m"    ; LCYAN="\033[${BOLD};96m"    ; DCYAN="\033[${BOLD};2;36m"     ; GRAY5="\033[${BOLD};90m"
MAGENTA="\033[${BOLD};35m" ; LMAGENTA="\033[${BOLD};95m" ; DMAGENTA="\033[${BOLD};2;35m"  ; GRAY="\033[${BOLD};39m"
RESET="\033[0m"


# --> [ 2.0 ] ###########################################[ UI ]###################@@@@@@############################## #

# TODO : Make not shitty
# [ 2.1 - User Interface ]<-------------------------------------------------------------------------------------------
function show_usage() {
  echo -e "${BLUE}---------------------------------------------------${RESET}"
  echo -e "${BLUE} PrivShare v${VERSION} - ${SCRIPT_FILE} usage      ${RESET}"
  echo -e "${BLUE}---------------------------------------------------${RESET}"
  echo "Syntax: ${SCRIPT_FILE} [options]"
  echo "Options:"
  echo "  -e, --execute    => Run the Flask app (\"${APP_COMMAND}\")"
  echo "  -t, --test       => Run unit tests (\"${TEST_COMMAND}\")"
  echo "  -a, --archive    => Generate a tar.gz in 'archives/'"
  echo "  -d, --database   => Execute 'db.sh' in this directory"
  echo "  -h, --help       => Display this usage info (default if no args)"
  echo
  echo "For more details, see 'README.md' in './privshare/'."
}

# --> [ 3.0 ]################################[ FUNCTION DEFINITIONS ]################################################# #
#
# [ 3.1 - cecho($(cVar(str)), str, bool) ]<-----------------------------------------------------------------------------
#
#  SUMMARY:
#    Replaces echo to output coloured text.
#      $1: Name of the colour variable (e.g., RED, LGREEN, etc.)
#      $2: Text to display.
#      $3: Bold flag (1 or 0). If set to 1, the BOLD variable is flip-flopped for the duration of the echo.
#
#  NOTES: Follow good encapsulation practice -> Use quotations and nest them appropriately while expanding
#         An empty space signifies a change in parameter.
#         The third parameter, BOLD, is optional. If it doesnt exist, it will default 0
cecho() {
  if [ "$3" -eq 1 ]; then
    flipFlop BOLD                # The flipFlop function may come across as redundant given the
    echo -e "${!1}${2}${RESET}"  # script is expecting a 0 or a 1 with respect to the placement of the BOLD variable
    flipFlop BOLD                # in the colour definitions above.
  else                           # This function is used as a way of separating the direct use of parameter 3 should
    echo -e "${$1}${2}${RESET}"  # unexpected data be used. It's a bit of a safeguard, allowing graceful error handling.
  fi                             # flipFlop will also be used in many other instances, including changes to boolean
}                                # variables which use true/false


# [ 3.2 - do_archive() ]<-----------------------------------------------------------------------------------------------
#
# SUMMARY:
#   Generates a project archive using tar, excluding specific directories.
#   The archive is named using the application name, version, and current date.
#
# NOTES:
#   - Excludes the bin and upload directories under the app folder, as well as the virtual environment.
#   - Archives the entire project folder (using its basename).
#
function do_archive() {
  echo -e "${CYAN}[INFO]${RESET} Generating project archive..."

  # Ensure the archive directory exists
  mkdir -p "${ARCHIVE_DIR}"

  # Create the archive name using APP_NAME, VERSION, and the date stamp
  ARCHIVE_NAME="${APP_NAME}-${VERSION}-${DATE_STAMP}.tar.gz"

  # Get the basename of the project folder (for tar archiving)
  PROJECT_BASENAME="$(basename "$PROJECT_ROOT")"

  echo -e "${YELLOW}[ACTION]${RESET} Archiving project folder '${PROJECT_BASENAME}'..."
  # Change directory to the parent so the project folder is archived as a single directory
  cd .. || { echo -e "${RED}[ERROR]${RESET} Could not cd to parent directory"; exit 1; }

  # Create the archive excluding unwanted directories:
  #  - The 'bin' and 'upload' directories inside the application folder.
  #  - The virtual environment directory.
  tar --exclude="${PROJECT_BASENAME}/${APP_NAME}/bin" \       # TODO : Implement .gitignore parsing
      --exclude="${PROJECT_BASENAME}/${APP_NAME}/upload" \
      --exclude="${PROJECT_BASENAME}/${ENV_DIR}" \
      -cvzf archive.tar.gz "${PROJECT_BASENAME}"

  if [[ $? -ne 0 ]]; then
    echo -e "${RED}[ERROR]${RESET} tar command failed!"
    exit 1
  fi

  echo -e "${YELLOW}[ACTION]${RESET} Moving archive to '${ARCHIVE_DIR}/${ARCHIVE_NAME}'..."
  mv archive.tar.gz "${ARCHIVE_DIR}/${ARCHIVE_NAME}" || {
    echo -e "${RED}[ERROR]${RESET} Failed to move archive!"
    exit 1
  }

  # Return to the project directory
  cd "${PROJECT_BASENAME}" || { echo -e "${RED}[ERROR]${RESET} Could not return to project directory"; exit 1; }

  echo -e "${GREEN}[OK]${RESET} Archive created: '${ARCHIVE_DIR}/${ARCHIVE_NAME}'."
}

# [ 3.4 - do_database() ]<--------------------------------------------------------------------------------------------
#
# SUMMARY:
#   Executes the database setup script (db.sh) located at the project root.
#
function do_database() {
  echo -e "${CYAN}[INFO]${RESET} Running DB setup via '${DB_SCRIPT}'..."
  if [[ ! -f "${DB_SCRIPT}" ]]; then
    echo -e "${RED}[ERROR]${RESET} ${DB_SCRIPT} not found in ${PROJECT_ROOT}"
    exit 1
  fi

  chmod +x "${DB_SCRIPT}" 2>/dev/null || true
  echo -e "${YELLOW}[ACTION]${RESET} Executing ${DB_SCRIPT}"
  "${DB_SCRIPT}"
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}[ERROR]${RESET} db.sh encountered an error!"
    exit 1
  fi
  echo -e "${GREEN}[OK]${RESET} Database script completed successfully."
}


# [ 3.3 - do_env_setup() ]<--------------------------------------------------------------------------------------------
#
# SUMMARY:
#   Sets up the Python virtual environment if not already activated.
#
# STEPS:
#   1. Verify that the APP_ROOT exists.
#   2. Detect the operating system and shell.
#   3. If not in a virtual environment, create and activate one.
#   4. Upgrade pip and install dependencies if a requirements file is found.
#
function do_env_setup() {
  # Step 0: Check for existence of the application directory
  if [[ ! -d "${APP_ROOT}" ]]; then
    echo -e "${RED}[ERROR]${RESET} Missing '${APP_NAME}/' in $(pwd). Must run from the project root."
    exit 1
  fi

  # Step 3.3.1: Detect OS -------------------------------------------------------------------
  echo "-----------------------------------------"
  echo "Detecting Operating System..."
  UNAME_OUT="$(uname -s 2>/dev/null || true)"
  case "${UNAME_OUT}" in
    Linux*) OS_ID="Linux";;
    Darwin*) OS_ID="macOS"; echo "MacOS Detected. Not supported." && exit 1 ;;
    *) OS_ID="UNKNOWN"; echo "OS Not supported. Windows support with .bat/.ps1 installer" && exit 1 ;;
  esac
  echo "OS identified as: ${OS_ID}"

  # Step 3.3.2: Detect current shell (zsh or bash) -----------------------------------------
  CURRENT_SHELL="$(basename "$SHELL" 2>/dev/null || echo "bash")"
  echo "Detected shell: ${CURRENT_SHELL}"
  echo "-----------------------------------------"

  # [ 3.3.3 - Is VENV active ]<----------------------------------------------------------------------------------------
  #
  if [[ -n "$VIRTUAL_ENV" ]]; then                                               # TODO : Check venv name
    echo "Already in venv ($VIRTUAL_ENV). Skipping creation/activation steps."   # (This could false positive)
    return 0
  fi

  echo "No active virtual environment detected."
  # [ 3.3.4 - Upgrade pip and related tools ]<------------------------------------------------------------------------
  # Create venv if not detected
  #
  if [[ ! -d "${ENV_DIR}" ]]; then
    echo "${ENV_DIR} does not exist. Creating virtual environment..."
    python3 -m venv "${ENV_DIR}" || {
      echo -e "${RED}[ERROR]${RESET} Failed to create virtual environment. Exiting."
      exit 1
    }
    echo "Successfully created virtual environment."
  else
    echo "Virtual environment already exists; continuing."
  fi
  # [ 3.3.5 - Activate VENV ]<----------------------------------------------------------------------------------------
  #
  ACTIVATE_FILE="${ENV_DIR}/bin/activate"
  ACTIVATE_ZSH_FILE="${ENV_DIR}/bin/activate.zsh"

  if [[ "$CURRENT_SHELL" == "zsh" && -f "$ACTIVATE_ZSH_FILE" ]]; then
    echo "Activating environment with ZSH script: $ACTIVATE_ZSH_FILE"
    source "$ACTIVATE_ZSH_FILE"
  elif [[ -f "$ACTIVATE_FILE" ]]; then
    echo "Activating environment with Bash script: $ACTIVATE_FILE"
    source "$ACTIVATE_FILE"
  else
    echo -e "${RED}[ERROR]${RESET} No suitable activate script found."
    exit 1
  fi

  sleep 1
  if [[ -z "$VIRTUAL_ENV" ]]; then
    echo -e "${RED}[ERROR]${RESET} Activation failed!"
    exit 1
  fi
  echo "Environment activated: $VIRTUAL_ENV"

  # [ 3.3.6 - Upgrade pip and related tools ]<------------------------------------------------------------------------
  #
  echo "Upgrading pip, setuptools, disttools, buildtools..."
  python3 -m pip install --upgrade pip setuptools disttools buildtools || {
    echo -e "${YELLOW}[WARNING]${RESET} pip or related tools upgrade failed. Continuing."
  }

  # [ 3.3.7 - Install dependencies from requirements.txt if present ]<------------------------------------------------
  #
  if [[ -f "${APP_ROOT}/requirements.txt" ]]; then
    echo "Installing dependencies from ${APP_ROOT}/requirements.txt..."
    python3 -m pip install -r "${APP_ROOT}/requirements.txt" || {
      echo -e "${RED}[ERROR]${RESET} Failed installing dependencies."
      exit 1
    }
  else
    echo "No requirements.txt found. Skipping dependency installation."
  fi

  sleep 1
  echo "-----------------------------------------"
  echo "Activating Python Environment"
  echo "-----------------------------------------"
  source "${ENV_DIR}/bin/activate" &
  echo "-----------------------------------------"
  echo "Launching new shell with Python Environment"
  echo "-----------------------------------------"
}

# --> [ 4.0 ]################################[ PRELIMINARY CHECKS ]################################################# #
# Verify that the APP_ROOT exists in the current directory.
#
if [[ ! -d "${APP_ROOT}" ]]; then
  echo -e "${RED}[ERROR]${RESET} Missing '${APP_NAME}/' in $(pwd). Must run from the project root."
  exit 1
fi

# If no arguments are provided, display usage and exit.
#
if [[ $# -eq 0 ]]; then
  show_usage
  exit 0
fi

# Check if user only wants archive (-a) or help (-h) (and nothing else).
#
onlyArchiveOrHelp=true
for arg in "$@"; do
  case "$arg" in
    -a|--archive|-h|--help)
      # Valid standalone options
      ;;
    *)
      onlyArchiveOrHelp=false
      break
      ;;
  esac
done

# If arguments other than just -a or -h are provided, set up the environment.
#
if [[ "${onlyArchiveOrHelp}" == false ]]; then
  do_env_setup
fi

# [ 5.0 - Argument Parsing ]<-----------------------------------------------------------------------------------------
#
EXECUTE_ONCE=false
TEST_ONCE=false
ARCHIVE_ONCE=false
DATABASE_ONCE=false
HELP_ONCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--execute)
      EXECUTE_ONCE=true
      shift
      ;;
    -t|--test)
      TEST_ONCE=true
      shift
      ;;
    -a|--archive)
      ARCHIVE_ONCE=true
      shift
      ;;
    -d|--database)
      DATABASE_ONCE=true
      shift
      ;;
    -h|--help)
      HELP_ONCE=true
      shift
      ;;
    *)
      echo -e "${RED}[ERROR]${RESET} Unknown argument '$1'"
      show_usage
      exit 1
      ;;
  esac
done

# [ 5.1 - Execute the appropriate tasks based on parsed arguments ]<--------------------------------------------------
[[ "$HELP_ONCE" == true ]] && show_usage
[[ "$ARCHIVE_ONCE" == true ]] && do_archive
[[ "$DATABASE_ONCE" == true ]] && do_database

if [[ "$EXECUTE_ONCE" == true ]]; then
  echo -e "${CYAN}[INFO]${RESET} Running the application..."
  echo -e "${YELLOW}[ACTION]${RESET} python -m privshare.privshare_app"
  python -m privshare.privshare_app
fi

if [[ "$TEST_ONCE" == true ]]; then
  echo -e "${CYAN}[INFO]${RESET} Running unit tests..."
  echo -e "${YELLOW}[ACTION]${RESET} python -m pytest ${TEST_DIR}"
  python -m pytest "${TEST_DIR}"
fi

# [ 5.2 - Remain in Environment ]<-----------------------------------------------------------------------------------
# If running in a virtual environment, keep the shell open.
if [[ -z "$VIRTUAL_ENV" ]]; then
  echo -e "${YELLOW}[NOTE]${RESET} Not in a virtual environment, skipping new shell."
  exit 0
fi

CURRENT_SHELL="$(basename "$SHELL" 2>/dev/null || echo "bash")"
if [[ "$CURRENT_SHELL" == "zsh" ]]; then
  echo -e "${GREEN}[OK]${RESET} Launching zsh so you remain in the virtual environment..."
  exec zsh
else
  echo -e "${GREEN}[OK]${RESET} Launching bash so you remain in the virtual environment..."
  exec bash
fi


# v0.4.0 EOF
