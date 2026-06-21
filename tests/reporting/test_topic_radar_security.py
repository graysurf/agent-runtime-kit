#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sys
import threading
import unittest
import urllib.request
from datetime import datetime, timedelta
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from types import SimpleNamespace
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
TOPIC_RADAR_PATH = REPO_ROOT / "core/skills/reporting/topic-radar/bin/topic_radar.py"


def load_topic_radar() -> Any:
    spec = importlib.util.spec_from_file_location("topic_radar", TOPIC_RADAR_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"failed to load {TOPIC_RADAR_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


topic_radar = load_topic_radar()


class TopicRadarSecurityTest(unittest.TestCase):
    def radar_args(self) -> SimpleNamespace:
        start = datetime(2026, 6, 19, tzinfo=topic_radar.UTC)
        return SimpleNamespace(
            cache_context=None,
            cache_dir=None,
            cache_events=[],
            cache_ttl_seconds=0,
            days=2,
            limit=5,
            news_provider="google",
            refresh=False,
            timeout=3,
            topics=["AI agents", "OpenAI"],
            window_end_dt=start + timedelta(days=3),
            window_mode="fixed",
            window_start_dt=start,
        )

    def test_http_get_rejects_oversized_body(self) -> None:
        class Handler(BaseHTTPRequestHandler):
            def log_message(self, _format: str, *_args: object) -> None:
                return

            def do_GET(self) -> None:
                body = b"abcdef"
                self.send_response(200)
                self.end_headers()
                self.wfile.write(body)

        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            url = f"http://127.0.0.1:{server.server_port}/body"
            with self.assertRaises(topic_radar.RemoteFetchError) as caught:
                topic_radar.http_get(url, timeout=3, max_bytes=5)
            self.assertIn("response_too_large", str(caught.exception))
        finally:
            server.shutdown()
            server.server_close()

    def test_safe_xml_rejects_doctype_and_entity_declarations(self) -> None:
        self.assertEqual(topic_radar.safe_xml_fromstring(b"<rss><channel /></rss>").tag, "rss")
        for xml in (
            b'<!DOCTYPE rss [<!ENTITY x "boom">]><rss><channel /></rss>',
            b'<rss><channel /><!ENTITY x "boom"></rss>',
        ):
            with self.subTest(xml=xml):
                with self.assertRaises(topic_radar.UnsafeXmlError):
                    topic_radar.safe_xml_fromstring(xml)

    def test_http_get_refuses_cross_host_redirect(self) -> None:
        requests: list[str] = []

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, _format: str, *_args: object) -> None:
                return

            def do_GET(self) -> None:
                requests.append(self.path)
                if self.path == "/redirect":
                    target = f"http://localhost:{self.server.server_port}/final"
                    self.send_response(302)
                    self.send_header("Location", target)
                    self.end_headers()
                    return
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"ok")

        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            url = f"http://127.0.0.1:{server.server_port}/redirect"
            with self.assertRaises(topic_radar.RemoteFetchError) as caught:
                topic_radar.http_get(url, timeout=3, allowed_hosts={"127.0.0.1"})
            self.assertIn("redirect_origin_not_allowed", str(caught.exception))
            self.assertEqual(requests, ["/redirect"])
        finally:
            server.shutdown()
            server.server_close()

    def test_http_get_refuses_same_host_different_port_redirect(self) -> None:
        class FinalHandler(BaseHTTPRequestHandler):
            def log_message(self, _format: str, *_args: object) -> None:
                return

            def do_GET(self) -> None:
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"ok")

        final_server = ThreadingHTTPServer(("127.0.0.1", 0), FinalHandler)
        final_thread = threading.Thread(target=final_server.serve_forever, daemon=True)
        final_thread.start()

        class RedirectHandler(BaseHTTPRequestHandler):
            def log_message(self, _format: str, *_args: object) -> None:
                return

            def do_GET(self) -> None:
                target = f"http://127.0.0.1:{final_server.server_port}/final"
                self.send_response(302)
                self.send_header("Location", target)
                self.end_headers()

        redirect_server = ThreadingHTTPServer(("127.0.0.1", 0), RedirectHandler)
        redirect_thread = threading.Thread(
            target=redirect_server.serve_forever,
            daemon=True,
        )
        redirect_thread.start()
        try:
            url = f"http://127.0.0.1:{redirect_server.server_port}/redirect"
            with self.assertRaises(topic_radar.RemoteFetchError) as caught:
                topic_radar.http_get(url, timeout=3)
            self.assertIn("redirect_origin_not_allowed", str(caught.exception))
        finally:
            redirect_server.shutdown()
            redirect_server.server_close()
            final_server.shutdown()
            final_server.server_close()

    def test_redirect_handler_refuses_https_to_http_downgrade(self) -> None:
        handler = topic_radar.AllowlistRedirectHandler(
            topic_radar.redirect_allowed_origins("https://example.test/feed.xml")
        )
        request = urllib.request.Request("https://example.test/feed.xml")
        with self.assertRaises(topic_radar.RemoteFetchError) as caught:
            handler.redirect_request(
                request,
                None,
                302,
                "Found",
                {},
                "http://example.test/feed.xml",
            )
        self.assertIn("redirect_origin_not_allowed:http://example.test", str(caught.exception))

    def test_fetch_arxiv_uses_safe_xml_parser(self) -> None:
        args = self.radar_args()
        valid_feed = b"""<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom"
      xmlns:arxiv="http://arxiv.org/schemas/atom">
  <entry>
    <title>AI agents for developer tools</title>
    <published>2026-06-20T00:00:00Z</published>
    <summary>Agentic coding workflow</summary>
    <link rel="alternate" href="https://arxiv.org/abs/2606.00001" />
    <category term="cs.AI" />
    <author><name>Example Author</name></author>
  </entry>
</feed>"""
        unsafe_feed = b'<!DOCTYPE feed [<!ENTITY x "boom">]><feed />'
        original_http_get = topic_radar.http_get
        try:
            topic_radar.http_get = lambda *_args, **_kwargs: valid_feed
            errors: list[dict[str, Any]] = []
            items = topic_radar.fetch_arxiv(args, errors)
            self.assertEqual(errors, [])
            self.assertEqual(len(items), 1)
            self.assertEqual(items[0].source, "arxiv")

            topic_radar.http_get = lambda *_args, **_kwargs: unsafe_feed
            errors = []
            self.assertEqual(topic_radar.fetch_arxiv(args, errors), [])
            self.assertIn("unsafe_xml:", errors[0]["error"])
        finally:
            topic_radar.http_get = original_http_get

    def test_fetch_official_and_news_use_safe_xml_parser(self) -> None:
        args = self.radar_args()
        rss = b"""<rss><channel><item>
  <title>OpenAI agent developer tools</title>
  <link>https://example.test/openai-agent-tools</link>
  <pubDate>Sat, 20 Jun 2026 00:00:00 GMT</pubDate>
  <description>AI agents and developer tools</description>
</item></channel></rss>"""
        unsafe_rss = b'<!DOCTYPE rss [<!ENTITY x "boom">]><rss />'
        original_http_get = topic_radar.http_get
        original_feeds = topic_radar.OFFICIAL_FEEDS
        original_pages = topic_radar.OFFICIAL_HTML_PAGES
        try:
            topic_radar.OFFICIAL_FEEDS = [("Fixture Feed", "https://example.test/rss.xml")]
            topic_radar.OFFICIAL_HTML_PAGES = []
            topic_radar.http_get = lambda *_args, **_kwargs: rss
            errors: list[dict[str, Any]] = []
            official_items = topic_radar.fetch_official(args, errors)
            news_items = topic_radar.fetch_google_news_rss(args, errors, "fixture")
            self.assertEqual(errors, [])
            self.assertEqual(len(official_items), 1)
            self.assertEqual(official_items[0].source, "official")
            self.assertEqual(len(news_items), 1)
            self.assertEqual(news_items[0].source, "news")

            topic_radar.http_get = lambda *_args, **_kwargs: unsafe_rss
            errors = []
            self.assertEqual(topic_radar.fetch_official(args, errors), [])
            self.assertIn("unsafe_xml:", errors[0]["error"])
            errors = []
            self.assertEqual(topic_radar.fetch_google_news_rss(args, errors, "fixture"), [])
            self.assertIn("unsafe_xml:", errors[0]["error"])
        finally:
            topic_radar.http_get = original_http_get
            topic_radar.OFFICIAL_FEEDS = original_feeds
            topic_radar.OFFICIAL_HTML_PAGES = original_pages


if __name__ == "__main__":
    unittest.main()
