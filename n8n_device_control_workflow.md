# Enhanced n8n Workflow: AI Conversation + Device Control

## Overview
This enhanced workflow detects Home Assistant commands and executes them while maintaining conversational AI capabilities.

## Additional Nodes Required

### 1. After Chat Webhook - Add Switch Node
**Node Type**: Switch
**Mode**: Rules
**Routing Rules**:

Rule 1 - Device Control Commands:
- **Value 1**: `{{ $json.body.messages[$json.body.messages.length - 1].content }}`
- **Operation**: Contains Regex
- **Value 2**: `(turn on|turn off|switch|set|dim|brightness|temperature|open|close|lock|unlock)\s+(the\s+)?(.*?)\s*(light|lamp|switch|door|lock|cover|climate|fan|scene)`

Rule 2 - Query Commands:
- **Value 1**: `{{ $json.body.messages[$json.body.messages.length - 1].content }}`
- **Operation**: Contains Regex  
- **Value 2**: `(what is|what's|is the|are the|check|status|temperature|humidity|state)`

Rule 3 - Default (Conversation):
- **Fallback Output**: Yes

### 2. Device Control Branch

#### Function Node - Parse Command
**Code**:
```javascript
const command = $json.body.messages[$json.body.messages.length - 1].content.toLowerCase();
const haConfig = {
  url: 'http://YOUR_HA_IP:8123',  // Change this!
  token: 'YOUR_LONG_LIVED_TOKEN'   // Change this!
};

// Parse the command
let action = '';
let entity = '';
let domain = '';
let service = '';
let additionalData = {};

// Detect action
if (command.includes('turn on')) {
  action = 'turn_on';
} else if (command.includes('turn off')) {
  action = 'turn_off';
} else if (command.includes('toggle')) {
  action = 'toggle';
} else if (command.includes('set') && command.includes('brightness')) {
  action = 'turn_on';
  const match = command.match(/(\d+)%?/);
  if (match) {
    additionalData.brightness_pct = parseInt(match[1]);
  }
} else if (command.includes('set') && command.includes('temperature')) {
  action = 'set_temperature';
  const match = command.match(/(\d+)/);
  if (match) {
    additionalData.temperature = parseInt(match[1]);
  }
}

// Detect entity type and name
const entityMatch = command.match(/(.*?)\s*(light|lamp|switch|climate|fan|cover|lock|scene)/);
if (entityMatch) {
  const entityName = entityMatch[1].replace(/(turn on|turn off|set|the)/g, '').trim();
  domain = entityMatch[2] === 'lamp' ? 'light' : entityMatch[2];
  
  // Convert natural name to entity_id format
  entity = `${domain}.${entityName.replace(/\s+/g, '_').toLowerCase()}`;
}

// Map domain to service
if (domain === 'light' || domain === 'switch' || domain === 'fan') {
  service = action;
} else if (domain === 'climate') {
  service = action === 'set_temperature' ? 'set_temperature' : 'turn_on';
} else if (domain === 'cover') {
  service = action === 'turn_on' ? 'open_cover' : 'close_cover';
} else if (domain === 'lock') {
  service = action === 'turn_on' ? 'unlock' : 'lock';
} else if (domain === 'scene') {
  service = 'turn_on';
}

return {
  json: {
    haConfig,
    domain,
    service,
    entity_id: entity,
    command: command,
    serviceData: {
      entity_id: entity,
      ...additionalData
    }
  }
};
```

#### HTTP Request Node - Call HA API
- **Method**: POST
- **URL**: `{{ $json.haConfig.url }}/api/services/{{ $json.domain }}/{{ $json.service }}`
- **Authentication**: Generic Credential Type
  - **Generic Auth Type**: Header Auth
  - **Header Auth:
    - **Name**: Authorization
    - **Value**: `Bearer {{ $json.haConfig.token }}`
- **Send Headers**:
  - **Name**: Content-Type
  - **Value**: application/json
- **Send Body**: JSON
- **Body**:
```json
{{ $json.serviceData }}
```

#### Set Node - Format Success Response
- **Field**: output
- **Value**: 
```javascript
{{ 
  $json.service.includes('turn_on') ? `I've turned on the ${$json.entity_id.split('.')[1].replace(/_/g, ' ')} for you.` :
  $json.service.includes('turn_off') ? `I've turned off the ${$json.entity_id.split('.')[1].replace(/_/g, ' ')}.` :
  $json.service.includes('set_temperature') ? `I've set the temperature to ${$json.serviceData.temperature} degrees.` :
  $json.service.includes('open') ? `I've opened the ${$json.entity_id.split('.')[1].replace(/_/g, ' ')}.` :
  $json.service.includes('close') ? `I've closed the ${$json.entity_id.split('.')[1].replace(/_/g, ' ')}.` :
  `I've executed the ${$json.service} command on ${$json.entity_id.split('.')[1].replace(/_/g, ' ')}.`
}}
```

### 3. Query Branch

#### HTTP Request Node - Get Entity State
- **Method**: GET
- **URL**: `{{ $json.haConfig.url }}/api/states/{{ $json.entity_id }}`
- **Authentication**: Same as above
- **Parse JSON**: Yes

#### AI Agent Node - Interpret State
- **System Message**:
```
You are a Home Assistant voice assistant. The user asked about a device state. 
Interpret the JSON data and respond conversationally. Include the current state, 
any relevant attributes (like temperature, brightness), and make it sound natural.
```
- **User Message**:
```
User asked: {{ $json.command }}
Device data: {{ JSON.stringify($json) }}
```

### 4. Merge All Branches
All three branches (device control, query, conversation) should connect to the same "Respond to Webhook" node at the end.

## Complete Node Flow
```
[Chat Webhook]
      ↓
[Switch Node] ──→ [Device Control] → [Parse] → [HA API] → [Format Response] ↘
      ├─────────→ [Query State] → [Get State] → [AI Interpret] ──────────────→ [Respond to Webhook]
      └─────────→ [AI Conversation] → [Set Fields] ─────────────────────────↗
```

## Configuration Steps
1. Replace `YOUR_HA_IP` with your Home Assistant IP (e.g., 192.168.1.100)
2. Replace `YOUR_LONG_LIVED_TOKEN` with your HA token
3. Save and activate the workflow
4. Test with commands like:
   - "Turn on the living room light"
   - "What's the temperature in the bedroom?"
   - "Set kitchen light brightness to 50%"
   - "Tell me a joke" 