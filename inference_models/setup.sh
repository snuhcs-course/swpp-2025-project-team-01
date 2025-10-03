#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default environment name
ENV_NAME="swpp-ai"

# Parse command line options
while getopts "n:" opt; do
    case $opt in
        n)
            ENV_NAME="$OPTARG"
            ;;
        \?)
            echo "Usage: $0 [-n env_name]"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}📦 Step 1/2: Creating conda environment '$ENV_NAME' (10-15 minutes)...${NC}"

# Override environment name with -n flag
conda env create -f environment.yml -n "$ENV_NAME"

echo ""
echo -e "${GREEN}⚡ Step 2/2: Installing flash-attn...${NC}"
echo "   Compiling CUDA code, this is normal..."

# Install flash-attn (optional, GPU required)
if conda run -n "$ENV_NAME" pip install flash-attn==2.8.3 --no-build-isolation; then
    echo -e "${GREEN}✓ Flash Attention installed${NC}"
else
    echo -e "${YELLOW}⚠ Flash Attention failed (optional, requires GPU)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. conda activate $ENV_NAME"
echo "  2. python your_script.py"