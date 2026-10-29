#!/usr/bin/env python3
"""Capture vital parameters over BLE or Bluetooth Classic.

Setup:
  python3 -m venv ~/.local/share/ble-vp-json-venv
  ~/.local/share/ble-vp-json-venv/bin/pip install bleak

The vital-parameter characteristic requires an LE bond. Without one, reads
never complete: the device requests numeric-comparison pairing, which needs
a BlueZ agent. Pair once with --pair, which registers this script as the
pairing agent and asks in the terminal to confirm the passkey shown on the
device. The bond persists, so later runs do not need --pair.

BLE remains the default. Linux Classic mode uses BlueZ pairing, RFCOMM, and
the binary EDCOMM SDK protocol, not the BLE JSON characteristic. SDP discovery
requires BlueZ's sdptool; --channel bypasses discovery when the SDK channel is
known. --pair uses hci0 and PreferredBearer=bredr, which may require
Experimental = true in /etc/bluetooth/main.conf. Existing bonds are not removed.
Classic output has transport=classic, zero-based SDK VP IDs, timestamps, raw
words, numeric value, unit/display_unit codes, factor, offset, and optional IBP
alias. value = decoded_raw / factor - offset, in unit (not display_unit).
It is not the BLE wire JSON schema or its numeric encoding. SDK authorization
errors are reported; this client does not supply SDK authentication secrets.

Examples (use the virtual environment's python if Bleak is not on PATH):
  ble-vp-json.py --scan
  ble-vp-json.py AA:BB:CC:DD:EE:FF --pair --list
  ble-vp-json.py AA:BB:CC:DD:EE:FF --list
  ble-vp-json.py AA:BB:CC:DD:EE:FF --count 0 > vital-parameters.jsonl
    ble-vp-json.py --transport classic --scan
    ble-vp-json.py AA:BB:CC:DD:EE:FF --transport classic --pair --list --timeout 60
    ble-vp-json.py AA:BB:CC:DD:EE:FF --transport classic --channel 4 --count 0

Redirected stdout gets one complete JSON object per line, and the terminal
(stderr) shows each snapshot as indented JSON. When stdout is the terminal,
it shows only the indented JSON. Diagnostics go to stderr.
The current firmware uses value handle 22 (0x0016). Discover the actual
characteristic on other firmware and override it with --characteristic.
Firmware replying with handle 52 instead of 22 may cause reads to fail;
this client cannot repair that firmware-side mismatch.
Use only on an authorized test device; captures can contain patient data.
"""

import argparse
import asyncio
import contextlib
import json
import math
import re
import socket
import struct
import sys
import xml.etree.ElementTree as ET

# Value handle 22 (0x0016). Bleak on BlueZ lists it as declaration handle 21.
VP_CHARACTERISTIC_UUID = "00000003-0000-0002-0203-00ae6d73100d"
PAIRING_AGENT_PATH = "/ble_vp_json/agent"
EDCOMM_HEADER = struct.Struct("<BBBBHHIHH")
EDCOMM_REQUEST = 1
EDCOMM_ACK = 2
EDCOMM_RESPONSE = 3
VP_VECTOR_COMMAND = 0x021D
VP_INFORMATION_COMMAND = 0x021E


def edcomm_checksum(data):
    padded = data + b"\x00" if len(data) % 2 else data
    total = sum(value[0] for value in struct.iter_unpack("<H", padded))
    while total >> 16:
        total = (total & 0xFFFF) + (total >> 16)
    return (~total) & 0xFFFF


def edcomm_packet(message_type, sequence, command, payload=b"", status=0):
    header = EDCOMM_HEADER.pack(
        0x24, 0xC3, message_type, sequence, 0,
        edcomm_checksum(payload) if payload else 0, len(payload), command, status,
    )
    checksum = edcomm_checksum(header)
    return header[:4] + struct.pack("<H", checksum) + header[6:] + payload


