#!/bin/bash
echo "

__________             .__          .___.__    .___  ________      /\  ____ ____ 
\______   \__ __  _____|  |__     __| _/|__| __| _/ /   __   \    / / /_   /_   |
 |    |  _/  |  \/  ___/  |  \   / __ | |  |/ __ |  \____    /   / /   |   ||   |
 |    |   \  |  /\___ \|   Y  \ / /_/ | |  / /_/ |     /    /   / /    |   ||   |
 |______  /____//____  >___|  / \____ | |__\____ |    /____/   / /     |___||___|
        \/           \/     \/       \/         \/             \/                
        
"
sleep 1

# Check if huggingface-cli is installed
if ! command -v huggingface-cli &> /dev/null; then
    echo "huggingface-cli is not installed. Installing it now..."
    pip install -U "huggingface_hub[cli]"
fi

# Ask for authentication with Hugging Face
echo "Please authenticate with Hugging Face..."
huggingface-cli login

# Clone ComfyUI repository
echo "Cloning ComfyUI repository..."
git clone https://github.com/comfyanonymous/ComfyUI
cd ComfyUI

# Install requirements
echo "Installing Python requirements..."
pip install -r requirements.txt
pip install sageattention

# Clone ComfyUI-Manager into custom_nodes
echo "Installing ComfyUI-Manager..."
cd custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager
cd ..

# Remove existing models if any
echo "Clearing models directory..."
rm -rf models/*

# Create necessary directories for models
echo "Creating model directories..."
mkdir -p models/vae
mkdir -p models/text_encoders
mkdir -p models/clip_vision
mkdir -p models/diffusion_models

# Download files from Hugging Face
echo "Downloading model files from Hugging Face..."

# Download VAE
echo "Downloading VAE model..."
huggingface-cli download Comfy-Org/Wan_2.1_ComfyUI_repackaged split_files/vae/wan_2.1_vae.safetensors --local-dir models/vae
# Move the file to the correct location
mv models/vae/split_files/vae/wan_2.1_vae.safetensors models/vae/
rm -rf models/vae/split_files

# Download Text Encoder
echo "Downloading Text Encoder model..."
huggingface-cli download Comfy-Org/Wan_2.1_ComfyUI_repackaged split_files/text_encoders/umt5_xxl_fp16.safetensors --local-dir models/text_encoders
# Move the file to the correct location
mv models/text_encoders/split_files/text_encoders/umt5_xxl_fp16.safetensors models/text_encoders/
rm -rf models/text_encoders/split_files

# Download CLIP Vision
echo "Downloading CLIP Vision model..."
huggingface-cli download Comfy-Org/Wan_2.1_ComfyUI_repackaged split_files/clip_vision/clip_vision_h.safetensors --local-dir models/clip_vision
# Move the file to the correct location
mv models/clip_vision/split_files/clip_vision/clip_vision_h.safetensors models/clip_vision/
rm -rf models/clip_vision/split_files

# Ask user which diffusion models they want to download
echo "Which diffusion models would you like to download? (Type the numbers separated by space, e.g., '1 3 5')"
echo "1. Text-to-Video (t2v) 14B FP16"
echo "2. Image-to-Video (i2v) 480p 14B FP16"
echo "3. Image-to-Video (i2v) 720p 14B FP16"
echo "4. Image-to-Video (i2v) 480p 14B FP8 (smaller size)"
echo "5. Image-to-Video (i2v) 720p 14B FP8 (smaller size)"
read -a model_choices

# Create an array to store selected file paths
declare -a selected_models
declare -a selected_model_names

# Map user choices to file paths
for choice in "${model_choices[@]}"; do
    case $choice in
        1)
            selected_models+=("split_files/diffusion_models/wan2.1_t2v_14B_fp16.safetensors")
            selected_model_names+=("wan2.1_t2v_14B_fp16.safetensors")
            ;;
        2)
            selected_models+=("split_files/diffusion_models/wan2.1_i2v_480p_14B_fp16.safetensors")
            selected_model_names+=("wan2.1_i2v_480p_14B_fp16.safetensors")
            ;;
        3)
            selected_models+=("split_files/diffusion_models/wan2.1_i2v_720p_14B_fp16.safetensors")
            selected_model_names+=("wan2.1_i2v_720p_14B_fp16.safetensors")
            ;;
        4)
            selected_models+=("split_files/diffusion_models/wan2.1_i2v_480p_14B_fp8_scaled.safetensors")
            selected_model_names+=("wan2.1_i2v_480p_14B_fp8_scaled.safetensors")
            ;;
        5)
            selected_models+=("split_files/diffusion_models/wan2.1_i2v_720p_14B_fp8_scaled.safetensors")
            selected_model_names+=("wan2.1_i2v_720p_14B_fp8_scaled.safetensors")
            ;;
        *)
            echo "Invalid choice: $choice - skipping"
            ;;
    esac
done

# Download selected diffusion models
if [ ${#selected_models[@]} -eq 0 ]; then
    echo "No models selected. Skipping diffusion model download."
else
    echo "Downloading selected diffusion models..."
    for i in "${!selected_models[@]}"; do
        echo "Downloading ${selected_model_names[$i]}..."
        huggingface-cli download Comfy-Org/Wan_2.1_ComfyUI_repackaged "${selected_models[$i]}" --local-dir models/diffusion_models
        
        # Extract the filename from the path
        filename=$(basename "${selected_models[$i]}")
        
        # Move the file to the correct location
        mv "models/diffusion_models/split_files/diffusion_models/$filename" models/diffusion_models/
        
        echo "${selected_model_names[$i]} downloaded successfully."
    done
    
    # Clean up split_files directories
    rm -rf models/diffusion_models/split_files
fi

echo "Setup complete! ComfyUI has been installed with all required models."
cd ComfyUI && python3 main.py --listen --use-sage-attention