import { writeFileSync, mkdirSync } from "fs";
import { join } from "path";

const E2E_DIR = join(import.meta.dirname, ".");
const LOGS_DIR = join(E2E_DIR, "logs");
const SCREENSHOTS_DIR = join(E2E_DIR, "screenshots");

// Ensure dirs exist
mkdirSync(LOGS_DIR, { recursive: true });
mkdirSync(SCREENSHOTS_DIR, { recursive: true });

export const BASE_URL =
  process.env.E2E_BASE_URL || "http://localhost:8788";

type LogEntry = {
  timestamp: string;
  step: string;
  method: string;
  url: string;
  requestHeaders?: Record<string, string>;
  requestBody?: unknown;
  status?: number;
  responseHeaders?: Record<string, string>;
  responseBody?: unknown;
  error?: string;
  duration_ms?: number;
};

let logEntries: LogEntry[] = [];
let screenshotIndex = 0;

/** Reset state between test suites */
export function resetLog() {
  logEntries = [];
  screenshotIndex = 0;
}

/** Make an HTTP request with full logging */
export async function request(
  step: string,
  method: string,
  path: string,
  options?: {
    body?: unknown;
    headers?: Record<string, string>;
    token?: string;
  }
): Promise<{ status: number; body: any; headers: Record<string, string> }> {
  const url = `${BASE_URL}${path}`;
  const headers: Record<string, string> = {
    Origin: BASE_URL,
    ...(options?.body ? { "Content-Type": "application/json" } : {}),
    ...(options?.headers || {}),
  };
  if (options?.token) {
    headers["Authorization"] = `Bearer ${options.token}`;
  }

  const entry: LogEntry = {
    timestamp: new Date().toISOString(),
    step,
    method,
    url,
    requestHeaders: { ...headers },
    requestBody: options?.body,
  };

  const start = Date.now();
  try {
    const res = await fetch(url, {
      method,
      headers,
      body: options?.body ? JSON.stringify(options.body) : undefined,
    });
    const duration_ms = Date.now() - start;

    // Read response body as text first, then try to parse as JSON
    const text = await res.text();
    let body: any;
    try {
      body = JSON.parse(text);
    } catch {
      body = text;
    }

    const responseHeaders: Record<string, string> = {};
    res.headers.forEach((v, k) => (responseHeaders[k] = v));

    entry.status = res.status;
    entry.responseHeaders = responseHeaders;
    entry.responseBody = body;
    entry.duration_ms = duration_ms;

    logEntries.push(entry);

    // Save screenshot (response snapshot) for every response
    saveScreenshot(step, { status: res.status, body, headers: responseHeaders });

    return { status: res.status, body, headers: responseHeaders };
  } catch (err: any) {
    entry.error = err.message || String(err);
    entry.duration_ms = Date.now() - start;
    logEntries.push(entry);
    saveScreenshot(step, { error: entry.error });
    throw err;
  }
}

/** Save a response snapshot to the screenshots directory */
function saveScreenshot(step: string, data: unknown) {
  screenshotIndex++;
  const filename = `${String(screenshotIndex).padStart(2, "0")}_${step.replace(/[^a-zA-Z0-9_-]/g, "_")}.json`;
  writeFileSync(
    join(SCREENSHOTS_DIR, filename),
    JSON.stringify(data, null, 2) + "\n"
  );
}

/** Flush all logs to disk */
export function flushLogs(testName: string) {
  const filename = `${testName.replace(/[^a-zA-Z0-9_-]/g, "_")}.log.json`;
  writeFileSync(
    join(LOGS_DIR, filename),
    JSON.stringify(logEntries, null, 2) + "\n"
  );
}

/** Generate a unique email for test isolation */
export function testEmail() {
  return `e2e-${Date.now()}-${Math.random().toString(36).slice(2, 8)}@test.com`;
}