async def read_edcomm_packet(reader):
    header = await reader.readexactly(EDCOMM_HEADER.size)
    version, sync, message_type, sequence, _, payload_checksum, length, command, status = EDCOMM_HEADER.unpack(header)
    if version != 0x24 or sync != 0xC3 or edcomm_checksum(header) != 0:
        raise RuntimeError("Invalid EDCOMM header or header checksum")
    if message_type not in (EDCOMM_REQUEST, EDCOMM_ACK, EDCOMM_RESPONSE, 4):
        raise RuntimeError(f"Unknown EDCOMM message type {message_type}")
    if length > 4096:
        raise RuntimeError("EDCOMM payload exceeds the 4096-byte capture limit")
    payload = await reader.readexactly(length)
    if payload_checksum != (edcomm_checksum(payload) if payload else 0):
        raise RuntimeError("Invalid EDCOMM payload checksum")
    return message_type, sequence, command, status, payload


def check_edcomm_status(command, status):
    if status:
        detail = " SDK authorization required" if status == 0x22 else ""
        raise RuntimeError(f"EDCOMM command 0x{command:04x} failed: status 0x{status:04x}.{detail}")


class ClassicEdcomm:
    def __init__(self, reader, writer, verbose=False):
        self.reader = reader
        self.writer = writer
        self.verbose = verbose
        self.sequence = 0

    async def send(self, message_type, sequence, command, payload=b"", status=0):
        self.writer.write(edcomm_packet(message_type, sequence, command, payload, status))
        await self.writer.drain()

    async def receive(self):
        packet = await read_edcomm_packet(self.reader)
        if self.verbose:
            message_type, sequence, command, status, payload = packet
            print(
                f"Classic RX type={message_type} seq={sequence} cmd=0x{command:04x} "
                f"status=0x{status:04x} bytes={len(payload)}", file=sys.stderr,
            )
        return packet

    async def reply_to_device(self, packet):
        _, sequence, command, _, payload = packet
        if command not in (0x0001, 0x0003) or payload:
            await self.send(EDCOMM_ACK, sequence, command, status=0x0004)
            raise RuntimeError(f"Unsupported device handshake request 0x{command:04x}")
        await self.send(EDCOMM_ACK, sequence, command)
        if command == 0x0001:
            response = struct.pack("<IIIB", 2, 1, 3, 0)
        else:
            response = struct.pack("<II", 1, 3) + b"python-sdk\x001.0\x00Python SDK\x00"
        await self.send(EDCOMM_RESPONSE, sequence, command, response)
        return command

    async def handshake(self):
        seen = set()
        while seen != {0x0001, 0x0003}:
            packet = await self.receive()
            message_type, _, command, status, _ = packet
            if message_type == EDCOMM_REQUEST:
                seen.add(await self.reply_to_device(packet))
            elif message_type == EDCOMM_ACK:
                check_edcomm_status(command, status)
            else:
                raise RuntimeError("Expected the device's WHO_ARE_YOU / GET_DEVICE_INFO handshake")

    async def request(self, command):
        self.sequence = (self.sequence + 1) & 0xFF
        sequence = self.sequence
        await self.send(EDCOMM_REQUEST, sequence, command)
        while True:
            packet = await self.receive()
            message_type, received_sequence, received_command, status, payload = packet
            if message_type == EDCOMM_REQUEST:
                await self.reply_to_device(packet)
                continue
            if message_type == EDCOMM_RESPONSE:
                await self.send(EDCOMM_ACK, received_sequence, received_command)
                if (received_sequence, received_command) != (sequence, command):
                    raise RuntimeError("Unexpected EDCOMM response command or sequence")
                check_edcomm_status(command, status)
                return payload
            if message_type == EDCOMM_ACK:
                check_edcomm_status(received_command, status)


