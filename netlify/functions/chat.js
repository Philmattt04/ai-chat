const Anthropic = require('@anthropic-ai/sdk').default;

const PERSONAS = {
  assistant: null,
  coder:
    'You are an expert software engineer with deep knowledge across many languages and frameworks. ' +
    'Give concise, correct, idiomatic code. Always explain the key decision or trade-off briefly.',
  writer:
    'You are a sharp writing editor. Cut filler, prefer active voice, and make every sentence earn its place. ' +
    "Give direct feedback. Show, don't tell.",
  tutor:
    'You are a Socratic tutor. Never give the answer directly. ' +
    'Ask one clear, well-chosen question that nudges the student toward the insight themselves.',
};

exports.handler = async (event) => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers, body: JSON.stringify({ error: 'Method not allowed' }) };
  }

  try {
    const { messages, persona = 'assistant', model = 'claude-sonnet-4-6' } =
      JSON.parse(event.body);

    const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

    const params = {
      model,
      max_tokens: 2048,
      messages,
    };

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
