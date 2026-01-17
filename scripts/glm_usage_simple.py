#!/usr/bin/env python3
"""Simple GLM monthly usage percentage output for tmux status bar - with auto-caching"""

import os
import json
import time
import urllib.request
from urllib.parse import urlparse
from pathlib import Path

CACHE_FILE = '/tmp/.glm_usage_cache'
CACHE_TTL = 60  # seconds
OPENCODE_SETTINGS_FILE = Path.home() / '.config' / 'opencode' / 'opencode.json'
CLAUDE_SETTINGS_FILE = Path.home() / '.claude' / 'settings.json'

def get_env_from_settings():
    """Read env values from opencode.json (1st priority) or ~/.claude/settings.json (fallback)"""
    try:
        with open(OPENCODE_SETTINGS_FILE, 'r') as f:
            settings = json.load(f)
            env = settings.get('env', {})
            if env:
                return env
    except Exception:
        pass

    try:
        with open(CLAUDE_SETTINGS_FILE, 'r') as f:
            settings = json.load(f)
            return settings.get('env', {})
    except Exception:
        return {}

def get_usage(query_type: str = 'TOKENS_LIMIT'):
    env = get_env_from_settings()
    auth_token = env.get('ANTHROPIC_AUTH_TOKEN', '')
    base_url = env.get('ANTHROPIC_BASE_URL', '')

    if not auth_token or not base_url:
        return None

    parsed = urlparse(base_url)
    base_domain = f"{parsed.scheme}://{parsed.netloc}"
    url = f"{base_domain}/api/monitor/usage/quota/limit"

    headers = {
        'Authorization': auth_token,
        'Accept-Language': 'en-US,en',
        'Content-Type': 'application/json'
    }

    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
            limits = data.get('data', {}).get('limits', [])
            for item in limits:
                if item.get('type') == query_type:
                    return f"{item.get('percentage', 0)}%"
    except Exception:
        pass
    return None

def get_cached_or_fetch():
    # Check if cache exists and is fresh
    try:
        if os.path.exists(CACHE_FILE):
            age = time.time() - os.path.getmtime(CACHE_FILE)
            if age < CACHE_TTL:
                with open(CACHE_FILE, 'r') as f:
                    return f.read()
    except Exception:
        pass

    # Fetch new data and cache it
    usage = get_usage()
    value = usage if usage else "--"
    try:
        with open(CACHE_FILE, 'w') as f:
            f.write(value)
    except Exception:
        pass
    return value

if __name__ == '__main__':
    print(get_cached_or_fetch(), end='')