def decode_vp_information(payload):
    if len(payload) < 4:
        raise RuntimeError("Truncated Classic VP information")
    count, = struct.unpack_from("<I", payload)
    if count > 30 or len(payload) != 4 + count * 28:
        raise RuntimeError("Invalid Classic VP information count or length")
    return list(struct.iter_unpack("<7I", payload[4:]))


def decode_vp_vector(payload, information):
    if len(payload) < 8:
        raise RuntimeError("Truncated Classic VP vector")
    count, timestamp = struct.unpack_from("<II", payload)
    if count > 30 or len(payload) != 8 + count * 12:
        raise RuntimeError("Invalid Classic VP vector count or length")
    values = []
    seen = set()
    for identifier, sample_timestamp, raw in struct.iter_unpack("<III", payload[8:]):
        if identifier >= len(information) or identifier in seen:
            raise RuntimeError("Unknown or duplicate Classic VP identifier")
        seen.add(identifier)
        unit, display_unit, _, _, factor, offset, _ = information[identifier]
        if not factor:
            raise RuntimeError(f"Invalid zero factor for Classic VP {identifier}")
        value = raw if raw < 0x80000000 else raw - 0x100000000
        entry = {
            "id": identifier, "timestamp": sample_timestamp, "raw": raw,
            "unit": unit, "display_unit": display_unit, "factor": factor, "offset": offset,
        }
        if identifier in (8, 11, 14, 17):
            if ((raw >> 28) & 7) == 3 and not raw & 0x80000000:
                value = raw & 0x3FF
                alias = (raw >> 10) & 7
                if alias <= 4:
                    entry["alias"] = alias
            elif raw > 0x3FF:
                raise RuntimeError(f"Unsupported packed IBP SYS format for Classic VP {identifier}")
        entry["value"] = value / factor - offset
        values.append(entry)
    return {"transport": "classic", "timestamp": timestamp, "vp": values}


def parse_rfcomm_services(text):
    text = re.sub(r"<\?xml[^?]*\?>", "", text)
    try:
        root = ET.fromstring("<records>" + text + "</records>")
    except ET.ParseError as error:
        raise RuntimeError("Invalid SDP XML; use --channel with a verified RFCOMM channel") from error
    services = []
    for record in root.findall("record"):
        name = record.find("./attribute[@id='0x0100']/text")
        for descriptor in record.findall("./attribute[@id='0x0004']/sequence/sequence"):
            protocol = descriptor.find("uuid")
            channel = descriptor.find("uint8")
            if protocol is None or channel is None:
                continue
            if protocol.get("value", "").lower() not in (
                "0x0003", "0x03", "00000003-0000-1000-8000-00805f9b34fb",
            ):
                continue
            try:
                number = int(channel.attrib["value"], 0)
            except (KeyError, ValueError) as error:
                raise RuntimeError("Invalid SDP RFCOMM channel") from error
            if not 1 <= number <= 30:
                raise RuntimeError("SDP RFCOMM channel must be between 1 and 30")
            services.append((number, name.get("value", "(unnamed)") if name is not None else "(unnamed)"))
    return services


async def discover_rfcomm_services(address, timeout):
    try:
        process = await asyncio.create_subprocess_exec(
            "sdptool", "browse", "--xml", address,
            stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
        )
    except FileNotFoundError as error:
        raise RuntimeError(
            "Classic service discovery needs BlueZ's sdptool; install the BlueZ utilities "
            "or supply --channel with the device's verified RFCOMM channel."
        ) from error
    try:
        stdout, stderr = await asyncio.wait_for(process.communicate(), timeout)
    except BaseException:
        if process.returncode is None:
            process.kill()
        await process.communicate()
        raise
    if process.returncode:
        raise RuntimeError(f"SDP discovery failed: {stderr.decode(errors='replace').strip()}")
    services = parse_rfcomm_services(stdout.decode(errors="replace"))
    if not services:
        raise RuntimeError("No RFCOMM service found. Check Classic discoverability, pairing, and SDK availability.")
    return services


