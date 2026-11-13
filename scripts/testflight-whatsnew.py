#!/usr/bin/env python3
"""Renseigne le champ « Quoi tester » (fr-FR et en-US) du build TestFlight qui vient d'être envoyé,
à partir de la section du tag dans iOS/CHANGELOG.md. N'échoue jamais le workflow : en cas de problème, avertissement seulement.

Variables : APPLE_API_KEY_ID, APPLE_API_ISSUER_ID, KEY_PATH, VERSION (X.Y.Z), BUILD (numéro de build), TAG (vX.Y.Z-iosN)."""
import json, os, re, sys, time, urllib.request, urllib.error, urllib.parse

import jwt  # PyJWT + cryptography

API = "https://api.appstoreconnect.apple.com"
KEY_ID, ISSUER, KEY_PATH = os.environ["APPLE_API_KEY_ID"], os.environ["APPLE_API_ISSUER_ID"], os.environ["KEY_PATH"]
VERSION, BUILD, TAG = os.environ["VERSION"], os.environ["BUILD"], os.environ["TAG"]
BUNDLE_ID = "fr.jmezes.kastideo"


def token():
    now = int(time.time())
    return jwt.encode({"iss": ISSUER, "iat": now, "exp": now + 1000, "aud": "appstoreconnect-v1"},
                      open(KEY_PATH).read(), algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"})


def call(method, path, body=None, query=None):
    url = API + path + ("?" + urllib.parse.urlencode(query) if query else "")
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method,
                                 headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read()
            return r.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        return e.code, {"error": e.read().decode()[:600]}


def changelog_text():
    name = TAG.lstrip("v")
    try:
        text = open("iOS/CHANGELOG.md", encoding="utf-8").read()
    except OSError:
        return None
    m = re.search(r"^## \[" + re.escape(name) + r"\][^\n]*\n(.*?)(?=^## \[|\Z)", text, re.S | re.M)
    if not m:
        return None
    body = m.group(1).strip()
    body = re.sub(r"\*\*(.+?)\*\*", r"\1", body)
    body = re.sub(r"`(.+?)`", r"\1", body)
    body = re.sub(r"^\s*[-*] ", "• ", body, flags=re.M)
    return body[:3900]


def main():
    fr = changelog_text() or f"Version {VERSION} (build {BUILD}). Voir le journal des versions pour le détail."
    en = f"Version {VERSION} (build {BUILD}). Release notes are written in French; ask for details if needed.\n\n" + fr
    code, apps = call("GET", "/v1/apps", query={"filter[bundleId]": BUNDLE_ID})
    if code != 200 or not apps.get("data"):
        print("::warning::App introuvable dans App Store Connect", apps); return
    app_id = apps["data"][0]["id"]

    build_id = None
    deadline = time.time() + 25 * 60
    while time.time() < deadline and not build_id:
        code, res = call("GET", "/v1/builds", query={"filter[app]": app_id, "filter[version]": BUILD,
                                                     "filter[preReleaseVersion.version]": VERSION, "limit": 5})
        if code == 200 and res.get("data"):
            build_id = res["data"][0]["id"]
            break
        print("Build pas encore visible chez Apple, nouvel essai dans 60 s…", code)
        time.sleep(60)
    if not build_id:
        print("::warning::Build introuvable : « Quoi tester » non renseigné (à saisir à la main dans TestFlight)."); return

    code, existing = call("GET", f"/v1/builds/{build_id}/betaBuildLocalizations")
    by_locale = {x["attributes"]["locale"]: x["id"] for x in existing.get("data", [])} if code == 200 else {}
    for locale, text in (("fr-FR", fr), ("en-US", en)):
        if locale in by_locale:
            code, res = call("PATCH", f"/v1/betaBuildLocalizations/{by_locale[locale]}",
                             {"data": {"type": "betaBuildLocalizations", "id": by_locale[locale], "attributes": {"whatsNew": text}}})
        else:
            code, res = call("POST", "/v1/betaBuildLocalizations",
                             {"data": {"type": "betaBuildLocalizations", "attributes": {"locale": locale, "whatsNew": text},
                                       "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}}})
        print(locale, code, "" if code < 300 else res)
        if code >= 300:
            print(f"::warning::« Quoi tester » {locale} refusé par Apple (code {code}).")


try:
    main()
except Exception as exc:  # jamais bloquant
    print("::warning::Quoi tester : erreur", exc)
sys.exit(0)
