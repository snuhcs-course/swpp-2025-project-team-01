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

echo -e "${GREEN}📦 Step 1/9: Creating conda environment '$ENV_NAME' with Python 3.12${NC}"
echo ""
conda create -n "$ENV_NAME" python=3.12 -y

echo ""
echo -e "${GREEN}📦 Step 2/9: Installing PyTorch with CUDA 12.9${NC}"
echo "   This will install torch, torchvision, torchaudio..."
echo ""
conda run -n "$ENV_NAME" pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu129

echo ""
echo -e "${GREEN}📦 Step 3/9: Installing CUDA Python${NC}"
echo ""
conda run -n "$ENV_NAME" pip install cuda-python==12.9.4

echo ""
echo -e "${GREEN}📦 Step 4/9: Installing NVIDIA NeMo for Parakeet ASR${NC}"
echo "   This will install NeMo toolkit with ASR support..."
echo ""
conda run -n "$ENV_NAME" pip install nemo_toolkit[asr]

echo ""
echo -e "${GREEN}📦 Step 5/9: Installing OpenAI Whisper and Kokoro${NC}"
echo "   This will install ASR models and TTS dependencies..."
echo ""
conda run -n "$ENV_NAME" pip install openai-whisper kokoro==0.9.4 librosa==0.11.0

echo ""
echo -e "${GREEN}📦 Step 6/9: Installing document processing libraries${NC}"
echo ""
conda run -n "$ENV_NAME" pip install pymupdf openpyxl

echo ""
echo -e "${GREEN}📦 Step 7/9: Installing transformers and ML utilities${NC}"
echo ""
conda run -n "$ENV_NAME" pip install -U transformers datasets peft

echo ""
echo -e "${GREEN}📦 Step 8/9: Installing FastAPI and server dependencies${NC}"
echo ""
conda run -n "$ENV_NAME" pip install fastapi aiofiles sse-starlette sseclient-py

echo ""
echo -e "${GREEN}📦 Step 9/9: Installing vLLM${NC}"
echo ""
conda run -n "$ENV_NAME" pip install vllm==0.10.2

echo ""
echo -e "${GREEN}⚡ Final Step: Installing flash-attn...${NC}"
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
