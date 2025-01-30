#!/usr/bin/env python3

import argparse
import hashlib
import os
import sys
from datetime import datetime
import base64
import nacl.signing
from xml.etree import ElementTree as ET
from xml.dom import minidom


def calculate_file_hash(file_path):
    """Calculate SHA-256 hash of the file."""
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()


def get_file_size(file_path):
    """Get file size in bytes."""
    return os.path.getsize(file_path)


def sign_update(file_path, ed_signature_key):
    """Sign the update file using Ed25519."""
    try:
        # Decode the base64 private key
        private_key_bytes = base64.b64decode(ed_signature_key)
        signing_key = nacl.signing.SigningKey(private_key_bytes)

        # Read the file content
        with open(file_path, "rb") as f:
            file_content = f.read()

        # Sign the content
        signature = signing_key.sign(file_content)

        # Return base64 encoded signature
        return base64.b64encode(signature.signature).decode('utf-8')
    except Exception as e:
        print(f"Error signing update: {e}")
        sys.exit(1)


def create_appcast(version, file_path, download_url, ed_signature):
    """Create appcast XML structure."""

    # Create root element
    rss = ET.Element("rss")
    rss.set("version", "2.0")
    rss.set("xmlns:sparkle", "http://www.andymatuschak.org/xml-namespaces/sparkle")

    # Add channel(title, description, link)
    channel = ET.SubElement(rss, "channel")
    title = ET.SubElement(channel, "title")
    title.text = "TodoMate 업데이트"
    description = ET.SubElement(channel, "description")
    description.text = "MacOS용 최신 업데이트"
    link = ET.SubElement(channel, "link")
    link.text = "https://github.com/hot666666/TodoMate/releases"

    # Add item(title, description, pubDate, *enclosure)
    item = ET.SubElement(channel, "item")
    title_item = ET.SubElement(item, "title")
    title_item.text = f"Version {version}"
    description_item = ET.SubElement(item, "description")
    description_item.text = f"새로운 업데이트 가능: TodoMate 버전 {version}."
    pub_date = ET.SubElement(item, "pubDate")
    pub_date.text = datetime.now().strftime("%a, %d %b %Y %H:%M:%S +0000")

    # Add enclosure(sparkle:shortVersionString | version | sha256 | edSignature, url, length, type)
    enclosure = ET.SubElement(item, "enclosure")
    enclosure.set("sparkle:shortVersionString", f"{version}")
    enclosure.set("sparkle:version", f"{1}")
    enclosure.set("sparkle:sha256", calculate_file_hash(file_path))
    enclosure.set("sparkle:edSignature", sign_update(file_path, ed_signature))
    enclosure.set("url", download_url)
    enclosure.set("length", str(get_file_size(file_path)))
    enclosure.set("type", "application/octet-stream")

    return rss


def prettify_xml(elem):
    """Return a pretty-printed XML string for the Element."""
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ")


def main():
    parser = argparse.ArgumentParser(
        description='Generate Sparkle appcast.xml')
    parser.add_argument('--version', required=True,
                        help='Version number of the release')
    parser.add_argument('--path', required=True, help='Path to the ZIP file')
    parser.add_argument('--url', required=True,
                        help='Download URL for the release')
    parser.add_argument(
        '--edSignature', help='Ed25519 private key for signing')

    args = parser.parse_args()

    # Verify file exists
    if not os.path.exists(args.path):
        print(f"Error: File not found at {args.path}")
        sys.exit(1)

    # Create appcast
    appcast = create_appcast(args.version, args.path,
                             args.url, args.edSignature)

    # Write to file
    with open("appcast.xml", "w", encoding='utf-8') as f:
        f.write(prettify_xml(appcast))

    print("Successfully generated appcast.xml")


if __name__ == "__main__":
    main()
