#!/usr/bin/env python3
import argparse
import os
import re
import select
import sys
import termios
import time
import tty
from html.parser import HTMLParser

import requests
from dotenv import load_dotenv
from mpd import MPDClient, ConnectionError as MPDConnectionError

try:
    import lyricsgenius
except Exception:
    lyricsgenius = None


def fetch_lyrics_genius(token: str, artist: str, title: str, timeout: int) -> str | None:
    if lyricsgenius is not None:
        genius = lyricsgenius.Genius(
            token,
            timeout=timeout,
            retries=1,
            remove_section_headers=True,
            skip_non_songs=True,
            verbose=False,
        )
        song = genius.search_song(title=title, artist=artist)
        if song and song.lyrics:
            return song.lyrics.strip()

    headers = {"Authorization": f"Bearer {token}"}
    query = f"{artist} {title}".strip()
    response = requests.get(
        "https://api.genius.com/search",
        headers=headers,
        params={"q": query},
        timeout=timeout,
    )
    if response.status_code != 200:
        return None
    data = response.json()
    hits = data.get("response", {}).get("hits", [])
    if not hits:
        return None
    result = hits[0].get("result", {})
    url = result.get("url")
    if not url:
        return None

    page = requests.get(url, headers={"User-Agent": "lyrics-cli/1.0"}, timeout=timeout)
    if page.status_code != 200:
        return None

    class LyricsHTMLParser(HTMLParser):
        def __init__(self) -> None:
            super().__init__()
            self.depth = 0
            self.parts: list[str] = []

        def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
            attr_map = dict(attrs)
            if "data-lyrics-container" in attr_map:
                self.depth = max(self.depth, 1)
            elif self.depth > 0 and tag == "div":
                self.depth += 1
            if self.depth > 0 and tag == "br":
                self.parts.append("\n")

        def handle_endtag(self, tag: str) -> None:
            if self.depth > 0 and tag == "div":
                self.depth -= 1

        def handle_data(self, data: str) -> None:
            if self.depth > 0:
                self.parts.append(data)

        def get_text(self) -> str:
            return "".join(self.parts).strip()

    parser = LyricsHTMLParser()
    parser.feed(page.text)
    lyrics = parser.get_text()
    if not lyrics:
        return None
    return lyrics


def fetch_lyrics_lrclib(artist: str, title: str, timeout: int) -> str | None:
    response = requests.get(
        "https://lrclib.net/api/get",
        params={"artist_name": artist, "track_name": title},
        timeout=timeout,
    )
    if response.status_code != 200:
        return None
    data = response.json()
    plain = data.get("plainLyrics")
    if plain:
        return plain.strip()
    synced = data.get("syncedLyrics")
    if synced:
        lines = []
        for line in synced.splitlines():
            cleaned = line
            while cleaned.startswith("[") and "]" in cleaned:
                cleaned = cleaned.split("]", 1)[1]
            cleaned = cleaned.strip()
            if cleaned:
                lines.append(cleaned)
        return "\n".join(lines).strip() if lines else None
    return None


def fetch_lrc_lrclib(artist: str, title: str, timeout: int) -> str | None:
    response = requests.get(
        "https://lrclib.net/api/get",
        params={"artist_name": artist, "track_name": title},
        timeout=timeout,
    )
    if response.status_code != 200:
        return None
    data = response.json()
    synced = data.get("syncedLyrics")
    if synced:
        return synced.strip()
    return None


def parse_lrc(text: str) -> list[tuple[float, str]]:
    entries: list[tuple[float, str]] = []
    offset_ms = 0
    for line in text.splitlines():
        offset_match = re.match(r"\[offset:([+-]?\d+)\]", line.strip())
        if offset_match:
            offset_ms = int(offset_match.group(1))
            continue
        times = re.findall(r"\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]", line)
        if not times:
            continue
        lyric = re.sub(r"\[.*?\]", "", line).strip()
        for mm, ss, ms in times:
            millis = int(ms.ljust(3, "0")) if ms else 0
            total = int(mm) * 60 + int(ss) + (millis / 1000.0) + (offset_ms / 1000.0)
            entries.append((max(total, 0.0), lyric))
    return sorted(entries, key=lambda item: item[0])