async def bluez_call(bus, path, interface, member, signature="", body=None):
    from dbus_fast import Message, MessageType

    reply = await bus.call(Message(
        destination="org.bluez", path=path, interface=interface, member=member,
        signature=signature, body=body or [],
    ))
    if reply.message_type == MessageType.ERROR:
        raise RuntimeError(f"BlueZ {member} failed: {reply.error_name}")
    return reply.body


async def classic_devices(bus, timeout, address=None):
    from dbus_fast import Variant

    async def known_devices():
        body = await bluez_call(bus, "/", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects")
        return [
            (path, interfaces["org.bluez.Device1"])
            for path, interfaces in body[0].items()
            if path.startswith("/org/bluez/hci0/") and "org.bluez.Device1" in interfaces
        ]

    def contains_address(devices):
        return any(properties.get("Address") and properties["Address"].value.upper() == address for _, properties in devices)

    devices = await known_devices()
    if address and contains_address(devices):
        return devices
    await bluez_call(bus, "/org/bluez/hci0", "org.bluez.Adapter1", "SetDiscoveryFilter", "a{sv}",
                     [{"Transport": Variant("s", "bredr")}])
    await bluez_call(bus, "/org/bluez/hci0", "org.bluez.Adapter1", "StartDiscovery")
    try:
        loop = asyncio.get_running_loop()
        deadline = loop.time() + timeout
        while loop.time() < deadline:
            devices = await known_devices()
            if address and contains_address(devices):
                break
            await asyncio.sleep(min(0.25, max(0, deadline - loop.time())))
        return await known_devices()
    finally:
        await bluez_call(bus, "/org/bluez/hci0", "org.bluez.Adapter1", "StopDiscovery")


async def prepare_classic(args):
    from dbus_fast import BusType, Message, MessageType, Variant
    from dbus_fast.aio import MessageBus

    bus = await MessageBus(bus_type=BusType.SYSTEM).connect()
    try:
        devices = await classic_devices(bus, args.timeout, None if args.scan else args.address.upper())
        if args.scan:
            for _, properties in devices:
                if "Address" in properties:
                    name = properties.get("Name") or properties.get("Alias")
                    print(f"{properties['Address'].value}\t{name.value if name else '(unnamed)'}")
            print("Listed known/discovered BlueZ devices on hci0 after a BR/EDR scan.", file=sys.stderr)
            return
        path = next((path for path, properties in devices
                     if properties.get("Address") and properties["Address"].value.upper() == args.address.upper()), None)
        if path is None:
            raise RuntimeError("Classic device not found. Enable BR/EDR discoverability and retry --scan.")
        try:
            await bluez_call(bus, path, "org.freedesktop.DBus.Properties", "Set", "ssv",
                             ["org.bluez.Device1", "PreferredBearer", Variant("s", "bredr")])
        except RuntimeError as error:
            raise RuntimeError(
                "Cannot select Classic for pairing. Enable Experimental = true in "
                "/etc/bluetooth/main.conf if PreferredBearer is unsupported, or pair "
                "over BR/EDR externally and retry without --pair. " + str(error)
            ) from error
        print("Pairing over Bluetooth Classic ...", file=sys.stderr)
        try:
            reply = await asyncio.wait_for(bus.call(Message(
                destination="org.bluez", path=path, interface="org.bluez.Device1", member="Pair",
            )), args.timeout)
        except (asyncio.TimeoutError, asyncio.CancelledError):
            with contextlib.suppress(RuntimeError, asyncio.TimeoutError):
                await asyncio.wait_for(bluez_call(bus, path, "org.bluez.Device1", "CancelPairing"), args.timeout)
            raise
        if reply.message_type == MessageType.ERROR and reply.error_name != "org.bluez.Error.AlreadyExists":
            raise RuntimeError(f"Classic pairing failed: {reply.error_name}")
    finally:
        bus.disconnect()


def output_document(document):
    pretty = json.dumps(document, indent=2, ensure_ascii=False)
    if sys.stdout.isatty():
        print(pretty, flush=True)
    else:
        print(json.dumps(document, separators=(",", ":"), ensure_ascii=True), flush=True)
        print(pretty, file=sys.stderr, flush=True)


async def run_classic(args):
    if not sys.platform.startswith("linux") or not hasattr(socket, "AF_BLUETOOTH"):
        raise RuntimeError("Classic RFCOMM capture currently requires Linux with Bluetooth socket support")
    agent = pairing_agent() if args.pair and not args.scan else contextlib.nullcontext()
    async with agent:
        if args.scan or args.pair:
            await prepare_classic(args)
        if args.scan:
            return
        services = await discover_rfcomm_services(args.address, args.timeout) if args.list or args.channel is None else []
        if args.list:
            for channel, name in services:
                print(f"RFCOMM channel {channel}\t{name}")
            return
        channels = {channel for channel, _ in services}
        if args.channel is None and len(channels) != 1:
            choices = ", ".join(f"{channel} ({name})" for channel, name in services)
            raise RuntimeError(f"Multiple RFCOMM services: {choices}. Select the SDK service with --channel.")
        channel = args.channel if args.channel is not None else channels.pop()
        print(f"Connecting via Classic RFCOMM to {args.address}, channel {channel} ...", file=sys.stderr)
        classic_socket = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)
        try:
            classic_socket.setblocking(False)
            await asyncio.wait_for(asyncio.get_running_loop().sock_connect(classic_socket, (args.address, channel)), args.timeout)
            reader, writer = await asyncio.open_connection(sock=classic_socket)
            try:
                client = ClassicEdcomm(reader, writer, args.verbose)
                await asyncio.wait_for(client.handshake(), args.timeout)
                captured = 0
                while args.count == 0 or captured < args.count:
                    async def snapshot():
                        information = decode_vp_information(await client.request(VP_INFORMATION_COMMAND))
                        return decode_vp_vector(await client.request(VP_VECTOR_COMMAND), information)

                    document = await asyncio.wait_for(snapshot(), args.timeout)
                    output_document(document)
                    captured += 1
                    if args.count == 0 or captured < args.count:
                        await asyncio.sleep(args.interval)
            finally:
                writer.close()
                with contextlib.suppress(OSError, asyncio.TimeoutError):
                    await asyncio.wait_for(writer.wait_closed(), args.timeout)
        except asyncio.TimeoutError as error:
            raise RuntimeError("Classic connection/handshake/read timed out; check the SDK RFCOMM service and Classic bond") from error
        except asyncio.IncompleteReadError as error:
            raise RuntimeError("Classic device disconnected before a complete EDCOMM packet arrived") from error
        finally:
            classic_socket.close()


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


