const Anthropic = require('@anthropic-ai/sdk').default;

const PERSONAS = {
  assistant: null,
  coder:
    'You are an expert software engineer with deep knowledge across many languages and frameworks. ' +
    'Give concise, correct, idiomatic code. Always explain the key decision or trade-off behind the solution.',
  writer:
    'You are a sharp writing editor. Cut filler, prefer active voice, and make every sentence earn its place. ' +
    "Give direct feedback. Show, don't tell.",
  tutor:
    'You are a Socratic tutor. Never give the answer directly. ' +
    'Ask one clear, well-chosen question that nudges the student toward the insight themselves.',
};

/**
 * Build the content array for the current user message.
 * If there's an attachment, prepend the appropriate content block before the text.
 *
 * Anthropic content block types:
 *   - image  → base64 image (vision)
 *   - document → base64 PDF
 *   - text  → plain text (also used for code/CSV files)
 */
function buildCurrentMessageContent(text, attachment) {
  const blocks = [];

  if (attachment) {
    const { mediaType, base64Data, kind, filename } = attachment;

    if (kind === 'image') {
      blocks.push({
        type: 'image',
        source: { type: 'base64', media_type: mediaType, data: base64Data },
      });
    } else if (kind === 'pdf') {
      blocks.push({
        type: 'document',
        source: { type: 'base64', media_type: 'application/pdf', data: base64Data },
      });
    } else {
      // text / code file — decode and include as a fenced text block
      const content = Buffer.from(base64Data, 'base64').toString('utf-8');
      blocks.push({
        type: 'text',
        text: `File: ${filename}\n\`\`\`\n${content}\n\`\`\``,
      });
    }
  }

  // Append the user's typed message (may be empty if they only sent a file)
  if (text && text.trim()) {
    blocks.push({ type: 'text', text: text.trim() });
  }

  // If we have exactly one text block and no attachment, the API accepts a plain string
  if (blocks.length === 1 && blocks[0].type === 'text' && !attachment) {
    return blocks[0].text;
  }

  return blocks;
}

exports.handler = async (event) => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  if (event.httpMethod === 'OPTIONS') return { statusCode: 200, headers, body: '' };
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers, body: JSON.stringify({ error: 'Method not allowed' }) };
  }

  try {
    const {
      history = [],
      userMessage = '',
      attachment = null,
      persona = 'assistant',
      model = 'claude-sonnet-4-6',
    } = JSON.parse(event.body);

    const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

    // Build the full messages array: plain-text history + current message with attachment
    const messages = [
      ...history,
      { role: 'user', content: buildCurrentMessageContent(userMessage, attachment) },
    ];

    const params = { model, max_tokens: 2048, messages };
    const systemPrompt = PERSONAS[persona];
    if (systemPrompt) params.system = systemPrompt;

    const response = await client.messages.create(params);

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        content: response.content[0].text,
        inputTokens: response.usage.input_tokens,
        outputTokens: response.usage.output_tokens,
      }),
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: err.message || 'Internal server error' }),
    };
  }
};
