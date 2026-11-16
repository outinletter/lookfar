// LookFar signal server: one Durable Object per session wakes on an alarm and
// toggles the Live Activity's yellow dot through APNs.
import { DurableObject } from "cloudflare:workers";

// Timings in ms. Tunable here without shipping an app update.
const PATTERNS = {
  far: { pulses: 2, sets: 1, on: 1200, off: 400, gap: 800 },
  blink: { pulses: 3, sets: 2, on: 500, off: 500, gap: 800 },
};
const INTERVALS = [5, 10, 20, 30];
const MAX_SESSION_MS = 8 * 60 * 60 * 1000; // Live Activities end after 8 hours.

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const json = (body, status = 200) => Response.json(body, { status });
const b64url = (bytes) =>
  btoa(String.fromCharCode(...new Uint8Array(bytes))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

export default {
  async fetch(request, env) {
    const match = new URL(request.url).pathname.match(/^\/session\/([0-9a-fA-F-]{36})$/);
    if (!match) return json({ error: "not found" }, 404);
    if (request.method !== "POST" && request.method !== "DELETE") return json({ error: "method" }, 405);
    return env.SESSIONS.get(env.SESSIONS.idFromName(match[1].toLowerCase())).fetch(request);
  },
};

export class Session extends DurableObject {
  async fetch(request) {
    const storage = this.ctx.storage;
    if (request.method === "DELETE") {
      await storage.deleteAlarm();
      await storage.deleteAll();
      return json({ ok: true });
    }
    let body;
    try { body = await request.json(); } catch { return json({ error: "json" }, 400); }
    const token = body.token;
    if (typeof token !== "string" || !/^[0-9a-f]{32,400}$/i.test(token)) return json({ error: "token" }, 400);

    // Token refresh for a running session.
    if (body.modes === undefined) {
      const session = await storage.get("session");
      if (!session) return json({ error: "no session" }, 404);
      session.token = token;
      await storage.put("session", session);
      return json({ ok: true });
    }

    const modes = body.modes;
    const valid = Array.isArray(modes) && modes.length >= 1 && modes.length <= 2 &&
      modes.every((m) => m in PATTERNS) && new Set(modes).size === modes.length;
    if (!valid || !INTERVALS.includes(body.minutes)) return json({ error: "config" }, 400);

    const now = Date.now();
    const session = {
      token, modes, minutes: body.minutes, sandbox: body.sandbox === true,
      startedAt: now, nextAt: now + body.minutes * 60000, index: 0,
    };
    await storage.put("session", session);
    await storage.setAlarm(session.nextAt);
    return json({ ok: true });
  }

  async alarm() {
    const storage = this.ctx.storage;
    const session = await storage.get("session");
    if (!session) return;
    if (Date.now() - session.startedAt > MAX_SESSION_MS) {
      await this.push(session, "end", false).catch(() => {});
      await storage.deleteAll();
      return;
    }
    let alive = true;
    try { alive = await this.signal(session, session.modes[session.index]); } catch (error) { console.log("signal failed", error); }

    // The session may have been stopped, restarted or given a new token while signalling.
    const current = await storage.get("session");
    if (!current || current.startedAt !== session.startedAt) return;
    if (!alive) { await storage.deleteAll(); return; }

    const interval = current.minutes * 60000;
    const offset = Math.min(300000, interval / 2);
    if (current.modes.length > 1) {
      current.nextAt += current.index === 0 ? offset : interval - offset;
      current.index = current.index === 0 ? 1 : 0;
    } else {
      current.nextAt += interval;
    }
    if (current.nextAt <= Date.now()) current.nextAt = Date.now() + 1000;
    await storage.put("session", current);
    await storage.setAlarm(current.nextAt);
  }

  // Returns false when APNs reports the Live Activity token is gone.
  async signal(session, mode) {
    const p = PATTERNS[mode];
    for (let set = 0; set < p.sets; set++) {
      for (let pulse = 0; pulse < p.pulses; pulse++) {
        if (!(await this.push(session, "update", true))) return false;
        await sleep(p.on);
        if (!(await this.push(session, "update", false))) return false;
        await sleep(p.off);
      }
      if (set < p.sets - 1) await sleep(p.gap);
    }
    return true;
  }

  async push(session, event, lit) {
    const now = Math.floor(Date.now() / 1000);
    const aps = { timestamp: now, event, "content-state": { lit } };
    if (event === "end") aps["dismissal-date"] = now;
    const host = session.sandbox ? "api.sandbox.push.apple.com" : "api.push.apple.com";
    const response = await fetch(`https://${host}/3/device/${session.token}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${await this.jwt()}`,
        "apns-topic": `${this.env.BUNDLE_ID}.push-type.liveactivity`,
        "apns-push-type": "liveactivity",
        "apns-priority": "10",
      },
      body: JSON.stringify({ aps }),
    });
    if (response.ok) return true;
    const reason = (await response.json().catch(() => ({}))).reason;
    console.log("apns", response.status, reason);
    const gone = response.status === 410 || reason === "BadDeviceToken" || reason === "DeviceTokenNotForTopic";
    return !gone;
  }

  // APNs provider token (ES256 JWT), reused for 50 minutes.
  async jwt() {
    const now = Math.floor(Date.now() / 1000);
    if (this.cached && now - this.cached.at < 3000) return this.cached.value;
    const der = Uint8Array.from(atob(this.env.APNS_KEY.replace(/-----[^-]+-----|\s/g, "")), (c) => c.charCodeAt(0));
    const key = await crypto.subtle.importKey("pkcs8", der, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
    const encode = (value) => b64url(new TextEncoder().encode(JSON.stringify(value)));
    const unsigned = `${encode({ alg: "ES256", kid: this.env.APNS_KEY_ID })}.${encode({ iss: this.env.TEAM_ID, iat: now })}`;
    const signature = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(unsigned));
    this.cached = { at: now, value: `${unsigned}.${b64url(signature)}` };
    return this.cached.value;
  }
}
