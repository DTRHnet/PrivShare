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
# :: FILE: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . db.sh                   .
#                                                                                                  .
# :: DESCRIPTION: Initializes the SQLite database, ensures Flask-Migrate is installed, and applies .
#                 database migrations. If no migrations exist, it creates them.                    .
#                                                                                                  .
# :: CONTACT:     < admin@dtrh.net >                                                               .
#                 https://DtRH.net                                                                 .
# :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.
set -e  # Exit immediately if any command exits with a non-zero status.

# [ 1.2.2 - COLOUR ALIASES ]============================================================================================
# BOLD is used as the first attribute in the ANSI escape sequence.
# When not in use you can clear it via: BOLD="$(cat /dev/null)
# TODO : Write text related var/alias/functions as a sourcable module
BOLD="0"

# <---[ STANDARD ] ------->  <--- [ LIGHT ] ------------>  <--- [ DARK ] ---------------->  <--- [ SHADES ] ------->
RED="\033[${BOLD};31m"     ; LRED="\033[${BOLD};91m"     ; DRED="\033[${BOLD};2;31m"      ; GRAY1="\033[${BOLD};97m"
GREEN="\033[${BOLD};32m"   ; LGREEN="\033[${BOLD};92m"   ; DGREEN="\033[${BOLD};2;32m"    ; GRAY2="\033[${BOLD};37m"
YELLOW="\033[${BOLD};33m"  ; LYELLOW="\033[${BOLD};93m"  ; DYELLOW="\033[${BOLD};2;33m"   ; GRAY3="\033[${BOLD};90m"
BLUE="\033[${BOLD};34m"    ; LBLUE="\033[${BOLD};94m"    ; DBLUE="\033[${BOLD};2;34m"     ; GRAY4="\033[${BOLD};30m"
CYAN="\033[${BOLD};36m"    ; LCYAN="\033[${BOLD};96m"    ; DCYAN="\033[${BOLD};2;36m"     ; GRAY5="\033[${BOLD};90m"
MAGENTA="\033[${BOLD};35m" ; LMAGENTA="\033[${BOLD};95m" ; DMAGENTA="\033[${BOLD};2;35m"  ; GRAY="\033[${BOLD};39m"
RESET="\033[0m"

# [ 2.0 - FUNCTION DEFINITIONS ]####################################################################################

# [ 2.1 - cecho() FUNCTION ]<-------------------------------------------------------------------------------------------
# SUMMARY:
#   Replaces echo to output coloured text.
#   $1: Name of the colour variable (e.g., RED, LGREEN, etc.)
#   $2: Text to display.
#   $3: Bold flag (1 or 0). If set to 1, toggles the BOLD variable for the duration of the echo.
#
# NOTES:
#   Uses indirect variable expansion to reference colour variables.
cecho() {
  if [ "$3" -eq 1 ]; then
    flipFlop BOLD
    echo -e "${!1}${2}${RESET}"
    flipFlop BOLD
  else
    echo -e "${!1}${2}${RESET}"
  fi
}

# [ 2.2 - flipFlop() FUNCTION ]<----------------------------------------------------------------------------------------
# SUMMARY:
#   Toggles the value of the provided variable (currently only supports BOLD).
flipFlop() {
  if [ "$1" = "BOLD" ]; then
    if [ "$BOLD" = "0" ]; then
      BOLD="1"
    else
      BOLD="0"
    fi
  fi
}

# [ 3.0 - GLOBAL VARIABLE DECLARATIONS AND INITIALIZATION ]===========================================================
PROJECT_DIR="$(pwd)"                        # Must be run in the project root.
APP_NAME="privshare"                        # Application name.
APP_DIR="${APP_NAME}"                       # Application directory.
APP_VERSION="0.4.0"                         # Application version.
FLASK_APP="${APP_DIR}/privshare_app.py"       # Entry point for the Flask app.

cecho GREEN "${APP_NAME} v${APP_VERSION} Database Setup for PostgreSQL\n" 0

# [ 4.0 - ENVIRONMENT CHECKS ]==========================================================================================
# 4.1 - Verify virtual environment.
if [ -z "$VIRTUAL_ENV" ]; then
  cecho RED "Error: You are not in a virtual environment. Please activate your virtual environment and try again.\n" 0
  exit 1
else
  VENV_NAME=$(basename "$VIRTUAL_ENV")
  if [ "$VENV_NAME" != ".privshare-env" ]; then
    cecho YELLOW "Warning: You are in a virtual environment named '$VENV_NAME', but the recommended name is '.privshare-env'.\n" 0
  else
    cecho GREEN "Virtual environment '$VENV_NAME' verified.\n" 0
  fi
fi

# [ 5.0 - DEPENDENCY UPGRADE ]============================================================================================
cecho GREEN "Upgrading Flask-Migrate...\n" 0
pip install --upgrade Flask-Migrate
if [ $? -ne 0 ]; then
  cecho RED "Error upgrading Flask-Migrate. Exiting.\n" 0
  exit 1
fi
cecho GREEN "Flask-Migrate upgraded successfully.\n" 0

# [ 6.0 - SET DATABASE CONNECTION FOR POSTGRESQL ]=======================================================================
# NOTE: Update the connection string with your actual PostgreSQL credentials.
export DATABASE_URI="postgresql://username:password@localhost:5432/${APP_NAME}"
cecho GREEN "Using database URI: ${YELLOW}${DATABASE_URI}\n" 0

MIGRATIONS_FOLDER="migrations"

# [ 7.0 - DATABASE MIGRATION SETUP ]====================================================================================
# 7.1 - Initialize migrations if the migrations folder does not exist.
if [ ! -d "$MIGRATIONS_FOLDER" ]; then
  cecho YELLOW "No migration folder found. Initializing Flask-Migrate...\n" 0
  flask db init
  if [ $? -ne 0 ]; then
    cecho RED "Error initializing migrations. Exiting.\n" 0
    exit 1
  fi
  cecho GREEN "Flask-Migrate initialized successfully.\n" 0
fi

# 7.2 - Generate a new migration if no migration history is present.
if [ -z "$(ls -A $MIGRATIONS_FOLDER/versions 2>/dev/null)" ]; then
  cecho YELLOW "No migration history found. Generating a new migration...\n" 0
  flask db migrate -m "Initial database migration"
  if [ $? -ne 0 ]; then
    cecho RED "Error creating initial migration. Exiting.\n" 0
    exit 1
  fi
  cecho GREEN "Database migration created successfully.\n" 0
fi

# 7.3 - Apply database migrations.
cecho GREEN "Applying database migrations...\n" 0
flask db upgrade
if [ $? -eq 0 ]; then
  cecho GREEN "Database setup complete for PostgreSQL.\n" 0
else
  cecho RED "An error occurred during the database migration process.\n" 0
  exit 1
fi


# v0.4.0 EOF
