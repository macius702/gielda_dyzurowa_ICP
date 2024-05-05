#! /usr/bin/env bash

set -e

CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Checking for uncommitted changes...${NC}"
if [ -n "$(git status --porcelain)" ]; then
    echo "There are uncommitted changes. Please commit or stash them before proceeding."
    exit 1
fi


echo -e "${CYAN}Pushing to git...${NC}"
git push

echo -e "${CYAN}Changing to parent directory...${NC}"
cd ..

echo -e "${CYAN}Removing gielda_dyzurowa_ICP directory...${NC}"
rm -rf gielda_dyzurowa_ICP

echo -e "${CYAN}Cloning from git...${NC}"
git clone git@github.com:macius702/gielda_dyzurowa_ICP.git


echo -e "${CYAN}Changing to gielda_dyzurowa_ICP directory...${NC}"
cd gielda_dyzurowa_ICP

echo -e "${CYAN}Running build_and_run.sh...${NC}"
./build_and_run.sh