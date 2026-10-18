#!/usr/bin/env python3
"""Ajoute ou remplace une version dans l'appcast Sparkle de Kastideo.

Utilisé par le workflow Release (branche « appcast » du dépôt) :

    python3 scripts/appcast.py --appcast appcast.xml --version 0.2.0 --build 12 \\
        --url https://github.com/.../Kastideo-0.2.0.dmg --length 12345 \\
        --signature "base64..." --notes notes.md [--channel beta]
"""
import argparse
import html
import os
import re
import sys
import xml.etree.ElementTree as ET
from email.utils import formatdate

SPARKLE = "http://www.andymatuschak.org/xml-namespaces/sparkle"
DC = "http://purl.org/dc/elements/1.1/"
ET.register_namespace("sparkle", SPARKLE)
ET.register_namespace("dc", DC)
MAX_ITEMS = 40


def sp(tag):
    return f"{{{SPARKLE}}}{tag}"


def markdown_to_html(text):
    """Convertit les notes (puces « - » et **gras**) en HTML simple pour la fenêtre Sparkle."""
    def inline(s):
        s = html.escape(s)
        s = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", s)
        s = re.sub(r"`(.+?)`", r"<code>\1</code>", s)
        return s

    parts, in_list = [], False
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith(("- ", "* ")):
            if not in_list:
                parts.append("<ul>")
                in_list = True
            parts.append(f"<li>{inline(line[2:])}</li>")
            continue
        if in_list:
            parts.append("</ul>")
            in_list = False
        if line:
            parts.append(f"<p>{inline(line)}</p>")
    if in_list:
        parts.append("</ul>")
    return "\n".join(parts) or "<p>Améliorations et corrections.</p>"


def load_or_create(path):
    if os.path.exists(path) and os.path.getsize(path) > 0:
        tree = ET.parse(path)
        return tree, tree.getroot().find("channel")
    rss = ET.Element("rss", {"version": "2.0"})
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = "Kastideo"
    ET.SubElement(channel, "link").text = "https://github.com/jihemezes/kastideo"
    ET.SubElement(channel, "description").text = "Mises à jour de Kastideo"
    ET.SubElement(channel, "language").text = "fr"
    return ET.ElementTree(rss), channel


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--appcast", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--build", required=True)
    parser.add_argument("--url", required=True)
    parser.add_argument("--length", required=True)
    parser.add_argument("--signature", required=True)
    parser.add_argument("--notes", required=True)
    parser.add_argument("--min-system", default="14.0")
    parser.add_argument("--channel", default="")
    args = parser.parse_args()

    tree, channel = load_or_create(args.appcast)

    # Retire une éventuelle entrée existante pour la même version (republication).
    for item in list(channel.findall("item")):
        short = item.find(sp("shortVersionString"))
        if short is not None and short.text == args.version:
            channel.remove(item)

    notes = open(args.notes, encoding="utf-8").read() if os.path.exists(args.notes) else ""

    item = ET.Element("item")
    ET.SubElement(item, "title").text = f"Kastideo {args.version}"
    ET.SubElement(item, "pubDate").text = formatdate(usegmt=True)
    ET.SubElement(item, sp("version")).text = str(args.build)
    ET.SubElement(item, sp("shortVersionString")).text = args.version
    ET.SubElement(item, sp("minimumSystemVersion")).text = args.min_system
    if args.channel:
        ET.SubElement(item, sp("channel")).text = args.channel
    ET.SubElement(item, "description").text = markdown_to_html(notes)
    ET.SubElement(item, "enclosure", {
        "url": args.url,
        "length": str(args.length),
        "type": "application/octet-stream",
        sp("edSignature"): args.signature,
    })

    # Nouvelle version en tête de liste, après les métadonnées du canal.
    items = channel.findall("item")
    index = list(channel).index(items[0]) if items else len(channel)
    channel.insert(index, item)
    for old in channel.findall("item")[MAX_ITEMS:]:
        channel.remove(old)

    ET.indent(tree, space="  ")
    tree.write(args.appcast, encoding="utf-8", xml_declaration=True)
    print(f"Appcast mis à jour : {args.version} (build {args.build}){' [' + args.channel + ']' if args.channel else ''}")


if __name__ == "__main__":
    sys.exit(main())
