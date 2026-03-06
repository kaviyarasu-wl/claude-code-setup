---
name: n8n
description: Build and debug n8n workflows. Use for creating automations, webhook handlers, API integrations, and workflow troubleshooting.
allowed-tools: Read, Grep, Glob, Write, Edit, WebFetch
---

# n8n Workflow Skill

## Overview

Design and build n8n automation workflows for integrations, data processing, and business automation. Covers webhooks, API calls, code nodes, error handling, and debugging.

## Workflow Structure

### Basic JSON Structure

```json
{
  "name": "My Workflow",
  "nodes": [
    {
      "parameters": {},
      "id": "unique-id",
      "name": "Node Name",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [250, 300]
    }
  ],
  "connections": {
    "Node Name": {
      "main": [
        [
          {
            "node": "Next Node",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "settings": {
    "executionOrder": "v1"
  }
}
```

## Common Node Patterns

### Webhook Trigger

```json
{
  "parameters": {
    "httpMethod": "POST",
    "path": "order-webhook",
    "responseMode": "responseNode",
    "options": {
      "rawBody": true
    }
  },
  "name": "Webhook",
  "type": "n8n-nodes-base.webhook",
  "typeVersion": 2,
  "position": [250, 300],
  "webhookId": "unique-webhook-id"
}
```

**Webhook Response Node:**
```json
{
  "parameters": {
    "respondWith": "json",
    "responseBody": "={{ JSON.stringify({ success: true, id: $json.id }) }}",
    "options": {
      "responseCode": 200,
      "responseHeaders": {
        "entries": [
          {
            "name": "Content-Type",
            "value": "application/json"
          }
        ]
      }
    }
  },
  "name": "Respond to Webhook",
  "type": "n8n-nodes-base.respondToWebhook",
  "typeVersion": 1
}
```

### HTTP Request

```json
{
  "parameters": {
    "method": "POST",
    "url": "https://api.example.com/orders",
    "authentication": "predefinedCredentialType",
    "nodeCredentialType": "httpHeaderAuth",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {
          "name": "Content-Type",
          "value": "application/json"
        }
      ]
    },
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={{ JSON.stringify($json) }}",
    "options": {
      "timeout": 30000,
      "response": {
        "response": {
          "fullResponse": true
        }
      }
    }
  },
  "name": "Create Order API",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2
}
```

### Code Node (JavaScript)

```json
{
  "parameters": {
    "mode": "runOnceForAllItems",
    "jsCode": "// Transform and validate data\nconst items = $input.all();\n\nconst processed = items.map(item => {\n  const data = item.json;\n  \n  return {\n    json: {\n      orderId: data.id,\n      customerEmail: data.customer.email.toLowerCase(),\n      total: parseFloat(data.total).toFixed(2),\n      items: data.line_items.map(li => ({\n        sku: li.sku,\n        quantity: li.quantity,\n        price: li.price\n      })),\n      processedAt: new Date().toISOString()\n    }\n  };\n});\n\nreturn processed;"
  },
  "name": "Transform Order Data",
  "type": "n8n-nodes-base.code",
  "typeVersion": 2
}
```

### Code Node (Python)

```json
{
  "parameters": {
    "mode": "runOnceForAllItems",
    "language": "python",
    "pythonCode": "import json\nfrom datetime import datetime\n\nitems = []\nfor item in _input.all():\n    data = item.json\n    \n    processed = {\n        'order_id': data['id'],\n        'customer_email': data['customer']['email'].lower(),\n        'total': f\"{float(data['total']):.2f}\",\n        'processed_at': datetime.now().isoformat()\n    }\n    \n    items.append({'json': processed})\n\nreturn items"
  },
  "name": "Python Transform",
  "type": "n8n-nodes-base.code",
  "typeVersion": 2
}
```

### IF Condition

```json
{
  "parameters": {
    "conditions": {
      "options": {
        "caseSensitive": true,
        "leftValue": "",
        "typeValidation": "strict"
      },
      "conditions": [
        {
          "id": "condition-1",
          "leftValue": "={{ $json.status }}",
          "rightValue": "paid",
          "operator": {
            "type": "string",
            "operation": "equals"
          }
        }
      ],
      "combinator": "and"
    },
    "options": {}
  },
  "name": "Is Paid?",
  "type": "n8n-nodes-base.if",
  "typeVersion": 2
}
```

### Switch (Multiple Conditions)

```json
{
  "parameters": {
    "mode": "rules",
    "rules": {
      "values": [
        {
          "conditions": {
            "conditions": [
              {
                "leftValue": "={{ $json.priority }}",
                "rightValue": "high",
                "operator": {
                  "type": "string",
                  "operation": "equals"
                }
              }
            ]
          },
          "renameOutput": true,
          "outputKey": "High Priority"
        },
        {
          "conditions": {
            "conditions": [
              {
                "leftValue": "={{ $json.priority }}",
                "rightValue": "medium",
                "operator": {
                  "type": "string",
                  "operation": "equals"
                }
              }
            ]
          },
          "renameOutput": true,
          "outputKey": "Medium Priority"
        }
      ]
    },
    "options": {
      "fallbackOutput": "extra"
    }
  },
  "name": "Route by Priority",
  "type": "n8n-nodes-base.switch",
  "typeVersion": 3
}
```

### Loop Over Items

```json
{
  "parameters": {
    "options": {}
  },
  "name": "Loop Over Items",
  "type": "n8n-nodes-base.splitInBatches",
  "typeVersion": 3
}
```

### Merge Branches

