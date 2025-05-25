# Local LLM Setup Guide

## Why Local LLM?
- **Privacy**: All data stays on your network
- **Speed**: Sub-200ms response times
- **Cost**: No API fees
- **Reliability**: Works without internet

## Recommended Models for Home Assistant

### Best Overall: Llama 3.2 3B
- **Size**: 1.9GB
- **Speed**: 150-300ms on modern CPU
- **Quality**: Excellent for home automation
- **RAM**: 4GB minimum

### Fastest: Phi-3 Mini
- **Size**: 2.3GB  
- **Speed**: 100-200ms
- **Quality**: Good for simple commands
- **RAM**: 3GB minimum

### Most Capable: Mistral 7B
- **Size**: 4.1GB
- **Speed**: 300-500ms
- **Quality**: Best understanding
- **RAM**: 8GB minimum

## Installation Steps

### 1. Install Ollama on Your Server

**On Windows (where HA is running):**
```powershell
# Download installer from ollama.ai
# Or use winget:
winget install Ollama.Ollama

# Start Ollama service
ollama serve
```

**On Linux (alternative):**
```bash
curl -fsSL https://ollama.ai/install.sh | sh
sudo systemctl enable ollama
sudo systemctl start ollama
```

### 2. Pull Your Chosen Model
```bash
# For Llama 3.2 (recommended)
ollama pull llama3.2:3b

# For Phi-3 (fastest)
ollama pull phi3:mini

# For Mistral (most capable)
ollama pull mistral:7b
```

### 3. Configure Ollama for Network Access

Edit Ollama environment:
```bash
# Windows: Set environment variable
OLLAMA_HOST=0.0.0.0:11434

# Linux: Edit service
sudo systemctl edit ollama.service
# Add:
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
```

### 4. Update n8n Workflow

#### Option A: Direct Ollama Integration
1. In n8n, add new credentials:
   - Type: Ollama
   - Base URL: `http://YOUR_HA_SERVER_IP:11434`

2. Replace OpenAI Agent with Ollama Agent:
   - Model: llama3.2:3b
   - Temperature: 0.7
   - System prompt:
   ```
   You are a Home Assistant voice assistant running locally. 
   You help control smart home devices and answer questions.
   Be concise but friendly. Responses should be under 50 words.
   ```

#### Option B: Keep OpenAI Structure
Keep the same n8n workflow but point to local Ollama:

1. Update the `/tags` webhook response:
```json
{
  "models": [
    {
      "name": "llama3.2:3b",
      "model": "llama3.2:3b"
    }
  ]
}
```

2. Add HTTP Request node instead of AI Agent:
```javascript
// In Function node before HTTP Request
const messages = $json.body.messages;
const lastMessage = messages[messages.length - 1].content;

return {
  json: {
    model: "llama3.2:3b",
    messages: messages,
    stream: false,
    options: {
      temperature: 0.7,
      top_p: 0.9,
      num_predict: 100  // Limit response length
    }
  }
};
```

3. HTTP Request to Ollama:
- URL: `http://YOUR_HA_SERVER_IP:11434/api/chat`
- Method: POST
- Body: `{{ $json }}`

### 5. Update Home Assistant

If you changed the model name, update HA:
1. Remove old Ollama integration
2. Re-add with same n8n URL
3. Select new model: llama3.2:3b

### 6. Performance Tuning

#### CPU Optimization
```bash
# Set thread count (usually CPU cores - 1)
ollama run llama3.2:3b --num-thread 7

# For permanent setting
OLLAMA_NUM_THREADS=7
```

#### Memory Settings
```bash
# Increase context window for better memory
OLLAMA_NUM_CTX=4096

# Reduce if running out of RAM
OLLAMA_NUM_CTX=2048
```

#### Model Customization
Create a Modelfile for home automation:
```dockerfile
FROM llama3.2:3b

PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER num_predict 100

SYSTEM """
You are Home Assistant AI, a smart home voice assistant.
Your responses should be:
- Brief (under 30 words)
- Action-oriented for commands
- Friendly but efficient
- Aware of common smart home devices

When controlling devices, always confirm the action.
"""
```

Build custom model:
```bash
ollama create ha-assistant -f Modelfile
```

### 7. Hybrid Approach (Best of Both)

Use local for device control, cloud for complex queries:

In n8n Switch node, add routing:
- Device commands → Local Ollama
- Weather/news/complex → OpenAI
- Default conversation → Local Ollama

### 8. Monitoring & Logs

Check Ollama performance:
```bash
# View logs
journalctl -u ollama -f

# Check model usage
ollama ps

# Test response time
time curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Turn on the lights"
}'
```

### 9. Troubleshooting

**Slow responses:**
- Reduce num_predict
- Use smaller model (phi3:mini)
- Check CPU usage
- Disable other services

**Out of memory:**
- Use quantized models (Q4_0)
- Reduce context window
- Close other applications

**Connection refused:**
- Check OLLAMA_HOST=0.0.0.0
- Verify firewall rules
- Test with localhost first

### 10. Advanced: GPU Acceleration

If you have NVIDIA GPU:
```bash
# Install CUDA version
ollama run llama3.2:3b --gpu

# Check GPU usage
nvidia-smi
```

This can reduce response time to under 100ms! 