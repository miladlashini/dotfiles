#!/usr/bin/env python3
"""Read JSON over BLE using Bleak.

Setup:
  python3 -m venv ~/.local/share/ble-vp-json-venv
  ~/.local/share/ble-vp-json-venv/bin/pip install bleak

Examples (use the virtual environment's python if Bleak is not on PATH):
  ble-vp-json.py --scan
  ble-vp-json.py AA:BB:CC:DD:EE:FF --list
  ble-vp-json.py AA:BB:CC:DD:EE:FF --count 0 > vital-parameters.jsonl

Each stdout line is one complete JSON object. Diagnostics go to stderr.
The current firmware uses value handle 22 (0x0016). Discover the actual
characteristic on other firmware and override it with --characteristic.
Firmware replying with handle 52 instead of 22 may cause reads to fail;
this client cannot repair that firmware-side mismatch.
Use only on an authorized test device; captures can contain patient data.
"""

import argparse
import asyncio
import json
import math
import sys


def positive_seconds(text):
    value = float(text)
    if not math.isfinite(value) or value <= 0:
        raise argparse.ArgumentTypeError("must be a finite number greater than zero")
    return value


def nonnegative_integer(text):
    value = int(text)
    if value < 0:
        raise argparse.ArgumentTypeError("must be zero or greater")
    return value


def characteristic_id(text):
    if text.lower().startswith("0x") or text.isdecimal():
        value = int(text, 0) if text.lower().startswith("0x") else int(text)
        if not 1 <= value <= 65535:
            raise argparse.ArgumentTypeError("handle must be between 1 and 65535")
        return value
    return text


async def read_json(client, characteristic, verbose=False, max_reads=16):
    buffer = bytearray()
    last_error = "no JSON received"
    for read_number in range(1, max_reads + 1):
        chunk = await client.read_gatt_char(characteristic)
        if verbose:
            print(f"Read {read_number}: {len(chunk)} bytes", file=sys.stderr)
        if not chunk:
            raise RuntimeError("Received an empty BLE value before completing JSON")
        if not buffer and not chunk.lstrip().startswith(b"{"):
            last_error = "waiting for the beginning of a JSON snapshot"
            continue
        buffer.extend(chunk)
        if len(buffer) > 65536:
            raise RuntimeError("JSON snapshot exceeded the 64 KiB safety limit")
        try:
            document = json.loads(buffer)
        except (json.JSONDecodeError, UnicodeDecodeError) as error:
            last_error = str(error)
            continue
        if not isinstance(document, dict):
            raise RuntimeError("Expected a JSON object from the vital-parameter characteristic")
        return document
    raise RuntimeError(
        f"No complete JSON after {max_reads} reads: {last_error}. "
        "Check the characteristic and firmware response handle; "
        "if capture started mid-snapshot, retry without another active reader."
    )


async def run(args):
    try:
        from bleak import BleakClient, BleakScanner
    except ImportError as error:
        raise RuntimeError(
            "Bleak is required. Run:\n"
            "  python3 -m venv ~/.local/share/ble-vp-json-venv\n"
            "  ~/.local/share/ble-vp-json-venv/bin/pip install bleak\n"
            "Then run this script with that environment's bin/python."
        ) from error

    if args.scan:
        devices = await BleakScanner.discover(timeout=args.timeout)
        for device in devices:
            print(f"{device.address}\t{device.name or '(unnamed)'}")
        if not devices:
            print("No BLE devices found. Check the adapter and device advertising.", file=sys.stderr)
        return

    print(f"Connecting to {args.address} ...", file=sys.stderr)
    async with BleakClient(args.address, timeout=args.timeout, pair=args.pair) as client:
        if args.list:
            for service in client.services:
                print(f"Service {service.uuid}")
                for characteristic in service.characteristics:
                    properties = ", ".join(characteristic.properties)
                    print(
                        f"  0x{characteristic.handle:04x} ({characteristic.handle}) "
                        f"{characteristic.uuid} [{properties}]"
                    )
            return

        characteristic = client.services.get_characteristic(args.characteristic)
        if characteristic is None:
            raise RuntimeError("Characteristic not found. Use --list and --characteristic HANDLE_OR_UUID.")
        if "read" not in characteristic.properties:
            raise RuntimeError("Selected characteristic is not readable. Check --list.")
        print(
            f"Reading {characteristic.uuid}, handle 0x{characteristic.handle:04x}. "
            "Use only one reader for the firmware's shared chunk stream.",
            file=sys.stderr,
        )
        captured = 0
        while args.count == 0 or captured < args.count:
            try:
                document = await asyncio.wait_for(
                    read_json(client, characteristic, args.verbose), timeout=args.timeout
                )
            except asyncio.TimeoutError as error:
                raise RuntimeError(
                    "Timed out reading JSON. Check BLE pairing/permissions and the "
                    "firmware response handle (request 22 must not reply with 52)."
                ) from error
            print(json.dumps(document, separators=(",", ":"), ensure_ascii=True), flush=True)
            captured += 1
            if args.count == 0 or captured < args.count:
                await asyncio.sleep(args.interval)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("address", nargs="?", help="BLE device address from --scan")
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--scan", action="store_true", help="scan for nearby BLE devices")
    modes.add_argument("--list", action="store_true", help="list the device's GATT characteristics")
    parser.add_argument(
        "--characteristic", type=characteristic_id, default=22,
        metavar="HANDLE_OR_UUID", help="value handle or UUID (default: 0x0016)"
    )
    parser.add_argument("--count", type=nonnegative_integer, default=1, help="snapshots to capture (0: continuous)")
    parser.add_argument("--interval", type=positive_seconds, default=1.0, help="seconds between snapshots (default: 1)")
    parser.add_argument("--timeout", type=positive_seconds, default=20.0, help="scan/connect/snapshot timeout in seconds (default: 20)")
    parser.add_argument("--pair", action="store_true", help="request pairing; allow time for any OS pairing prompt")
    parser.add_argument("--verbose", action="store_true", help="log chunk byte counts to stderr")
    args = parser.parse_args(argv)
    if not args.scan and not args.address:
        parser.error("provide a BLE address, or use --scan")
    try:
        asyncio.run(run(args))
    except KeyboardInterrupt:
        return 130
    except BrokenPipeError:
        return 0
    except Exception as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())