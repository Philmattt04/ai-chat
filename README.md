# Vox AI

Four AI voices, one app. A Flutter chat application powered by Claude (Anthropic) with four independent AI personas — each with its own dedicated conversation history. Built by **Philippe Mathieu**.

**Live:** https://ai-chat-flutter.netlify.app

---

## How It Works

Vox AI gives you four specialized Claude personas to choose from. Each persona has a distinct system prompt that shapes how Claude responds — its tone, focus, and approach. Switching between personas doesn't mix conversations: each one maintains its own independent chat history, so you can have a coding discussion with Coder while a writing session with Writer stays exactly where you left it.

Every conversation is backed by a Netlify serverless function that proxies requests to the Anthropic API, keeping your API key server-side and out of the browser. You can toggle between Claude Haiku (fast, cost-efficient) and Claude Sonnet (more capable) at any time, and a token counter tracks usage for the active persona.

---

## Personas

### 🤖 Assistant
The default, no-system-prompt Claude. Balanced, helpful, and thorough — best for general questions, research, or anything that doesn't fit the other modes.

### 💻 Coder
An expert software engineer with deep knowledge across languages and frameworks. Gives concise, correct, idiomatic code and always explains the key decision or trade-off behind the solution.

### ✍️ Writer
A sharp writing editor focused on clarity and directness. Cuts filler, prefers active voice, and makes every sentence earn its place. Gives direct feedback rather than flattery.

### 🧠 Tutor
A Socratic teacher who never gives the answer directly. Instead, asks one well-chosen question designed to nudge you toward the insight yourself. Best for learning concepts rather than getting quick answers.

---

## Example Prompts

### 🤖 Assistant
- "What's the difference between TCP and UDP, and when would you choose each?"
- "Summarize the key ideas behind the CAP theorem."
- "What are the pros and cons of microservices vs. a monolith?"

### 💻 Coder
- "I have a list of 10,000 user objects and need to find duplicates by email. Most efficient approach in TypeScript?"
- "Review this function and tell me what's wrong with it." *(paste code)*
- "What's the difference between `useMemo` and `useCallback` in React, and when does it actually matter?"
- "Write a rate limiter in Node.js using a sliding window algorithm."

### ✍️ Writer
- "Here's my LinkedIn bio — make it tighter and more direct." *(paste text)*
- "Edit this paragraph. Don't hold back." *(paste paragraph)*
- "I need to write a cold email to a potential client. Here's my draft:" *(paste draft)*
- "Rewrite this in plain English." *(paste jargon-heavy text)*

### 🧠 Tutor
- "I want to understand why async/await exists. I know callbacks and Promises but the connection isn't clicking."
- "I'm learning Big O notation but I don't get why O(n²) is so much worse than O(n log n) in practice."
- "Explain recursion to me — I keep losing track of the call stack."
- "I understand what a React hook is but I don't understand *why* they replaced class components."

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (web, iOS, Android) |
| UI | Material 3, Google Fonts (Inter), flutter_markdown |
| Backend | Netlify Functions (Node.js) |
| AI | Anthropic SDK — Claude Sonnet 4.6 / Haiku 4.5 |

---

## Getting Started

### Prerequisites
- Flutter ≥ 3.16
- A Netlify account
- An Anthropic API key from [console.anthropic.com](https://console.anthropic.com)

### Run locally

```bash
git clone https://github.com/Philmattt04/ai-chat.git
cd ai-chat
flutter pub get
```

Install Netlify CLI and run the dev server (proxies the function at port 8888):

```bash
npm install -g netlify-cli
netlify dev
```

Open `http://localhost:8888` in your browser.

### Deploy to Netlify

```bash
flutter build web --release
netlify deploy --dir=build/web --functions=netlify/functions --prod
```

Set `ANTHROPIC_API_KEY` in your Netlify site's environment variables.