```json
{
  "parameters": {
    "mode": "combine",
    "mergeByFields": {
      "values": [
        {
          "field1": "id",
          "field2": "order_id"
        }
      ]
    },
    "options": {}
  },
  "name": "Merge Data",
  "type": "n8n-nodes-base.merge",
  "typeVersion": 3
}
```

## Error Handling

### Error Trigger Workflow

```json
{
  "nodes": [
    {
      "parameters": {},
      "name": "Error Trigger",
      "type": "n8n-nodes-base.errorTrigger",
      "typeVersion": 1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "channel": "#alerts",
        "text": "=Workflow Error!\n\nWorkflow: {{ $json.workflow.name }}\nNode: {{ $json.execution.error.node.name }}\nError: {{ $json.execution.error.message }}\n\nExecution ID: {{ $json.execution.id }}",
        "otherOptions": {}
      },
      "name": "Slack Alert",
      "type": "n8n-nodes-base.slack",
      "typeVersion": 2.2
    }
  ]
}
```

### Try/Catch with Continue on Fail

```json
{
  "parameters": {
    "url": "https://api.example.com/risky-endpoint",
    "options": {
      "timeout": 5000
    }
  },
  "name": "Risky API Call",
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2,
  "onError": "continueRegularOutput",
  "continueOnFail": true
}
```

Then handle in Code node:
```javascript
const items = $input.all();

return items.map(item => {
  if (item.error) {
    return {
      json: {
        success: false,
        error: item.error.message,
        fallbackData: getDefault()
      }
    };
  }
  return item;
});
```

## Common Integrations

### Slack Notification

```json
{
  "parameters": {
    "resource": "message",
    "operation": "post",
    "channel": {
      "__rl": true,
      "value": "#general",
      "mode": "name"
    },
    "text": "=New order received!\n\nOrder ID: {{ $json.orderId }}\nCustomer: {{ $json.customerEmail }}\nTotal: ${{ $json.total }}",
    "otherOptions": {
      "includeLinkToWorkflow": false
    }
  },
  "name": "Slack",
  "type": "n8n-nodes-base.slack",
  "typeVersion": 2.2,
  "credentials": {
    "slackApi": {
      "id": "1",
      "name": "Slack account"
    }
  }
}
```

### Google Sheets Append

```json
{
  "parameters": {
    "operation": "append",
    "documentId": {
      "__rl": true,
      "value": "spreadsheet-id",
      "mode": "id"
    },
    "sheetName": {
      "__rl": true,
      "value": "Sheet1",
      "mode": "name"
    },
    "columns": {
      "mappingMode": "autoMapInputData",
      "value": {}
    },
    "options": {}
  },
  "name": "Google Sheets",
  "type": "n8n-nodes-base.googleSheets",
  "typeVersion": 4.4,
  "credentials": {
    "googleSheetsOAuth2Api": {
      "id": "2",
      "name": "Google Sheets account"
    }
  }
}
```

### Send Email (Gmail)

```json
{
  "parameters": {
    "sendTo": "={{ $json.customerEmail }}",
    "subject": "Order Confirmation #{{ $json.orderId }}",
    "emailType": "html",
    "message": "=<h1>Thank you for your order!</h1><p>Order ID: {{ $json.orderId }}</p><p>Total: ${{ $json.total }}</p>",
    "options": {}
  },
  "name": "Gmail",
  "type": "n8n-nodes-base.gmail",
  "typeVersion": 2.1,
  "credentials": {
    "gmailOAuth2": {
      "id": "3",
      "name": "Gmail account"
    }
  }
}
```

## Data Transformation Patterns

### Flatten Nested Object

```javascript
// Code node
const items = $input.all();

return items.map(item => {
  const data = item.json;

  return {
    json: {
      id: data.id,
      customerName: data.customer.name,
      customerEmail: data.customer.email,
      shippingStreet: data.shipping.address.street,
      shippingCity: data.shipping.address.city,
    }
  };
});
```

### Aggregate/Group Data

```javascript
// Code node - runOnceForAllItems
const items = $input.all();

// Group by status
const grouped = items.reduce((acc, item) => {
  const status = item.json.status;
  if (!acc[status]) acc[status] = [];
  acc[status].push(item.json);
  return acc;
}, {});

// Return as separate items
return Object.entries(grouped).map(([status, orders]) => ({
  json: {
    status,
    count: orders.length,
    totalValue: orders.reduce((sum, o) => sum + o.total, 0),
    orders
  }
}));
```

### Filter and Deduplicate

```javascript
// Code node
const items = $input.all();
const seen = new Set();

const unique = items.filter(item => {
  const key = item.json.email.toLowerCase();
  if (seen.has(key)) return false;
  seen.add(key);
  return true;
});

return unique;
```

## Debugging Tips

1. **Use Set node** to inspect data at any point
2. **Check execution history** for error details
3. **Enable "Save execution progress"** for long workflows
4. **Use Code node** with `console.log()` for debugging
5. **Test webhooks** with RequestBin or webhook.site

## Workflow Design Best Practices

- [ ] Start with Webhook or Schedule trigger
- [ ] Validate input data early
- [ ] Handle errors with Error Trigger workflow
- [ ] Use descriptive node names
- [ ] Add notes for complex logic
- [ ] Test with small dataset first
- [ ] Use credentials, never hardcode secrets

## Usage

```
/n8n webhook-to-slack     # Create webhook that posts to Slack
/n8n shopify-to-sheets    # Shopify orders to Google Sheets
/n8n form-to-email        # Form submission to email
/n8n api-sync             # Sync between two APIs
/n8n debug "workflow.json" # Debug existing workflow
```
