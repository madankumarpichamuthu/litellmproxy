# Image & Video Generation Models Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two new shared model aliases — `class-image-model` (Imagen 4 via Gemini) and `class-video-model` (Veo 3 via Vertex AI) — so bootcamp students can generate images and videos through the same proxy they already use for chat.

**Architecture:** Extend `config.yaml` with two new model entries using existing `GEMINI_API_KEY` for images and new Vertex AI credentials for video. Update `.env.example` with the new required vars. Update `index.html` with two new UI panels (one for image generation, one for video generation) that call the correct proxy endpoints. No new server code needed — LiteLLM handles both `/v1/images/generations` and `/v1/videos/generations` natively.

**Tech Stack:** LiteLLM proxy (already installed), Google AI Studio Imagen 4 (`gemini/imagen-4.0-generate-001`), Vertex AI Veo 3 (`vertex_ai/veo-3.0-generate-preview`), vanilla HTML/CSS/JS.

---

## File Map

| File | Change |
|---|---|
| `config.yaml` | Add `class-image-model` and `class-video-model` entries |
| `.env.example` | Add `VERTEXAI_PROJECT`, `VERTEXAI_LOCATION`, `VERTEXAI_CREDENTIALS` |
| `index.html` | Add Image tab and Video tab to the existing UI |
| `README.md` | Document new endpoints, env vars, and student usage examples |

---

### Task 1: Add image generation model to config.yaml

**Files:**
- Modify: `config.yaml`

- [ ] **Step 1: Open config.yaml and add the image model entry**

Replace the entire file with:

```yaml
model_list:
  - model_name: class-chat-model
    litellm_params:
      model: gemini/gemini-3.1-flash-lite
      api_key: os.environ/GEMINI_API_KEY

  - model_name: class-image-model
    litellm_params:
      model: gemini/imagen-4.0-generate-001
      api_key: os.environ/GEMINI_API_KEY
    model_info:
      mode: image_generation

  - model_name: class-video-model
    litellm_params:
      model: vertex_ai/veo-3.0-generate-preview
      vertex_project: os.environ/VERTEXAI_PROJECT
      vertex_location: os.environ/VERTEXAI_LOCATION
      vertex_credentials: os.environ/VERTEXAI_CREDENTIALS
    model_info:
      mode: video_generation

general_settings:
  master_key: sk-vibe-summer-2026
```

- [ ] **Step 2: Smoke-test image endpoint manually (proxy must be running)**

```bash
litellm --config config.yaml --host 0.0.0.0 --port 4000
```

Then in another terminal:

```bash
curl http://127.0.0.1:4000/v1/images/generations \
  -H "Authorization: Bearer sk-vibe-summer-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "class-image-model",
    "prompt": "A cartoon cat sitting on a cloud",
    "n": 1,
    "size": "1024x1024"
  }'
```

Expected: JSON response with `data[0].url` or `data[0].b64_json` containing the image.

- [ ] **Step 3: Commit**

```bash
git add config.yaml
git commit -m "feat: add class-image-model (Imagen 4) and class-video-model (Veo 3) to proxy config"
```

---

### Task 2: Update .env.example with Vertex AI credentials

**Files:**
- Modify: `.env.example`

- [ ] **Step 1: Add Vertex AI vars to .env.example**

Replace the entire file with:

```env
# Required for chat and image generation
GEMINI_API_KEY=your_gemini_api_key_here

# Required for video generation (Vertex AI / Veo)
# Get these from your Google Cloud project
VERTEXAI_PROJECT=your-gcp-project-id
VERTEXAI_LOCATION=us-central1
# Base64-encoded service account JSON, or path to the JSON file
VERTEXAI_CREDENTIALS=your_base64_encoded_service_account_json
```

- [ ] **Step 2: Commit**

```bash
git add .env.example
git commit -m "docs: add Vertex AI env vars to .env.example for video generation"
```

---

### Task 3: Add Image Generation tab to index.html

**Files:**
- Modify: `index.html`

- [ ] **Step 1: Replace index.html with a tabbed version adding an Image tab**

