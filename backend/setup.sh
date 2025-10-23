#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default environment name
ENV_NAME="swpp-backend"

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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Backend + AI Environment Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${GREEN}📦 Step 1/2: Creating conda environment '$ENV_NAME' from environment.yml${NC}"
echo "   This will install Python 3.12, PyTorch, ML libraries, and FastAPI (10-15 minutes)..."
echo ""

# Create conda environment from environment.yml
conda env create -f "$SCRIPT_DIR/environment.yml" -n "$ENV_NAME"

echo ""
echo -e "${GREEN}⚡ Step 2/2: Installing flash-attn (optional, GPU-only)...${NC}"
echo "   Compiling CUDA code, this is normal..."
echo ""

# Install flash-attn (optional, GPU required)
if conda run -n "$ENV_NAME" pip install flash-attn==2.8.3 --no-build-isolation; then
    echo -e "${GREEN}✓ Flash Attention installed${NC}"
else
    echo -e "${YELLOW}⚠ Flash Attention failed (optional, requires GPU)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
echo "Environment '$ENV_NAME' is ready!"
echo ""
echo "Next steps:"
echo "  1. conda activate $ENV_NAME"
echo "  2. cd backend"
echo "  3. python main.py"
echo ""
echo "Or use uvicorn directly:"
echo "  uvicorn main:app --reload --host 0.0.0.0 --port 8000"
echo -e "${BLUE}========================================${NC}"
