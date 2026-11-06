const assert = require('node:assert/strict');
const { readFile } = require('node:fs/promises');
const http = require('node:http');
const path = require('node:path');
const { test } = require('node:test');
const { chromium } = require('playwright');

for (const version of ['v1', 'v2']) {
  test(`${version}: stored messages render as text without executing markup`, async () => {
    const message = '<img src="missing" onerror="window.guestbookExecuted = true">Hello & welcome';
    const directory = path.join(__dirname, '..', version, 'guestbook', 'public');
    const server = http.createServer(async (req, res) => {
      if (req.url === '/lrange/guestbook') {
        res.setHeader('Content-Type', 'application/json');
        return res.end(JSON.stringify([message]));
      }
      const files = { '/': 'index.html', '/script.js': 'script.js', '/jquery.min.js': 'jquery.min.js', '/style.css': 'style.css' };
      const file = files[req.url];
      if (!file) return res.writeHead(404).end();
      try {
        res.setHeader('Content-Type', file.endsWith('.js') ? 'text/javascript' : file.endsWith('.css') ? 'text/css' : 'text/html');
        res.end(await readFile(path.join(directory, file)));
      } catch { res.writeHead(500).end(); }
    });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    let browser;
    try {
      browser = await chromium.launch({ headless: true, channel: process.env.PLAYWRIGHT_CHANNEL || undefined });
      const page = await browser.newPage();
      await page.goto(`http://127.0.0.1:${server.address().port}`);
      await page.waitForFunction(() => document.querySelector('#guestbook-entries').textContent.includes('Hello'));
      assert.equal(await page.locator('#guestbook-entries').textContent(), message);
      assert.equal(await page.locator('#guestbook-entries img').count(), 0);
      assert.equal(await page.evaluate(() => window.guestbookExecuted), undefined);
    } finally {
      if (browser) await browser.close();
      await new Promise(resolve => server.close(resolve));
    }
  });
}
