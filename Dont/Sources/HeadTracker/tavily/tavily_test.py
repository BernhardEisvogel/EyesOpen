

import re
import requests
from tavily import TavilyClient
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import yt_dlp
import subprocess
import os
import sys

from dotenv import load_dotenv
import os

load_dotenv()

# TAVILY_API_KEY = "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"

TAVILY_API_KEY = os.getenv("TAVILY_API_KEY")

HEADERS = {"User-Agent": "Mozilla/5.0"}
TARGET_SITES = ["npr.org", "bbc.co.uk", "bbc.com"]

# ---------- Helper: check ffmpeg ----------
def check_ffmpeg():
    try:
        subprocess.run(["ffmpeg", "-version"], capture_output=True, check=True)
        return True
    except:
        print("❌ ffmpeg not found. Please install ffmpeg and add it to PATH.")
        return False

# ---------- Conversion to MP4 (AAC audio) ----------
def convert_any_to_mp4(input_file, output_file):
    """Convert any audio file to MP4 container with AAC codec."""
    try:
        subprocess.run([
            "ffmpeg", "-i", input_file, "-t", "10",
            "-vn", "-acodec", "aac", "-y", output_file
        ], check=True, capture_output=True)
        print(f"🎧 Converted to MP4: {output_file}")
        return output_file
    except subprocess.CalledProcessError as e:
        print(f"❌ Conversion failed: {e}")
        return None

# ---------- Tavily search ----------
def tavily_search(query):
    client = TavilyClient(api_key=TAVILY_API_KEY)
    site_query = " OR ".join([f"site:{s}" for s in TARGET_SITES])
    full_query = f"{query} ({site_query})"
    results = client.search(full_query, max_results=10)
    return [r["url"] for r in results["results"]]

# ---------- Extract audio URL from regular web pages ----------
def extract_audio_url(url):
    print(f"🔎 Parsing: {url}")
    res = requests.get(url, headers=HEADERS, timeout=10)
    soup = BeautifulSoup(res.text, "html.parser")

    if "npr.org" in url:
        audio = soup.find("audio")
        if audio and audio.get("src"):
            return audio["src"]

    if "bbc." in url:
        for source in soup.find_all("source"):
            if source.get("src") and ".mp3" in source["src"]:
                return source["src"]

    # Generic fallback
    audio = soup.find("audio")
    if audio and audio.get("src"):
        return urljoin(url, audio["src"])

    for source in soup.find_all("source"):
        if source.get("src"):
            return urljoin(url, source["src"])

    match = re.search(r'https?://[^\s"\']+\.(mp3|wav|m4a)', res.text)
    return match.group(0) if match else None

# ---------- Download from normal website ----------
def download_audio(audio_url, output_mp4):
    temp_file = output_mp4.replace(".mp4", ".tmp")
    try:
        with requests.get(audio_url, headers=HEADERS, stream=True) as r:
            r.raise_for_status()
            with open(temp_file, "wb") as f:
                for chunk in r.iter_content(chunk_size=8192):
                    f.write(chunk)
        print(f"✅ Downloaded to {temp_file}")
        convert_any_to_mp4(temp_file, output_mp4)
        os.remove(temp_file)
        return True
    except Exception as e:
        print(f"❌ Download failed: {e}")
        return False

# ---------- Download from YouTube (single video only) ----------
def download_youtube_audio(url, output_mp4):
    base_temp = output_mp4.replace(".mp4", "_yt_temp")
    ydl_opts = {
        'format': 'bestaudio/best',
        'outtmpl': base_temp + '.%(ext)s',
        'quiet': False,
        'noplaylist': True,            # ⭐ CRITICAL: download only one video, not a playlist
        'extract_flat': False,
    }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            # Find the actual downloaded file
            downloaded_file = ydl.prepare_filename(info)
            if not os.path.exists(downloaded_file):
                # Fallback for different extension
                for ext in ['.webm', '.opus', '.m4a']:
                    test_path = base_temp + ext
                    if os.path.exists(test_path):
                        downloaded_file = test_path
                        break
            if not os.path.exists(downloaded_file):
                raise FileNotFoundError(f"Could not locate downloaded file for {url}")

            print(f"✅ YouTube audio saved to {downloaded_file}")
            success = convert_any_to_mp4(downloaded_file, output_mp4) is not None
            os.remove(downloaded_file)
            return success
    except Exception as e:
        print(f"❌ YouTube download failed: {e}")
        return False

# ---------- Process one URL ----------
def process_url(url, index):
    if "youtube.com" in url or "youtu.be" in url:
        out_mp4 = f"downloaded_{index}.mp4"
        return download_youtube_audio(url, out_mp4)
    else:
        audio_url = extract_audio_url(url)
        if audio_url:
            out_mp4 = f"downloaded_{index}.mp4"
            return download_audio(audio_url, out_mp4)
        else:
            print(f"⚠️ No audio link found on {url}")
            return False

# ---------- Main ----------
def main(argvs):
    if not check_ffmpeg():
        sys.exit(1)
    query = "scary jumps scare sound"
    urls = tavily_search(query)
    print(f"🔍 Found {len(urls)} candidate URLs")

    successful = 0
    for i, url in enumerate(urls):
        if successful >= 3:
            break
        print(f"\n--- Processing {i+1}/{len(urls)}: {url} ---")
        if process_url(url, successful + 1):
            successful += 1
            print(f"✅ Success ({successful}/3) downloaded and converted to MP4")
        else:
            print(f"❌ Failed to process {url}")

    print(f"\n🏁 Done. Successfully downloaded and converted {successful} items to MP4.")

if __name__ == "__main__":
    main(sys.argv)
