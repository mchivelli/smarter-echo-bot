# n8n.cloud Workflow Setup Guide

## 1. Create n8n.cloud Account
- Go to https://n8n.cloud and sign up
- Create new workflow named "HA-Assist-Ollama"

## 2. Create Three Webhook Nodes

### Webhook 1: Version Endpoint
- **Node Type**: Webhook
- **HTTP Method**: GET  
- **Path**: `/version`
- **Respond**: Immediately
- **Response Data**:
```json
{
  "version": "0.5.13"
}
```

### Webhook 2: List Models Endpoint
- **Node Type**: Webhook
- **HTTP Method**: GET
- **Path**: `/tags`
- **Respond**: Immediately
- **Response Data**:
```json
{
  "models": [
    {
      "name": "gpt-3.5-turbo",
      "model": "gpt-3.5-turbo",
      "size": 0,
      "digest": "",
      "details": {
        "format": "gguf",
        "family": "gpt",
        "families": ["gpt"],
        "parameter_size": "3.5B",
        "quantization_level": "Q4_0"
      }
    },
    {
      "name": "gpt-4",
      "model": "gpt-4",
      "size": 0,
      "digest": "",
      "details": {
        "format": "gguf",
        "family": "gpt",
        "families": ["gpt"],
        "parameter_size": "175B",
        "quantization_level": "Q4_0"
      }
    }
  ]
}
```

### Webhook 3: Chat Endpoint
- **Node Type**: Webhook
- **HTTP Method**: POST
- **Path**: `/chat`
- **Respond**: Using 'Respond to Webhook' Node
- **Authentication**: None

## 3. Create Processing Chain

### AI Agent Node
- **Model**: OpenAI Chat Model
- **Model Name**: gpt-3.5-turbo
- **API Key**: Add OpenAI credentials
- **Prompt** (Expression):
```
{{ $json.body.messages[$json.body.messages.length - 1].content }}
```
- **System Message**:
```
You are a helpful Home Assistant voice assistant. You can control smart home devices and have natural conversations. When asked to control devices, respond conversationally while confirming the action.
```

### Set Node (Format Response)
- **Keep Only Set**: Yes
- **Fields to Set**:
  - **Field**: output
  - **Value** (Expression):
```javascript
{{ $json.output.replace(/\n/g, "\\n").replace(/"/g, '\\"') }}
```

### Respond to Webhook Node
- **Respond With**: JSON
- **Response Body**:
```json
{
  "model": "{{ $json.body.model }}",
  "created_at": "{{ new Date().toISOString() }}",
  "message": {
    "role": "assistant",
    "content": "{{ $json.output }}"
  },
  "done": true,
  "done_reason": "stop",
  "context": [],
  "total_duration": 0,
  "load_duration": 0,
  "prompt_eval_count": 0,
  "prompt_eval_duration": 0,
  "eval_count": 0,
  "eval_duration": 0
}
```

## 4. Connect Nodes
1. Chat Webhook → AI Agent
2. AI Agent → Set Node
3. Set Node → Respond to Webhook

## 5. Activate & Test
- Save workflow
- Toggle to "Active"
- Copy webhook URLs (you'll see them in each webhook node)
- Test with: `curl -X POST [your-chat-url] -d '{"messages":[{"role":"user","content":"Hello"}]}'` 