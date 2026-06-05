const http = require("http");
const fs = require("fs");
const path = require("path");

const chat = require("../api/chat.js");
const createUser = require("../api/create-user.js");
const grade = require("../api/grade.js");
const resetPassword = require("../api/reset-password.js");

const root = path.resolve(__dirname, "..");
const port = Number(process.env.PORT || 8766);

loadEnv(path.join(root, ".env"));

function loadEnv(filePath) {
  if (!fs.existsSync(filePath)) return;
  const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);
  for (const line of lines) {
    const match = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
    if (!match) continue;
    const value = match[2].replace(/^['"]|['"]$/g, "");
    if (!process.env[match[1]]) process.env[match[1]] = value;
  }
}

function mimeType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  return {
    ".html": "text/html; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".svg": "image/svg+xml",
    ".mp4": "video/mp4",
    ".md": "text/markdown; charset=utf-8"
  }[ext] || "application/octet-stream";
}

function collectBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 1_000_000) {
        reject(new Error("Request body too large"));
        req.destroy();
      }
    });
    req.on("end", () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch {
        reject(new Error("Invalid JSON"));
      }
    });
    req.on("error", reject);
  });
}

async function runApi(handler, req, res) {
  try {
    req.body = await collectBody(req);
    await handler(req, createApiResponse(res));
  } catch (err) {
    res.statusCode = 400;
    res.setHeader("Content-Type", "application/json; charset=utf-8");
    res.end(JSON.stringify({ error: err.message }));
  }
}

function createApiResponse(res) {
  return {
    setHeader: (key, value) => res.setHeader(key, value),
    status(code) {
      res.statusCode = code;
      return this;
    },
    json(data) {
      if (!res.getHeader("Content-Type")) {
        res.setHeader("Content-Type", "application/json; charset=utf-8");
      }
      res.end(JSON.stringify(data));
      return data;
    },
    end(data) {
      res.end(data);
    }
  };
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (url.pathname === "/api/chat") return runApi(chat, req, res);
  if (url.pathname === "/api/create-user") return runApi(createUser, req, res);
  if (url.pathname === "/api/grade") return runApi(grade, req, res);
  if (url.pathname === "/api/reset-password") return runApi(resetPassword, req, res);

  const requestPath = url.pathname === "/" ? "/course-package/preview.html" : url.pathname;
  const decodedPath = decodeURIComponent(requestPath).replace(/^[/\\]+/, "");
  const filePath = path.resolve(root, decodedPath);

  if (!filePath.startsWith(root)) {
    res.statusCode = 403;
    return res.end("Forbidden");
  }

  fs.stat(filePath, (statErr, stat) => {
    if (statErr || !stat.isFile()) {
      res.statusCode = 404;
      return res.end("Not found");
    }

    res.setHeader("Content-Type", mimeType(filePath));
    fs.createReadStream(filePath).pipe(res);
  });
});

server.listen(port, "127.0.0.1", () => {
  console.log(`CAASPP AI preview running at http://127.0.0.1:${port}/course-package/preview.html`);
});
