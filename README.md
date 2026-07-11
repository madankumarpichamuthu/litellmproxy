# LiteLLM Proxy for Bootcamp Students

This project provides a lightweight, classroom-safe API proxy powered by LiteLLM. It exposes a single model alias, `class-chat-model`, which routes to Google's Gemini `gemini-flash-lite-latest` model through the LiteLLM proxy server.

## Features

- Uses the built-in LiteLLM proxy server
- Protects access with a master key
- Reads the real Gemini API key from a `.env` file
- Works well for frontend JavaScript apps using `fetch()`

## 1. Prerequisites

- Python 3.10+
- A Gemini API key
- Optional: Docker for container deployment

## 2. Setup locally

1. Create and activate a virtual environment:

   ```bash
   python -m venv .venv
   source .venv/bin/activate
   ```

2. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

3. Create a `.env` file from the example:

   ```bash
   cp .env.example .env
   ```

4. Edit `.env` and add your real Gemini API key:

   ```env
   GEMINI_API_KEY=your_real_gemini_api_key_here
   ```

## 3. Run the proxy

Start the proxy with the built-in LiteLLM CLI:

```bash
litellm --config config.yaml --host 0.0.0.0 --port 4000
```

The server will be available at:

```text
http://127.0.0.1:4000
```

## 4. Test the endpoint

Use `curl` with the master key:

```bash
curl http://127.0.0.1:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-vibe-summer-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "class-chat-model",
    "messages": [{"role": "user", "content": "Say hello from the bootcamp proxy."}]
  }'
```

## 5. Frontend usage example

Students can call the proxy from JavaScript like this:

```javascript
const response = await fetch('http://127.0.0.1:4000/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer sk-vibe-summer-2026',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: 'class-chat-model',
    messages: [{ role: 'user', content: 'Help me with my coding assignment.' }]
  })
});

const data = await response.json();
console.log(data);
```

## 6. GitHub Pages frontend demo

Students can open the included [index.html](index.html) file directly in a browser, or host the repository on GitHub Pages.

Before using the app, replace the placeholder URL in [index.html](index.html) with your deployed Render or Railway proxy URL:

```javascript
https://YOUR_RENDER_PROXY_URL/v1/chat/completions
```

Then the app will send requests using:

- the shared master key: `sk-vibe-summer-2026`
- the shared model alias: `class-chat-model`

## 7. Docker deployment

Build the image:

```bash
docker build -t litellm-proxy .
```

Run the container:

```bash
docker run -p 4000:4000 --env-file .env litellm-proxy
```

This container uses port `4000` by default, which is suitable for Render or Railway.