def safe_filename(text: str) -> str:
    sanitized = re.sub(r"[^A-Za-z0-9._-]+", "_", text).strip("_")
    return sanitized or "lyrics"


def contains_cjk(text: str) -> bool:
    for ch in text:
        code = ord(ch)
        if (
            0x4E00 <= code <= 0x9FFF
            or 0x3400 <= code <= 0x4DBF
            or 0x3040 <= code <= 0x30FF
            or 0xAC00 <= code <= 0xD7AF
        ):
            return True
    return False


def filter_lyrics(text: str, filter_cjk: bool) -> str:
    if not filter_cjk:
        return text
    lines = [line for line in text.splitlines() if not contains_cjk(line)]
    return "\n".join(lines).strip()


def colorize_lyrics(text: str) -> str:
    lines = []
    for line in text.splitlines():
        tag = line.lower()
        if "refren" in tag or "chorus" in tag:
            lines.append(f"\033[33m{line}\033[0m")
        else:
            lines.append(f"\033[32m{line}\033[0m")
    return "\n".join(lines)


def get_current_song(client: MPDClient) -> dict:
    status = client.status()
    if status.get("state") != "play":
        return {}
    return client.currentsong()


def get_current_song_id(client: MPDClient) -> str | None:
    song = get_current_song(client)
    if not song:
        return None
    return song.get("id") or song.get("file")


def get_song_id_any_state(client: MPDClient) -> str | None:
    try:
        song = client.currentsong()
    except Exception:
        return None
    if not song:
        return None
    return song.get("id") or song.get("file")


def get_elapsed(client: MPDClient) -> float | None:
    try:
        status = client.status()
        elapsed = status.get("elapsed")
        if elapsed is not None:
            return float(elapsed)
        time_value = status.get("time", "0:0").split(":")[0]
        return float(time_value)
    except Exception:
        return None


