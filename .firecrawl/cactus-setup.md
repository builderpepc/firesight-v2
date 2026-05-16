#!/bin/bash

if \[\[ "${BASH\_SOURCE\[0\]}" == "${0}" \]\]; then
 echo "Please run: source ./setup"
 return 1 2>/dev/null \|\| exit 1
fi

PROJECT\_ROOT="$(cd "$(dirname "${BASH\_SOURCE\[0\]}")" && pwd)"
VENV\_DIR="$PROJECT\_ROOT/venv"
REQUIREMENTS\_FILE="${CACTUS\_REQUIREMENTS:-$PROJECT\_ROOT/python/requirements.txt}"
PARENT\_REQUIREMENTS="$PROJECT\_ROOT/../requirements.txt"

RED='\\033\[0;31m'\
GREEN='\\033\[0;32m'\
YELLOW='\\033\[1;33m'\
BLUE='\\033\[0;34m'\
NC='\\033\[0m'\
\
echo "Setting up Cactus development environment..."\
echo "============================================="\
echo ""\
\
echo -e "${BLUE}Step 1: Configuring git hooks for DCO...${NC}"\
git config core.hooksPath .githooks\
echo -e "${GREEN}✓ Git hooks configured${NC}"\
\
name=$(git config user.name \|\| true)\
email=$(git config user.email \|\| true)\
\
if \[ -z "$name" \] \|\| \[ -z "$email" \]; then\
 echo ""\
 echo -e "${YELLOW}⚠️ Warning: Git user configuration is incomplete${NC}"\
 echo ""\
 echo "Please configure your git identity:"\
 echo " git config --global user.name \\"Your Name\\""\
 echo " git config --global user.email \\"your.email@example.com\\""\
 echo ""\
else\
 echo -e "${GREEN}✓ Git user: $name <$email>${NC}"\
fi\
\
echo ""\
echo -e "${BLUE}Step 2: Setting up Python virtual environment...${NC}"\
\
if ! command -v python3.12 &> /dev/null; then\
 echo -e "${RED}Error: python3.12 is not installed${NC}"\
 echo ""\
 echo "Please install python3.12:"\
 echo " macOS: brew install python@3.12"\
 echo " Ubuntu/Debian: sudo apt-get install python3.12 python3.12-venv"\
 return 1\
fi\
\
if \[ ! -d "$VENV\_DIR" \]; then\
 if ! python3.12 -m venv "$VENV\_DIR"; then\
 echo -e "${RED}Failed to create virtual environment${NC}"\
 echo "Please ensure python3.12-venv is installed:"\
 echo " Ubuntu/Debian: sudo apt-get install python3.12-venv"\
 echo " macOS: Should be included with Python3.12"\
 return 1\
 fi\
 echo -e "${GREEN}✓ Virtual environment created${NC}"\
else\
 echo -e "${GREEN}✓ Virtual environment already exists${NC}"\
fi\
\
source "$VENV\_DIR/bin/activate"\
\
echo ""\
echo -e "${BLUE}Step 3: Installing Python dependencies...${NC}"\
\
python3 -m pip install --upgrade pip -q\
\
if \[ -f "$REQUIREMENTS\_FILE" \]; then\
 if python3 -m pip install -r "$REQUIREMENTS\_FILE" -q; then\
 echo -e "${GREEN}✓ Dependencies installed${NC}"\
 else\
 echo -e "${RED}Failed to install dependencies${NC}"\
 return 1\
 fi\
else\
 echo -e "${YELLOW}Warning: requirements.txt not found${NC}"\
fi\
\
if \[ -f "$PARENT\_REQUIREMENTS" \] && \[ "$PARENT\_REQUIREMENTS" != "$REQUIREMENTS\_FILE" \]; then\
 echo ""\
 echo -e "${BLUE}Detected parent repo requirements at: $PARENT\_REQUIREMENTS${NC}"\
 echo -e "${BLUE}Installing parent repo requirements...${NC}"\
 if python3 -m pip install -r "$PARENT\_REQUIREMENTS" -q; then\
 echo -e "${GREEN}✓ Parent repo dependencies installed${NC}"\
 else\
 echo -e "${YELLOW}Warning: failed to install parent repo requirements${NC}"\
 fi\
fi\
\
echo ""\
echo -e "${BLUE}Step 4: Installing cactus CLI tools...${NC}"\
\
if python3 -m pip install -e "$PROJECT\_ROOT/python" --quiet; then\
 echo -e "${GREEN}✓ Cactus CLI installed${NC}"\
else\
 echo -e "${RED}Failed to install cactus CLI${NC}"\
 return 1\
fi\
\
echo ""\
echo -e "${GREEN}=============================================${NC}"\
echo -e "${GREEN}Setup complete!${NC}"\
echo -e "${GREEN}=============================================${NC}"\
echo ""\
cactus --help