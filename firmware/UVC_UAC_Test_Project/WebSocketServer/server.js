/* Websocket server for UVC, UAC testing
 *
 * [How to use it]
 * 1. Check you local IP first.
 * (e.g.) 192.168.50.80
 * 2. Change local IP in client.html line #222
 * (e.g.) ws://192.168.50.80:9090
 * 3. Access http://localhost:8000/client or http://192.168.50.80:8000/client in a web browser.
 */

const path = require("path");
const express = require("express");
const WebSocket = require("ws");
const app = express();

const WS_PORT = process.env.WS_PORT || 9090;
const HTTP_PORT = process.env.HTTP_PORT || 8000;

const wsServer = new WebSocket.Server(
  {
    host: "0.0.0.0",
    port: WS_PORT,
    // Accept compressed frames from ESP32 (fixes "RSV1 must be clear" error)
    perMessageDeflate: true,
  },
  () => console.log(`WS server is listening at ws://0.0.0.0:${WS_PORT}`),
);

const imageQueue = [];
const audioQueue = [];
const IMAGE_DELAY = 1000; // 1 second delay for images to sync with audio
const MAX_IMAGE_QUEUE = 30;   // drop oldest if ESP32 sends faster than we consume
const MAX_AUDIO_QUEUE = 60;   // ~2s at 512 bytes @ 16kHz-ish

// array of connected websocket clients
let connectedClients = [];
let esp32Client = null;
let enabledAudio = false;
let enabledImage = false;
let imageQueueTimer = null;

wsServer.on("connection", (ws, req) => {
  // Check the protocol from the initial handshake to identify the client
  const clientProtocol = req.headers["sec-websocket-protocol"];
  if (clientProtocol === "ESP32") {
    console.log("ESP32 client connected");
    esp32Client = ws; // Store the ESP32 client separately
  } else {
    console.log("HTML client connected");
    connectedClients.push(ws); // Add HTML clients to the array
  }

  ws.on("message", (data) => {
    if (esp32Client && ws === esp32Client) {
      if (data instanceof Buffer) {
        console.log(`[ESP32] Received data: ${data.length} bytes`);
        if (data.length === 512) {
          console.log(`[ESP32] Audio frame detected: ${data.length} bytes`);
          // Sending without syncing
          if (enabledAudio && !enabledImage) {
            broadcastData("audio", data);
          } else {
            // Add audio data to audioQueue (bounded)
            if (audioQueue.length >= MAX_AUDIO_QUEUE) {
              audioQueue.shift();
            }
            audioQueue.push(data);
            sendSyncedData();
          }
        } else if (isValidJPEG(data)) {
          console.log(`[ESP32] Image frame detected: ${data.length} bytes (JPEG)`);
          if (imageQueue.length >= MAX_IMAGE_QUEUE) {
            imageQueue.shift(); // drop oldest to avoid unbounded growth
          }
          imageQueue.push({ data, timestamp: Date.now() });
          scheduleProcessImageQueue();
        } else {
          console.log(`[ESP32] Unknown data type: ${data.length} bytes (first bytes: ${data.slice(0, 4).toString('hex')})`);
        }
      }
    } else {
      if (typeof data === "string") {
        let settings;
        try {
          settings = JSON.parse(data);
        } catch (e) {
          console.error("Invalid JSON from client:", e.message);
          return;
        }
        if (settings && settings.command === "toggleAudio") {
          enabledAudio = settings.enabled;
        } else if (settings && settings.command === "imageCheckbox") {
          enabledImage = settings.enabled;
        }
        if (esp32Client != null && esp32Client.readyState === 1) {
          esp32Client.send(data);
        }
      }
    }
  });

  ws.on("error", (err) => {
    console.error("WebSocket error:", err.message);
  });

  ws.on("close", () => {
    console.log("Client disconnected");
    connectedClients = connectedClients.filter((client) => client !== ws);
    if (ws === esp32Client) {
      esp32Client = null; // Clear ESP32 client on disconnection
    }
  });
});

// Helper function to validate if the Buffer is a valid JPEG image
function isValidJPEG(data) {
  // JPEG files start with 0xFFD8 and end with 0xFFD9
  const SOI = [0xff, 0xd8]; // Start of image marker
  const EOI = [0xff, 0xd9]; // End of image marker

  return (
    data.length > 2 &&
    data[0] === SOI[0] &&
    data[1] === SOI[1] && // Check for SOI at the start
    data[data.length - 2] === EOI[0] &&
    data[data.length - 1] === EOI[1] // Check for EOI at the end
  );
}

// Single timer to drain image queue (avoids many setTimeouts per frame)
function scheduleProcessImageQueue() {
  if (imageQueueTimer) return;
  imageQueueTimer = setTimeout(() => {
    imageQueueTimer = null;
    processImageQueue();
    if (imageQueue.length > 0) scheduleProcessImageQueue();
  }, IMAGE_DELAY);
}

// Function to process the image queue and send images to clients after delay
function processImageQueue() {
  const now = Date.now();
  while (imageQueue.length > 0) {
    const { data, timestamp } = imageQueue[0];
    if (now - timestamp >= IMAGE_DELAY) {
      // Send image data to all connected HTML clients
      broadcastData("image", data);
      imageQueue.shift(); // Remove the processed image from the queue
    } else {
      break; // Stop if we haven't reached the delay time
    }
  }
}

// Function to send synchronized audio and image data
function sendSyncedData() {
  // Check if both queues have data to send
  if (audioQueue.length > 0 && imageQueue.length > 0) {
    // Send audio data
    broadcastData("audio", audioQueue.shift());

    // We already process images in processImageQueue()
  }
}

// Helper function to broadcast data to HTML clients (safe iteration, no splice-in-loop)
function broadcastData(type, data) {
  const open = connectedClients.filter((c) => c.readyState === 1);
  connectedClients = open;
  open.forEach((client) => {
    try {
      client.send(JSON.stringify({ type, length: data.length }));
      client.send(data);
    } catch (e) {
      console.error("Broadcast send error:", e.message);
    }
  });
}

// HTTP stuff
app.get("/client", (req, res) =>
  res.sendFile(path.resolve(__dirname, "./client.html")),
);
app.listen(HTTP_PORT, "0.0.0.0", () =>
  console.log(`HTTP server listening at http://0.0.0.0:${HTTP_PORT}`),
);
