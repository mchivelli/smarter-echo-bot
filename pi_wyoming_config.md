# Raspberry Pi Wyoming Satellite Configuration

## Prerequisites
- Wyoming Satellite already installed (as per your tutorial)
- Home Assistant Long-Lived Access Token
- n8n.cloud webhook URLs ready

## 1. Remote Access Options

Since your Pi will connect via mobile hotspot, you have three options:

### Option A: Direct Public Access (Simplest)
**Requirements**: Port forward Home Assistant API (port 8123) on your router

1. **On your router**: Forward external port 8123 to your HA server's internal IP:8123
2. **Get your public IP**: Visit whatismyip.com
3. **Optional**: Set up dynamic DNS (e.g., DuckDNS) if your IP changes

**Wyoming Config URL**: `http://YOUR_PUBLIC_IP:8123/api/assist/converse`

### Option B: Cloudflare Tunnel (Most Secure)
1. Install Cloudflare Tunnel on your HA server:
```bash
# On Windows, download cloudflared.exe
# Create tunnel:
cloudflared tunnel create homeassistant
cloudflared tunnel route dns homeassistant your-subdomain.your-domain.com
```

2. Create config file:
```yaml
tunnel: YOUR_TUNNEL_ID
credentials-file: C:\Users\YourUser\.cloudflared\YOUR_TUNNEL_ID.json

ingress:
  - hostname: your-subdomain.your-domain.com
    service: http://localhost:8123
  - service: http_status:404
```

3. Run tunnel: `cloudflared tunnel run homeassistant`

**Wyoming Config URL**: `https://your-subdomain.your-domain.com/api/assist/converse`

### Option C: VPN (Most Flexible)
Install Tailscale on both Pi and Windows server - then use internal Tailscale IP

## 2. Configure Wyoming HTTP Pipeline

Edit your Wyoming satellite configuration to add HTTP stage:

```yaml
# /home/pi/wyoming-satellite/config.yml
pipeline:
  # Existing wake word detection
  wake:
    uri: tcp://127.0.0.1:10400
    word: "ok_nabu"
  
  # STT stage (existing)
  stt:
    command: "arecord -D plughw:CARD=seeed2micvoicec,DEV=0 -r 16000 -c 1 -f S16_LE -t raw"
  
  # NEW: HTTP stage for Home Assistant
  http:
    name: "Home Assistant Assist"
    url: "YOUR_CHOSEN_URL_FROM_ABOVE"
    method: POST
    headers:
      Authorization: "Bearer YOUR_LONG_LIVED_TOKEN"
      Content-Type: "application/json"
    body_template: |
      {
        "text": "{{ stt.text }}",
        "language": "en",
        "conversation_id": "wyoming_{{ device_id }}"
      }
    response:
      format: json
      speech_path: "response.speech.plain.speech"
      error_path: "error"
    timeout: 10
    retry: 2
  
  # TTS stage (existing) 
  tts:
    command: "aplay -D plughw:CARD=seeed2micvoicec,DEV=0 -r 22050 -c 1 -f S16_LE -t raw"
    input_text: "{{ http.response.speech }}"
```

## 3. Update Wyoming Service

```bash
sudo systemctl edit wyoming-satellite.service
```

Update the ExecStart line to use config file:
```ini
ExecStart=/home/pi/wyoming-satellite/script/run --config /home/pi/wyoming-satellite/config.yml
```

## 4. Configure Home Assistant

### Add Ollama Integration
1. **Settings** → **Integrations** → **Add Integration** → **Ollama**
2. **Host**: Your n8n.cloud base URL (without /chat)
   Example: `https://your-instance.app.n8n.cloud/webhook/abc123`
3. **Port**: 443 (for HTTPS)
4. **Model**: gpt-3.5-turbo

### Set as Conversation Agent
1. **Settings** → **Voice assistants** → **Add Assistant**
2. **Name**: "AI Assistant"
3. **Conversation agent**: Select your Ollama integration
4. **Wake word**: ok_nabu
5. **Speech-to-text**: Your existing STT
6. **Text-to-speech**: Your existing TTS

## 5. Test Commands

Test the full pipeline:

**Basic conversation**:
- "Ok Nabu, what's the weather like?"
- "Ok Nabu, tell me a joke"

**Device control** (once configured in n8n):
- "Ok Nabu, turn on the living room light"
- "Ok Nabu, set bedroom temperature to 22 degrees"
- "Ok Nabu, what's the kitchen light status?"

## 6. Debugging

Check logs on Pi:
```bash
journalctl -u wyoming-satellite -f
```

Check Home Assistant logs:
```
Settings → System → Logs
```

Check n8n execution history in the cloud dashboard

## 7. Performance Optimization

For lowest latency on mobile networks:

1. **Use HTTP/2**: Enable in HA configuration.yaml:
```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - YOUR_ROUTER_IP
  server_port: 8123
```

2. **Optimize n8n workflow**: 
   - Use smaller AI models (gpt-3.5-turbo)
   - Implement response caching for common queries
   - Set timeout limits

3. **Network optimization**:
   - Use 5GHz WiFi when possible
   - Position Pi near router/hotspot
   - Consider USB WiFi adapter with external antenna 