The current single-page chat UI needs a tab bar. Replace the full file content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Cloud Class AI</title>
  <style>
    :root {
      --bg: #0f172a;
      --panel: #111827;
      --accent: #8b5cf6;
      --accent-2: #38bdf8;
      --text: #f8fafc;
      --muted: #cbd5e1;
      --bubble: #1f2937;
      --bubble-user: #4f46e5;
    }

    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "Trebuchet MS", "Segoe UI", sans-serif;
      background: linear-gradient(135deg, var(--bg), #1e293b);
      color: var(--text);
      display: flex;
      justify-content: center;
      align-items: flex-start;
      min-height: 100vh;
      padding: 20px;
    }

    .app {
      width: min(900px, 100%);
      background: rgba(17, 24, 39, 0.96);
      border: 3px solid rgba(255,255,255,0.12);
      border-radius: 24px;
      overflow: hidden;
      box-shadow: 0 20px 50px rgba(0,0,0,0.35);
    }

    .header {
      padding: 20px 24px;
      background: linear-gradient(90deg, var(--accent), var(--accent-2));
      color: white;
    }
    .header h1 { margin: 0 0 6px; font-size: 1.4rem; }
    .header p { margin: 0; color: #eef2ff; }

    /* Tab bar */
    .tabs {
      display: flex;
      background: #0b1220;
      border-bottom: 1px solid rgba(255,255,255,0.1);
    }
    .tab-btn {
      flex: 1;
      padding: 14px;
      background: none;
      border: none;
      border-bottom: 3px solid transparent;
      color: var(--muted);
      font-size: 1rem;
      font-weight: 600;
      cursor: pointer;
      transition: color 0.2s, border-color 0.2s;
    }
    .tab-btn.active {
      color: var(--text);
      border-bottom-color: var(--accent);
    }
    .tab-btn:hover { color: var(--text); }

    /* Tab panels */
    .tab-panel { display: none; }
    .tab-panel.active { display: block; }

    /* ── Chat panel ── */
    .chat-area {
      height: 440px;
      overflow-y: auto;
      padding: 20px;
      background: #0b1220;
    }
    .message { margin-bottom: 14px; display: flex; flex-direction: column; gap: 6px; }
    .message.user { align-items: flex-end; }
    .message.bot  { align-items: flex-start; }
    .bubble {
      max-width: 80%;
      padding: 12px 14px;
      border-radius: 16px;
      line-height: 1.45;
      white-space: pre-wrap;
      word-wrap: break-word;
    }
    .message.user .bubble { background: var(--bubble-user); color: white; border-bottom-right-radius: 4px; }
    .message.bot  .bubble { background: var(--bubble); color: var(--text); border-bottom-left-radius: 4px; }
    .meta { font-size: 0.8rem; color: var(--muted); }

    /* ── Image panel ── */
    .image-panel-body {
      padding: 24px;
      background: #0b1220;
      min-height: 300px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .image-result {
      display: flex;
      flex-wrap: wrap;
      gap: 12px;
      min-height: 200px;
      align-items: center;
      justify-content: center;
    }
    .image-result img {
      max-width: 100%;
      border-radius: 12px;
      border: 2px solid rgba(255,255,255,0.1);
    }
    .image-placeholder {
      color: var(--muted);
      font-size: 0.95rem;
      text-align: center;
    }

    /* ── Video panel ── */
    .video-panel-body {
      padding: 24px;
      background: #0b1220;
      min-height: 300px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .video-result {
      display: flex;
      flex-wrap: wrap;
      gap: 12px;
      min-height: 200px;
      align-items: center;
      justify-content: center;
    }
    .video-result video {
      max-width: 100%;
      border-radius: 12px;
      border: 2px solid rgba(255,255,255,0.1);
      controls: true;
    }
    .video-placeholder {
      color: var(--muted);
      font-size: 0.95rem;
      text-align: center;
    }

    /* ── Shared composer ── */
    .composer {
      display: flex;
      gap: 10px;
      padding: 16px;
      background: var(--panel);
      border-top: 1px solid rgba(255,255,255,0.12);
    }
    input[type="text"] {
      flex: 1;
      padding: 12px 14px;
      border: 0;
      border-radius: 999px;
      font-size: 1rem;
      outline: none;
      background: #1f2937;
      color: var(--text);
    }
    button.send-btn {
      border: 0;
      padding: 12px 16px;
      border-radius: 999px;
      background: linear-gradient(90deg, var(--accent), var(--accent-2));
      color: white;
      cursor: pointer;
      font-weight: 700;
    }
    button.send-btn:hover { transform: translateY(-1px); }
    .hint {
      padding: 0 16px 16px;
      color: var(--muted);
      font-size: 0.92rem;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="app">
    <div class="header">
      <h1>🌈 Cloud Class AI</h1>
      <p>Chat, create images, and generate videos — all powered by our class proxy!</p>
    </div>

    <!-- Tab bar -->
    <div class="tabs">
      <button class="tab-btn active" data-tab="chat">💬 Chat</button>
      <button class="tab-btn" data-tab="image">🖼️ Image</button>
      <button class="tab-btn" data-tab="video">🎬 Video</button>
    </div>

    <!-- ── Chat tab ── -->
    <div id="tab-chat" class="tab-panel active">
      <div class="chat-area" id="chatArea"></div>
      <div class="composer">
        <input id="chatInput" type="text" placeholder="Type your question here..." />
        <button class="send-btn" id="chatSendBtn">Send 🚀</button>
      </div>
      <div class="hint">Tip: Ask for help with homework, coding, or a fun story.</div>
    </div>

    <!-- ── Image tab ── -->
    <div id="tab-image" class="tab-panel">
      <div class="image-panel-body">
        <div class="image-result" id="imageResult">
          <span class="image-placeholder">Your generated image will appear here ✨</span>
        </div>
      </div>
      <div class="composer">
        <input id="imageInput" type="text" placeholder="Describe the image you want..." />
        <button class="send-btn" id="imageSendBtn">Generate 🎨</button>
      </div>
      <div class="hint">Tip: Be descriptive — "a cartoon robot reading a book in a cozy library"</div>
    </div>

    <!-- ── Video tab ── -->
    <div id="tab-video" class="tab-panel">
      <div class="video-panel-body">
        <div class="video-result" id="videoResult">
          <span class="video-placeholder">Your generated video will appear here 🎬</span>
        </div>
      </div>
      <div class="composer">
        <input id="videoInput" type="text" placeholder="Describe the video you want..." />
        <button class="send-btn" id="videoSendBtn">Generate 🎬</button>
      </div>
      <div class="hint">Tip: "A time-lapse of clouds moving over mountains at sunset" — keep it short and visual.</div>
    </div>
  </div>

  <script>
    const PROXY_URL = 'https://vibe-proxy-gqv4.onrender.com';
    const API_KEY   = 'Bearer sk-vibe-summer-2026';

    // ── Tab switching ──
    document.querySelectorAll('.tab-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById(`tab-${btn.dataset.tab}`).classList.add('active');
      });
    });

    // === TEACHER'S MAGIC CODE — Chat ===
    const chatArea = document.getElementById('chatArea');

    async function askAI(message) {
      const response = await fetch(`${PROXY_URL}/v1/chat/completions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': API_KEY },
        body: JSON.stringify({
          model: 'class-chat-model',
          messages: [{ role: 'user', content: message }]
        })
      });
      const data = await response.json();
      return data.choices?.[0]?.message?.content || 'Oops! The AI had no reply.';
    }

    // === TEACHER'S MAGIC CODE — Image generation ===
    async function generateImage(prompt) {
      const response = await fetch(`${PROXY_URL}/v1/images/generations`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': API_KEY },
        body: JSON.stringify({
          model: 'class-image-model',
          prompt: prompt,
          n: 1,
          size: '1024x1024'
        })
      });
      const data = await response.json();
      // LiteLLM returns either a URL or base64 depending on the provider
      const item = data.data?.[0];
      if (!item) throw new Error('No image in response');
      return item.url || `data:image/png;base64,${item.b64_json}`;
    }

    // === TEACHER'S MAGIC CODE — Video generation ===
    async function generateVideo(prompt) {
      const response = await fetch(`${PROXY_URL}/v1/videos/generations`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': API_KEY },
        body: JSON.stringify({
          model: 'class-video-model',
          prompt: prompt,
          seconds: '8',
          size: '1280x720'
        })
      });
      const data = await response.json();
      const item = data.data?.[0];
      if (!item) throw new Error('No video in response');
      return item.url || `data:video/mp4;base64,${item.b64_video}`;
    }

    // === KIDS UI CODE — Chat ===
    function addMessage(text, role) {
      const row = document.createElement('div');
      row.className = `message ${role}`;
      const bubble = document.createElement('div');
      bubble.className = 'bubble';
      bubble.textContent = text;
      const meta = document.createElement('div');
      meta.className = 'meta';
      meta.textContent = role === 'user' ? 'You' : 'AI Buddy';
      row.appendChild(bubble);
      row.appendChild(meta);
      chatArea.appendChild(row);
      chatArea.scrollTop = chatArea.scrollHeight;
    }

    async function sendChatMessage() {
      const message = document.getElementById('chatInput').value.trim();
      if (!message) return;
      addMessage(message, 'user');
      document.getElementById('chatInput').value = '';
      addMessage('Thinking... ✨', 'bot');
      try {
        const reply = await askAI(message);
        chatArea.lastChild.remove();
        addMessage(reply, 'bot');
      } catch (error) {
        chatArea.lastChild.remove();
        addMessage('Something went wrong. Check the proxy URL and key.', 'bot');
        console.error(error);
      }
    }

    document.getElementById('chatSendBtn').addEventListener('click', sendChatMessage);
    document.getElementById('chatInput').addEventListener('keydown', e => { if (e.key === 'Enter') sendChatMessage(); });
    addMessage('Hi! I am your classroom AI helper. Ask me anything! 🌟', 'bot');

    // === KIDS UI CODE — Image ===
    async function sendImageRequest() {
      const prompt = document.getElementById('imageInput').value.trim();
      if (!prompt) return;
      const result = document.getElementById('imageResult');
      result.innerHTML = '<span class="image-placeholder">Generating your image... 🎨</span>';
      document.getElementById('imageSendBtn').disabled = true;
      try {
        const imgSrc = await generateImage(prompt);
        result.innerHTML = '';
        const img = document.createElement('img');
        img.src = imgSrc;
        img.alt = prompt;
        result.appendChild(img);
      } catch (error) {
        result.innerHTML = '<span class="image-placeholder">Something went wrong. Check the proxy and try again.</span>';
        console.error(error);
      } finally {
        document.getElementById('imageSendBtn').disabled = false;
      }
    }

    document.getElementById('imageSendBtn').addEventListener('click', sendImageRequest);
    document.getElementById('imageInput').addEventListener('keydown', e => { if (e.key === 'Enter') sendImageRequest(); });

    // === KIDS UI CODE — Video ===
    async function sendVideoRequest() {
      const prompt = document.getElementById('videoInput').value.trim();
      if (!prompt) return;
      const result = document.getElementById('videoResult');
      result.innerHTML = '<span class="video-placeholder">Generating your video... this takes ~30 seconds 🎬</span>';
      document.getElementById('videoSendBtn').disabled = true;
      try {
        const videoSrc = await generateVideo(prompt);
        result.innerHTML = '';
        const vid = document.createElement('video');
        vid.src = videoSrc;
        vid.controls = true;
        vid.autoplay = true;
        vid.loop = true;
        vid.style.maxWidth = '100%';
        result.appendChild(vid);
      } catch (error) {
        result.innerHTML = '<span class="video-placeholder">Something went wrong. Check the proxy and try again.</span>';
        console.error(error);
      } finally {
        document.getElementById('videoSendBtn').disabled = false;
      }
    }

    document.getElementById('videoSendBtn').addEventListener('click', sendVideoRequest);
    document.getElementById('videoInput').addEventListener('keydown', e => { if (e.key === 'Enter') sendVideoRequest(); });
  </script>
</body>
</html>
```

- [ ] **Step 2: Commit**

```bash
git add index.html
git commit -m "feat: add Image and Video tabs to student UI"
```

---

### Task 4: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add a new section after section 5 (Frontend usage example)**

Insert the following after the existing "## 5. Frontend usage example" section:

```markdown
## 5a. Image generation usage

Students can generate images from a text prompt:

```javascript
const response = await fetch('https://vibe-proxy-gqv4.onrender.com/v1/images/generations', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer sk-vibe-summer-2026',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: 'class-image-model',
    prompt: 'A cartoon robot reading a book in a cozy library',
    n: 1,
    size: '1024x1024'
  })
});
const data = await response.json();
const imgSrc = data.data[0].url || `data:image/png;base64,${data.data[0].b64_json}`;
```

## 5b. Video generation usage

Students can generate short videos from a text prompt (~30 second wait):

```javascript
const response = await fetch('https://vibe-proxy-gqv4.onrender.com/v1/videos/generations', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer sk-vibe-summer-2026',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: 'class-video-model',
    prompt: 'A time-lapse of clouds moving over mountains at sunset',
    seconds: '8',
    size: '1280x720'
  })
});
const data = await response.json();
const videoSrc = data.data[0].url;
```
```

- [ ] **Step 2: Add Vertex AI env vars to the local setup section**

In the existing "## 2. Setup locally" → "Edit `.env`" step, add a note:

```markdown
For video generation, also add these Vertex AI credentials:

```env
VERTEXAI_PROJECT=your-gcp-project-id
VERTEXAI_LOCATION=us-central1
VERTEXAI_CREDENTIALS=your_base64_encoded_service_account_json
```

> Note: If you only need chat + image generation, you can skip the Vertex AI vars.
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: document image and video generation endpoints and usage"
```

---

## Prerequisite: Vertex AI credentials for video

Before Task 1 can be fully tested end-to-end for video, the teacher needs:

1. A Google Cloud project with the Vertex AI API enabled
2. A service account with the `Vertex AI User` role
3. The service account JSON key, base64-encoded:
   ```bash
   base64 -i your-service-account.json | tr -d '\n'
   ```
4. Set `VERTEXAI_CREDENTIALS` in Render's environment variables dashboard

Image generation requires no new credentials — it reuses the existing `GEMINI_API_KEY`.