async def prefer_le_bearer(device):
    """Make BlueZ connect over LE instead of BR/EDR.

    The device advertises without the "BR/EDR Not Supported" flag and uses a
    public address, so BlueZ treats it as dual-mode and Device1.Connect() tries
    BR/EDR first, failing with BREDR.ProfileUnavailable. PreferredBearer needs
    bluetoothd started with experimental features (Experimental = true).
    """
    from dbus_fast import BusType, Message, MessageType, Variant
    from dbus_fast.aio import MessageBus

    bus = await MessageBus(bus_type=BusType.SYSTEM).connect()
    try:
        reply = await bus.call(Message(
            destination="org.bluez",
            path=device.details["path"],
            interface="org.freedesktop.DBus.Properties",
            member="Set",
            signature="ssv",
            body=["org.bluez.Device1", "PreferredBearer", Variant("s", "le")],
        ))
    finally:
        bus.disconnect()
    if reply.message_type == MessageType.ERROR:
        print(
            f"Warning: could not set PreferredBearer=le ({reply.error_name}). "
            "If connecting fails with BREDR.ProfileUnavailable, set "
            "'Experimental = true' in /etc/bluetooth/main.conf and restart bluetooth.",
            file=sys.stderr,
        )


def ask_terminal(question):
    """Ask on the controlling terminal, so it works with stdout redirected."""
    try:
        with open("/dev/tty", "r+") as tty:
            tty.write(question)
            tty.flush()
            return tty.readline().strip()
    except OSError:
        return ""


