# Complete Implementation Checklist

## ✅ Prerequisites Check
- [ ] Home Assistant running on Windows VM
- [ ] Raspberry Pi with Wyoming Satellite installed
- [ ] n8n.cloud account created
- [ ] OpenAI API key obtained
- [ ] Home Assistant Long-Lived Access Token created

## 📡 Phase 1: Network Setup (30 mins)
- [ ] Choose remote access method:
  - [ ] Option A: Port forwarding + DuckDNS
  - [ ] Option B: Cloudflare Tunnel
  - [ ] Option C: Tailscale VPN
- [ ] Test remote access from phone hotspot
- [ ] Note down public URL/IP for Home Assistant

## 🔧 Phase 2: n8n Workflow Creation (45 mins)
- [ ] Log into n8n.cloud
- [ ] Create new workflow "HA-Assist-Ollama"
- [ ] Add webhooks:
  - [ ] GET /version endpoint
  - [ ] GET /tags endpoint  
  - [ ] POST /chat endpoint
- [ ] Configure basic chat flow:
  - [ ] AI Agent node with OpenAI
  - [ ] Set node for formatting
  - [ ] Respond to Webhook node
- [ ] Test basic chat functionality
- [ ] Copy webhook base URL

## 🎯 Phase 3: Enhanced Device Control (1 hour)
- [ ] Add Switch node after chat webhook
- [ ] Create device control branch:
  - [ ] Function node for parsing commands
  - [ ] HTTP Request node for HA API calls
  - [ ] Set node for success responses
- [ ] Create query branch:
  - [ ] HTTP Request for entity states
  - [ ] AI Agent for interpreting states
- [ ] Update Function node with:
  - [ ] Your HA server IP
  - [ ] Your Long-Lived Token
- [ ] Test device commands

## 🏠 Phase 4: Home Assistant Integration (30 mins)
- [ ] Add Ollama integration:
  - [ ] Host: n8n webhook base URL
  - [ ] Port: 443
  - [ ] Model: gpt-3.5-turbo
- [ ] Create voice assistant:
  - [ ] Name: "AI Assistant"
  - [ ] Conversation agent: Ollama
  - [ ] STT/TTS: Existing
- [ ] Test in HA interface

## 🥧 Phase 5: Raspberry Pi Configuration (45 mins)
- [ ] SSH into Raspberry Pi
- [ ] Create Wyoming config file:
  ```bash
  nano /home/pi/wyoming-satellite/config.yml
  ```
- [ ] Add HTTP pipeline stage with:
  - [ ] Home Assistant public URL
  - [ ] Bearer token
  - [ ] Response parsing paths
- [ ] Update systemd service to use config
- [ ] Restart Wyoming service
- [ ] Check logs for errors

## 🧪 Phase 6: Testing & Validation (30 mins)
- [ ] Test wake word detection: "Ok Nabu"
- [ ] Test conversation:
  - [ ] "What's the weather?"
  - [ ] "Tell me a joke"
  - [ ] "What time is it?"
- [ ] Test device control:
  - [ ] "Turn on living room light"
  - [ ] "Set temperature to 22"
  - [ ] "Is the kitchen light on?"
- [ ] Test on mobile hotspot
- [ ] Measure response latency

## 🚀 Phase 7: Optimization (Optional)
- [ ] Implement command caching in n8n
- [ ] Add error handling nodes
- [ ] Create device name aliases
- [ ] Set up conversation memory:
  - [ ] Add n8n Data Store
  - [ ] Store last 5 messages
  - [ ] Include in AI context
- [ ] Fine-tune audio settings:
  - [ ] Mic gain adjustment
  - [ ] Noise suppression level
  - [ ] Wake word sensitivity

## 📚 Phase 8: Documentation
- [ ] Document all configured values:
  - [ ] Webhook URLs
  - [ ] API tokens
  - [ ] Device mappings
- [ ] Create backup of:
  - [ ] n8n workflow export
  - [ ] Wyoming config.yml
  - [ ] HA configuration
- [ ] Write troubleshooting guide

## 🎉 Completion Checklist
- [ ] Voice commands work from Pi
- [ ] Devices respond to commands
- [ ] AI conversations feel natural
- [ ] Works on mobile hotspot
- [ ] Response time < 2 seconds
- [ ] All services auto-start on boot

## 🐛 Common Issues & Solutions

### Pi can't reach Home Assistant
- Check firewall rules on Windows
- Verify port forwarding/tunnel is active
- Test with curl from Pi

### Ollama integration fails
- Verify all three webhook endpoints
- Check n8n workflow is active
- Test webhooks with Postman

### No audio response
- Check Wyoming TTS pipeline
- Verify audio device settings
- Monitor journalctl logs

### High latency
- Switch to lighter AI model
- Check network connection quality
- Consider local LLM deployment

## 📞 Support Resources
- n8n Community: community.n8n.io
- Home Assistant Forums: community.home-assistant.io
- Wyoming Issues: github.com/rhasspy/wyoming-satellite/issues 