def main() -> int:
    load_dotenv()
    parser = argparse.ArgumentParser(description="Afiseaza versurile melodiei redate in mpd.")
    parser.add_argument("--host", default="127.0.0.1", help="MPD host (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=6600, help="MPD port (default: 6600)")
    parser.add_argument("--interval", type=float, default=2.0, help="Interval de refresh in secunde")
    parser.add_argument("--timeout", type=int, default=10, help="Timeout pentru request de lyrics")
    parser.add_argument(
        "--source",
        choices=["genius", "lrclib", "auto"],
        default="auto",
        help="Sursa versuri: genius, lrclib sau auto (default)",
    )
    parser.add_argument(
        "--no-filter-cjk",
        action="store_true",
        help="Nu elimina liniile cu caractere CJK",
    )
    parser.add_argument(
        "--auto-scroll",
        action="store_true",
        help="Afiseaza versurile linie cu linie, cu delay intre linii",
    )
    parser.add_argument(
        "--lrc-sync",
        action="store_true",
        help="Sincronizeaza versurile pe linii folosind LRC (LRCLIB)",
    )
    parser.add_argument(
        "--lrc-dir",
        default=str(os.path.join(os.path.expanduser("~"), ".lyrics")),
        help="Folder pentru cache LRC (default: ~/.lyrics)",
    )
    parser.add_argument(
        "--lrc-offset",
        type=float,
        default=0.0,
        help="Offset in secunde pentru sincronizare LRC",
    )
    parser.add_argument(
        "--scroll-interval",
        type=float,
        default=2.0,
        help="Delay in secunde intre linii (default: 2.0)",
    )
    parser.add_argument(
        "--word-interval",
        type=float,
        default=0.2,
        help="Delay in secunde intre cuvinte (default: 0.2)",
    )
    parser.add_argument(
        "--show-speed",
        action="store_true",
        help="Afiseaza viteza curenta cand ajustezi cu +/-. (default: off)",
    )
    args = parser.parse_args()
    filter_cjk = not args.no_filter_cjk
    scroll_interval = args.scroll_interval
    word_interval = args.word_interval
    lrc_dir = args.lrc_dir

    client = MPDClient()
    client.timeout = 10
    client.idletimeout = None
    connected = False
    last_song_id = None
    last_state_message = ""

    term_settings = None
    if args.auto_scroll:
        term_settings = termios.tcgetattr(sys.stdin.fileno())
        tty.setcbreak(sys.stdin.fileno())

    try:
        while True:
            try:
                if not connected:
                    client.connect(args.host, args.port)
                    connected = True

                status = client.status()
                if status.get("state") != "play":
                    message = "MPD e pe pauza." if status.get("state") == "pause" else "MPD nu reda nimic."
                    if message != last_state_message:
                        print("\033c", end="")
                        print(message)
                        last_state_message = message
                    last_song_id = None
                    time.sleep(args.interval)
                    continue
                last_state_message = ""
                song = client.currentsong()

                song_id = song.get("id") or song.get("file")
                if song_id == last_song_id:
                    time.sleep(args.interval)
                    continue

                last_song_id = song_id
                artist = song.get("artist", "").strip()
                title = song.get("title", "").strip()
                if not artist or not title:
                    print("Nu pot citi artist/titlu din MPD.")
                    time.sleep(args.interval)
                    continue

                genius_token = os.environ.get("GENIUS_ACCESS_TOKEN", "").strip()
                lyrics = None
                lrc_entries: list[tuple[float, str]] | None = None

                if args.lrc_sync:
                    lrc_name = safe_filename(f"{artist}-{title}.lrc")
                    lrc_path = os.path.join(lrc_dir, lrc_name)
                    lrc_text = None
                    if os.path.exists(lrc_path):
                        with open(lrc_path, "r", encoding="utf-8", errors="ignore") as handle:
                            lrc_text = handle.read()
                    else:
                        lrc_text = fetch_lrc_lrclib(artist, title, args.timeout)
                        if lrc_text:
                            os.makedirs(lrc_dir, exist_ok=True)
                            with open(lrc_path, "w", encoding="utf-8") as handle:
                                handle.write(lrc_text)
                    if lrc_text:
                        lrc_entries = parse_lrc(lrc_text)
                if args.source in ("auto", "genius"):
                    if not genius_token:
                        print("Lipseste GENIUS_ACCESS_TOKEN. Pune-l in .env sau exporta-l.")
                    else:
                        lyrics = fetch_lyrics_genius(genius_token, artist, title, args.timeout)
                if not lyrics and args.source in ("auto", "lrclib"):
                    lyrics = fetch_lyrics_lrclib(artist, title, args.timeout)

                if lyrics:
                    lyrics = filter_lyrics(lyrics, filter_cjk)
                    if not args.auto_scroll:
                        lyrics = colorize_lyrics(lyrics)

                if args.lrc_sync and not lrc_entries:
                    print("\033c", end="")
                    print("=" * 72)
                    print(f"{artist} - {title}\n")
                    print("Nu am gasit LRC sincronizat pentru aceasta melodie.")
                    time.sleep(args.interval)
                    continue

                print("\033c", end="")
                print("=" * 72)
                print(f"{artist} - {title}\n")
                if args.lrc_sync and lrc_entries:
                    current_id = song_id
                    last_line = ""
                    past_lines: list[str] = []
                    while True:
                        status = client.status()
                        state = status.get("state")
                        if state == "pause":
                            time.sleep(0.2)
                            continue
                        if state != "play":
                            break
                        if get_song_id_any_state(client) != current_id:
                            break
                        elapsed = get_elapsed(client)
                        if elapsed is None:
                            time.sleep(0.2)
                            continue
                        elapsed += args.lrc_offset
                        line = ""
                        for t, text in lrc_entries:
                            if t <= elapsed:
                                line = text
                            else:
                                break
                        if line and line != last_line:
                            print("\033c", end="")
                            print("=" * 72)
                            print(f"{artist} - {title}\n")
                            for past in past_lines:
                                print(f"\033[32m{past}\033[0m")
                            print(f"\033[31m{line}\033[0m")
                            past_lines.append(line)
                            last_line = line
                        time.sleep(0.2)
                elif lyrics:
                    if args.auto_scroll:
                        current_id = song_id
                        lines = lyrics.splitlines()
                        i = 0
                        while i < len(lines):
                            status = client.status()
                            state = status.get("state")
                            if state == "pause":
                                time.sleep(0.2)
                                continue
                            if state != "play":
                                break
                            if get_song_id_any_state(client) != current_id:
                                break
                            line = lines[i]
                            words = line.split()
                            if not words:
                                i += 1
                                continue
                            print("\033[31m", end="")
                            sys.stdout.flush()
                            for w_index, word in enumerate(words):
                                if w_index:
                                    print(" ", end="")
                                print(word, end="")
                                sys.stdout.flush()
                                remaining_word = word_interval
                                interrupted = False
                                while remaining_word > 0:
                                    if select.select([sys.stdin], [], [], 0)[0]:
                                        ch = sys.stdin.read(1)
                                        if ch in ("+", "="):
                                            scroll_interval = max(0.2, scroll_interval - 0.2)
                                            if args.show_speed:
                                                sys.stderr.write(f"\r\033[2KSpeed: {scroll_interval:.1f}s")
                                                sys.stderr.flush()
                                        elif ch in ("-", "_"):
                                            scroll_interval = min(10.0, scroll_interval + 0.2)
                                            if args.show_speed:
                                                sys.stderr.write(f"\r\033[2KSpeed: {scroll_interval:.1f}s")
                                                sys.stderr.flush()
                                    status = client.status()
                                    state = status.get("state")
                                    if state == "pause":
                                        time.sleep(0.2)
                                        continue
                                    if state != "play" or get_song_id_any_state(client) != current_id:
                                        interrupted = True
                                        break
                                    step = min(0.2, remaining_word)
                                    time.sleep(step)
                                    remaining_word -= step
                                if interrupted:
                                    break
                            if interrupted:
                                break
                            print("\033[0m")
                            # Wait remaining line interval after words.
                            remaining = scroll_interval
                            interrupted = False
                            while remaining > 0:
                                if select.select([sys.stdin], [], [], 0)[0]:
                                    ch = sys.stdin.read(1)
                                    if ch in ("+", "="):
                                        scroll_interval = max(0.2, scroll_interval - 0.2)
                                        if args.show_speed:
                                            sys.stderr.write(f"\r\033[2KSpeed: {scroll_interval:.1f}s")
                                            sys.stderr.flush()
                                    elif ch in ("-", "_"):
                                        scroll_interval = min(10.0, scroll_interval + 0.2)
                                        if args.show_speed:
                                            sys.stderr.write(f"\r\033[2KSpeed: {scroll_interval:.1f}s")
                                            sys.stderr.flush()
                                status = client.status()
                                state = status.get("state")
                                if state == "pause":
                                    time.sleep(0.2)
                                    continue
                                if state != "play" or get_song_id_any_state(client) != current_id:
                                    interrupted = True
                                    break
                                step = min(0.2, remaining)
                                time.sleep(step)
                                remaining -= step
                            if interrupted:
                                break
                            # Replace the red line with green.
                            print(f"\033[1A\033[2K\033[32m{line}\033[0m")
                            i += 1
                    else:
                        print(lyrics)
                else:
                    print("Nu am gasit versuri pentru aceasta melodie.")

                time.sleep(args.interval)

            except MPDConnectionError:
                print("Conexiune MPD pierduta. Reincerc...")
                try:
                    client.disconnect()
                except Exception:
                    pass
                connected = False
                time.sleep(args.interval)
            except requests.RequestException:
                print("Eroare la accesarea versurilor. Reincerc...")
                time.sleep(args.interval)
            except KeyboardInterrupt:
                print("\nIesire.")
                break
    finally:
        if term_settings is not None:
            termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, term_settings)

    try:
        if connected:
            client.disconnect()
    except Exception:
        pass

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