def make_pairing_agent():
    """Return an org.bluez.Agent1 that handles pairing requests in the terminal."""
    from dbus_fast import DBusError
    from dbus_fast.annotations import DBusObjectPath, DBusStr, DBusUInt16, DBusUInt32
    from dbus_fast.service import ServiceInterface, dbus_method

    async def ask(question):
        return await asyncio.get_running_loop().run_in_executor(None, ask_terminal, question)

    def reject(reason):
        raise DBusError("org.bluez.Error.Rejected", reason)

    class PairingAgent(ServiceInterface):
        def __init__(self):
            super().__init__("org.bluez.Agent1")

        @dbus_method()
        def Release(self) -> None:
            pass

        @dbus_method()
        async def RequestConfirmation(self, device: DBusObjectPath, passkey: DBusUInt32) -> None:
            answer = await ask(f"Confirm that the device shows passkey {passkey:06d} (yes/no): ")
            # Typing the passkey itself also confirms it.
            if answer.lower() not in ("y", "yes", f"{passkey:06d}"):
                reject("passkey not confirmed")

        @dbus_method()
        async def RequestPasskey(self, device: DBusObjectPath) -> DBusUInt32:
            answer = await ask("Enter the passkey shown on the device: ")
            if not answer.isdecimal() or int(answer) > 999999:
                reject("no valid passkey entered")
            return int(answer)

        @dbus_method()
        async def RequestPinCode(self, device: DBusObjectPath) -> DBusStr:
            answer = await ask("Enter the PIN code for the device: ")
            if not answer:
                reject("no PIN code entered")
            return answer

        @dbus_method()
        def DisplayPasskey(self, device: DBusObjectPath, passkey: DBusUInt32, entered: DBusUInt16) -> None:
            if entered == 0:
                print(f"Enter passkey {passkey:06d} on the device.", file=sys.stderr)

        @dbus_method()
        def DisplayPinCode(self, device: DBusObjectPath, pincode: DBusStr) -> None:
            print(f"Enter PIN code {pincode} on the device.", file=sys.stderr)

        @dbus_method()
        async def RequestAuthorization(self, device: DBusObjectPath) -> None:
            answer = await ask("Accept pairing with the device (yes/no): ")
            if answer.lower() not in ("y", "yes"):
                reject("pairing not accepted")

        @dbus_method()
        def AuthorizeService(self, device: DBusObjectPath, uuid: DBusStr) -> None:
            pass

        @dbus_method()
        def Cancel(self) -> None:
            print("Pairing request cancelled.", file=sys.stderr)

    return PairingAgent()


@contextlib.asynccontextmanager
async def pairing_agent():
    """Register a terminal pairing agent as BlueZ's default agent while active."""
    from dbus_fast import BusType, Message, MessageType
    from dbus_fast.aio import MessageBus

    def agent_manager_call(member, signature, body):
        return bus.call(Message(
            destination="org.bluez",
            path="/org/bluez",
            interface="org.bluez.AgentManager1",
            member=member,
            signature=signature,
            body=body,
        ))

    bus = await MessageBus(bus_type=BusType.SYSTEM).connect()
    try:
        bus.export(PAIRING_AGENT_PATH, make_pairing_agent())
        for member, signature, body in (
            ("RegisterAgent", "os", [PAIRING_AGENT_PATH, "KeyboardDisplay"]),
            ("RequestDefaultAgent", "o", [PAIRING_AGENT_PATH]),
        ):
            reply = await agent_manager_call(member, signature, body)
            if reply.message_type == MessageType.ERROR:
                raise RuntimeError(f"Could not register the pairing agent ({member}: {reply.error_name}).")
        yield
    finally:
        await agent_manager_call("UnregisterAgent", "o", [PAIRING_AGENT_PATH])
        bus.disconnect()


