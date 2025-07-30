# Model Configuration Guide

This directory contains model configuration files for different platforms. The AI models used in the Agentic AI System are now centrally configured through these files.


## Configuration Files

- `models-mac.conf` - Model configuration for macOS/Apple Silicon platforms
- `models-linux.conf` - Model configuration for Linux/NVIDIA GPU platforms
- `models-4gb.conf` - **Lightweight model configuration for systems with limited VRAM (4GB or less)**
- `litellm/config.yaml.template` - Template for LiteLLM configuration (processed during setup)

## Model Types

Each configuration file defines the following model types:

1. **Primary Model** - General-purpose model for complex reasoning and analysis
2. **Code Model** - Specialized model for code generation and technical tasks
3. **Embedding Model** - Model for vector operations and semantic search
4. **Reranking Model** - Model for search result optimization
5. **Small Model** - Fast, lightweight model for quick tasks

## Default Models

### Mac Platform (Apple Silicon)
- Primary: `qwen3:235b-a22b`
- Code: `mychen76/qwen3_cline_roocode`
- Embedding: `dengcao/Qwen3-Embedding-8B:Q5_K_M`
- Reranking: `dengcao/Qwen3-Reranker-8B:Q5_K_M`
- Small: `mistral:7b-instruct-q8_0`

### Linux Platform (NVIDIA GPU)
- Primary: `Llama4:Scout`
- Code: `codellama:34b`
- Embedding: `jeffh/intfloat-e5-base-v2:f16`
- Reranking: `jeffh/intfloat-e5-base-v2:f16`
- Small: `mistral:7b-instruct-q8_0`

## Customizing Models

To use different models:

1. Edit the appropriate configuration file (`models-mac.conf` or `models-linux.conf`)
2. Update the model names for the desired model types
3. Run the setup script - it will automatically:
   - Pull the configured models from Ollama
   - Generate the LiteLLM configuration with your models
   - Configure all services to use the specified models

## Example Customization

To change the primary model on Mac:

```bash
# Edit config/models-mac.conf
PRIMARY_MODEL="llama3:70b"  # Change from default qwen3:235b-a22b
```

Then run the setup:
```bash
./setup.sh
```

The setup script will handle all necessary configuration updates automatically.

## Adding New Models

To add models to the pull list, edit the `MODELS_TO_PULL` array in the configuration file:

```bash
declare -a MODELS_TO_PULL=(
    "$PRIMARY_MODEL"
    "$CODE_MODEL"
    "$EMBEDDING_MODEL"
    "$RERANKING_MODEL"
    "$SMALL_MODEL"
    "my-custom-model:latest"  # Add custom model
)
```

## 4GB Configuration

The `models-4gb.conf` file provides a lightweight model configuration designed for:
- Systems with limited VRAM (4GB or less)
- Testing and development environments
- Smaller deployments with constrained resources

### Key Differences
- Smaller, more memory-efficient models
- Reduced model sizes to fit within 4GB VRAM
- Faster model download time
- Suitable for initial testing or low-resource scenarios

### Switching to 4GB Configuration

To use the 4GB configuration:

```bash
# For Mac
cp config/models-4gb.conf config/models-mac.conf

# For Linux/NVIDIA
cp config/models-4gb.conf config/models-linux.conf

# Then run setup
./setup.sh
```

**Note:** The 4GB configuration trades some model performance for lower memory usage. For production or high-performance requirements, use the platform-specific default configurations.

## Model Aliases

The configuration also supports model aliases for easier reference in applications. These are automatically configured in LiteLLM:

- `primary` → Primary model
- `code` → Code model
- `embedding` → Embedding model
- `reranking` → Reranking model
- `small` → Small model

## Notes

- Model names must be valid Ollama model identifiers
- Large models may take significant time to download
- Ensure you have sufficient disk space for the models
- GPU memory requirements vary by model size
- The setup scripts will verify model availability after pulling