async def run(args):
    if args.transport == "classic":
        await run_classic(args)
        return
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

    device = await BleakScanner.find_device_by_address(args.address, timeout=args.timeout)
    if device is None and sys.platform.startswith("linux"):
        # A connected peripheral stops advertising; reuse BlueZ's device object.
        from bleak.backends.device import BLEDevice

        path = "/org/bluez/hci0/dev_" + args.address.upper().replace(":", "_")
        device = BLEDevice(args.address, None, {"path": path, "props": {}})
    if device is None:
        raise RuntimeError(f"Device {args.address} not found. Check that it is advertising.")
    if sys.platform.startswith("linux"):
        await prefer_le_bearer(device)

    print(f"Connecting to {args.address} ...", file=sys.stderr)
    agent = pairing_agent() if args.pair else contextlib.nullcontext()
    async with agent, BleakClient(device, timeout=args.timeout) as client:
        if args.pair:
            # Pairs over the established LE link; returns at once if already bonded.
            print("Pairing ...", file=sys.stderr)
            await client.pair()
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
                    "Timed out reading JSON. Check that the device is bonded "
                    "('bluetoothctl info ADDRESS' shows 'Paired: yes'; otherwise run once "
                    "with --pair) and the "
                    "firmware response handle (request 22 must not reply with 52)."
                ) from error
            output_document(document)
            captured += 1
            if args.count == 0 or captured < args.count:
                await asyncio.sleep(args.interval)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("address", nargs="?", help="Bluetooth device address from --scan")
    parser.add_argument("--transport", choices=("ble", "classic"), default="ble", help="Bluetooth transport (default: ble)")
    parser.add_argument("--channel", type=int, help="Classic SDK RFCOMM channel (1-30); otherwise discover using sdptool")
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--scan", action="store_true", help="scan for devices on the selected transport")
    modes.add_argument("--list", action="store_true", help="list BLE GATT characteristics or Classic RFCOMM services")
    parser.add_argument(
        "--characteristic", type=characteristic_id, default=VP_CHARACTERISTIC_UUID,
        metavar="HANDLE_OR_UUID",
        help="Bleak handle (as shown by --list) or UUID (default: value handle 0x0016)"
    )
    parser.add_argument("--count", type=nonnegative_integer, default=1, help="snapshots to capture (0: continuous)")
    parser.add_argument("--interval", type=positive_seconds, default=1.0, help="seconds between snapshots (default: 1)")
    parser.add_argument("--timeout", type=positive_seconds, default=20.0, help="scan/connect/snapshot timeout in seconds (default: 20)")
    parser.add_argument("--pair", action="store_true", help="pair (bond) with the device first, confirming the passkey in this terminal")
    parser.add_argument("--verbose", action="store_true", help="log BLE chunk sizes or Classic packet headers to stderr")
    args = parser.parse_args(argv)
    if args.channel is not None and (args.transport != "classic" or not 1 <= args.channel <= 30):
        parser.error("--channel requires --transport classic and a channel between 1 and 30")
    if not args.scan and not args.address:
        parser.error("provide a Bluetooth address, or use --scan")
    if args.transport == "classic" and args.address and not re.fullmatch(r"(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}", args.address):
        parser.error("Classic requires a Bluetooth address in AA:BB:CC:DD:EE:FF format")
    if args.transport == "classic" and args.characteristic != VP_CHARACTERISTIC_UUID:
        parser.error("--characteristic is BLE-only; use --channel for Classic")
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