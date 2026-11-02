#!/usr/bin/env python3
"""Collect partial TC4/TC5/TC6 evidence for Verification_TRI-22391.

Linux prerequisites: BlueZ sdptool and an already paired, authorized test DUT.
Uses the neighboring ble-vp-json.py; no additional Python packages are needed.
No bonds/SDP records are deleted and no power cycle is performed by this tool.
Captures may contain patient data: use a test-only device and protect evidence.

Discovery only (LMX9830 expects channels 1,2,3 unless overridden):
  python3 verify-classic-sdp.py AA:BB:CC:DD:EE:FF --hardware lmx9830 \
    --dut-serial TEST001 --build-id BUILD123 --operator Milad --output evidence-01

Add SDK traffic only on channels known to support the CWBTAPI SDK role:
  ... --sdk-channels 1 --reconnects 3 --samples 2

BT121 regression: use --hardware bt121 --expected-channels with its approved
channel inventory. LMX-specific URL encoding assertions are not applied.
Offline decoding: replace ADDRESS with --sdp-xml saved-sdp.xml. This validates
captured XML only and cannot establish current hardware discovery or traffic.

Exit 0: all selected automated checks passed, NOT all six verification cases.
Exit 1: a selected check failed; 2: invalid arguments; 130: interrupted.
The JSON report lists coverage gaps even when the selected checks pass.
"""

import argparse
import asyncio
import contextlib
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
from pathlib import Path
import platform
import re
import socket
import sys
import uuid
import xml.etree.ElementTree as ET


CLIENT_PATH = Path(__file__).with_name('ble-vp-json.py')
SPEC = importlib.util.spec_from_file_location('verification_vp_client', CLIENT_PATH)
capture = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(capture)
EDCOMM_UUID = '0d10736d-ae02-0002-0100-000000000900'
SOURCE_COMMIT = 'efbb98795d023d79cfb76d70362cd0dc7527915c'


def now():
    return datetime.now(timezone.utc).isoformat()


def normalize_uuid(value):
    if value.lower().startswith('0x'):
        number = int(value, 16)
        if not 0 <= number <= 0xFFFFFFFF:
            raise ValueError('Short SDP UUID exceeds 32 bits')
        value = f'{number:08x}-0000-1000-8000-00805f9b34fb'
    return str(uuid.UUID(value))


def attributes(record):
    result = {}
    for attribute in record.findall('attribute'):
        identifier = int(attribute.attrib['id'], 0)
        if identifier in result:
            raise ValueError(f'Duplicate SDP attribute 0x{identifier:04x}')
        result[identifier] = attribute
    return result


def inspect_sdp(text, expected_channels, hardware, edcomm_uuid=EDCOMM_UUID):
    text = re.sub(r'<\?xml[^?]*\?>', '', text)
    root = ET.fromstring('<records>' + text + '</records>')
    target_uuid = normalize_uuid(edcomm_uuid)
    serial_uuid = normalize_uuid('0x1101')
    rfcomm_uuid = normalize_uuid('0x0003')
    records = []
    errors = []
    for record in root.findall('record'):
        fields = attributes(record)
        service_class = fields.get(0x0001)
        if service_class is None:
            continue
        all_uuids = [normalize_uuid(element.attrib['value']) for element in service_class.iter('uuid')]
        if target_uuid not in all_uuids:
            continue
        record_errors = []
        sequence = service_class.find('sequence')
        direct = list(sequence) if sequence is not None else []
        if len(service_class) != 1 or any(element.tag != 'uuid' for element in direct):
            record_errors.append('ServiceClassIDList must contain UUIDs directly, not nested sequences')
        direct_uuids = [normalize_uuid(element.attrib['value']) for element in direct if element.tag == 'uuid']
        if sorted(direct_uuids) != sorted([target_uuid, serial_uuid]):
            record_errors.append('Expected exactly the EDComm and Serial Port service UUIDs')
        channels = []
        protocols = fields.get(0x0004)
        if protocols is not None:
            for descriptor in protocols.findall('./sequence/sequence'):
                protocol = descriptor.find('uuid')
                if protocol is not None and normalize_uuid(protocol.attrib['value']) == rfcomm_uuid:
                    children = list(descriptor)
                    if len(children) != 2 or children[0].tag != 'uuid' or children[1].tag != 'uint8':
                        record_errors.append('RFCOMM descriptor must contain a UUID and a uint8 channel')
                    else:
                        channels.append(int(children[1].attrib['value'], 0))
        if len(channels) != 1 or any(not 1 <= channel <= 30 for channel in channels):
            record_errors.append('Expected exactly one RFCOMM channel in range 1..30')
        urls = {}
        if hardware == 'lmx9830':
            for identifier in (0x000A, 0x000C):
                attribute = fields.get(identifier)
                elements = list(attribute) if attribute is not None else []
                if len(elements) != 1 or elements[0].tag != 'url' or not elements[0].get('value'):
                    record_errors.append(f'Attribute 0x{identifier:04x} must be a nonempty URL element, not text')
                else:
                    urls[f'0x{identifier:04x}'] = elements[0].get('value')
        name_attribute = fields.get(0x0100)
        name = name_attribute.find('text') if name_attribute is not None else None
        records.append({'name': name.get('value') if name is not None else None,
                        'channels': channels, 'service_uuids': all_uuids,
                        'urls': urls, 'errors': record_errors})
        errors.extend(f'Record {len(records)}: {error}' for error in record_errors)
    observed = [channel for record in records for channel in record['channels']]
    if sorted(observed) != sorted(expected_channels) or len(records) != len(expected_channels):
        errors.append(f'Expected exactly one EDComm record per channel {expected_channels}; observed {observed}')
    return {'records': records, 'expected_channels': expected_channels, 'errors': errors}


async def browse(address, timeout):
    process = await asyncio.create_subprocess_exec(
        'sdptool', 'browse', '--xml', address,
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
    )
    try:
        stdout, stderr = await asyncio.wait_for(process.communicate(), timeout)
    except BaseException:
        if process.returncode is None:
            with contextlib.suppress(ProcessLookupError):
                process.kill()
        await process.communicate()
        raise
    return process.returncode, stdout, stderr


class EvidenceEdcomm(capture.ClassicEdcomm):
    def __init__(self, reader, writer, args, evidence):
        super().__init__(reader, writer, frame_gap=args.frame_gap)
        self.evidence = evidence

    def log_packet(self, direction, message_type, sequence, command, status, payload):
        self.evidence.write(json.dumps({
            'utc': now(), 'direction': direction, 'message_type': message_type,
            'sequence': sequence, 'command': command, 'status': status,
            'payload_hex': payload.hex(),
        }) + '\n')
        self.evidence.flush()

    async def send(self, message_type, sequence, command, payload=b'', status=0):
        await super().send(message_type, sequence, command, payload, status)
        self.log_packet('tx', message_type, sequence, command, status, payload)

    async def receive(self):
        packet = await super().receive()
        self.log_packet('rx', *packet)
        return packet


async def session(args, channel, stem):
    classic_socket = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)
    writer = None
    client = None
    try:
        classic_socket.setblocking(False)
        await asyncio.wait_for(asyncio.get_running_loop().sock_connect(classic_socket, (args.address, channel)), args.timeout)
        reader, writer = await asyncio.open_connection(sock=classic_socket)
        with stem.with_suffix('.edcomm.jsonl').open('x') as packets, stem.with_suffix('.vp.jsonl').open('x') as snapshots:
            client = EvidenceEdcomm(reader, writer, args, packets)
            await asyncio.wait_for(client.handshake(), args.timeout)
            for sample_index in range(args.samples):
                information = capture.decode_vp_information(
                    await asyncio.wait_for(client.request(capture.VP_INFORMATION_COMMAND), args.timeout)
                )
                snapshot = capture.decode_vp_vector(
                    await asyncio.wait_for(client.request(capture.VP_VECTOR_COMMAND), args.timeout), information
                )
                if not information or not snapshot['vp']:
                    raise RuntimeError('Empty VP information/vector does not establish application traffic')
                snapshots.write(json.dumps({'utc': now(), 'snapshot': snapshot}, allow_nan=False) + '\n')
                snapshots.flush()
                if sample_index + 1 < args.samples:
                    await asyncio.sleep(args.interval)
    except asyncio.TimeoutError as error:
        pending = client.waiting_for if client is not None else 'RFCOMM connect'
        raise RuntimeError(f'Timeout waiting for {pending}; inspect DUT logs and channel/role compatibility') from error
    finally:
        if writer is not None:
            writer.close()
            with contextlib.suppress(OSError, asyncio.TimeoutError):
                await asyncio.wait_for(writer.wait_closed(), args.timeout)
        classic_socket.close()


def save_report(args, report):
    temporary = args.output / 'report.json.tmp'
    temporary.write_text(json.dumps(report, indent=2, allow_nan=False) + '\n')
    temporary.replace(args.output / 'report.json')


def record_check(args, report, identifier, status, **details):
    report['checks'].append({'id': identifier, 'status': status, 'utc': now(), **details})
    save_report(args, report)
    print(f'{identifier}: {status}', file=sys.stderr, flush=True)


async def discover_and_check(args, report, label):
    xml_path = args.output / f'{label}.sdp.xml'
    if args.sdp_xml is not None:
        raw_xml = args.sdp_xml.read_bytes()
        stderr = b''
        returncode = 0
    else:
        returncode, raw_xml, stderr = await browse(args.address, args.timeout)
    xml_path.write_bytes(raw_xml)
    (args.output / f'{label}.sdptool.stderr.txt').write_bytes(stderr)
    if returncode:
        raise RuntimeError(f'sdptool exited {returncode}; see {label}.sdptool.stderr.txt')
    result = inspect_sdp(raw_xml.decode('utf-8'), args.expected_channels, args.hardware, args.edcomm_uuid)
    record_check(args, report, label, 'FAIL' if result['errors'] else 'PASS',
                 source='offline XML' if args.sdp_xml else 'live sdptool browse',
                 artifact=xml_path.name, **result)
    return not result['errors']


async def run_checks(args, report):
    if not await discover_and_check(args, report, 'TC4-discovery-initial'):
        record_check(args, report, 'TC5-traffic', 'NOT_EXECUTED', reason='Discovery/schema validation failed; no unverified channel is used')
        return
    if not args.sdk_channels:
        record_check(args, report, 'TC5-traffic', 'NOT_EXECUTED', reason='No SDK-compatible channels selected')
        return
    for cycle in range(args.reconnects + 1):
        if cycle:
            await asyncio.sleep(args.reconnect_delay)
            if not await discover_and_check(args, report, f'TC4-discovery-reconnect-{cycle}'):
                record_check(args, report, f'TC5-cycle-{cycle}', 'NOT_EXECUTED', reason='Rediscovery failed')
                continue
        for channel in args.sdk_channels:
            identifier = f'TC5-channel-{channel}-cycle-{cycle}'
            stem = args.output / identifier
            try:
                await session(args, channel, stem)
            except (OSError, RuntimeError, asyncio.IncompleteReadError) as error:
                record_check(args, report, identifier, 'FAIL', error=str(error), channel=channel,
                             evidence_prefix=stem.name)
            else:
                record_check(args, report, identifier, 'PASS', channel=channel,
                             snapshots=args.samples, evidence_prefix=stem.name,
                             scope='CWBTAPI SDK handshake and VP request/response only')


def channels(text):
    try:
        values = [int(value) for value in text.split(',')]
    except ValueError as error:
        raise argparse.ArgumentTypeError('use comma-separated channels, e.g. 1,2,3') from error
    if not values or len(set(values)) != len(values) or any(not 1 <= value <= 30 for value in values):
        raise argparse.ArgumentTypeError('channels must be unique integers in 1..30')
    return values


def positive_integer(text):
    value = int(text)
    if value < 1:
        raise argparse.ArgumentTypeError('must be at least one')
    return value


def parse_arguments(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('address', nargs='?')
    parser.add_argument('--sdp-xml', type=Path, help='validate an existing capture without contacting hardware')
    parser.add_argument('--hardware', required=True, choices=('lmx9830', 'bt121'))
    parser.add_argument('--expected-channels', type=channels)
    parser.add_argument('--sdk-channels', type=channels, default=[], help='discovered channels approved for the CWBTAPI SDK role')
    parser.add_argument('--edcomm-uuid', default=EDCOMM_UUID)
    parser.add_argument('--dut-serial', required=True)
    parser.add_argument('--hardware-version', default='NOT RECORDED')
    parser.add_argument('--module-firmware', default='NOT RECORDED')
    parser.add_argument('--build-id', required=True, help='operator-recorded build identity; not automatically verified')
    parser.add_argument('--operator', required=True)
    parser.add_argument('--source-commit', default=SOURCE_COMMIT, help='declared test source; not proof of flashed build identity')
    parser.add_argument('--label', default='manual-run', help='e.g. cold-start-1; does not cause a power cycle')
    parser.add_argument('--output', type=Path, required=True, help='new evidence directory; existing directories are never overwritten')
    parser.add_argument('--timeout', type=capture.positive_seconds, default=30.0)
    parser.add_argument('--reconnects', type=capture.nonnegative_integer, default=3, help='additional connections after the initial one')
    parser.add_argument('--samples', type=positive_integer, default=2)
    parser.add_argument('--interval', type=capture.positive_seconds, default=1.0)
    parser.add_argument('--frame-gap', type=capture.positive_seconds, default=0.1)
    parser.add_argument('--reconnect-delay', type=capture.positive_seconds, default=2.0)
    args = parser.parse_args(argv)
    if bool(args.address) == bool(args.sdp_xml):
        parser.error('provide either ADDRESS or --sdp-xml, not both')
    if args.address and not re.fullmatch(r'(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}', args.address):
        parser.error('ADDRESS must be a Bluetooth MAC address')
    if args.sdp_xml and args.sdk_channels:
        parser.error('--sdk-channels requires live hardware, not --sdp-xml')
    if args.expected_channels is None:
        if args.hardware == 'bt121':
            parser.error('BT121 requires --expected-channels from its approved baseline')
        args.expected_channels = [1, 2, 3]
    if not set(args.sdk_channels).issubset(args.expected_channels):
        parser.error('--sdk-channels must be a subset of --expected-channels')
    try:
        args.edcomm_uuid = normalize_uuid(args.edcomm_uuid)
    except ValueError:
        parser.error('invalid --edcomm-uuid')
    return args


def main(argv=None):
    args = parse_arguments(argv)
    try:
        args.output.mkdir(mode=0o700, parents=True, exist_ok=False)
    except OSError as error:
        print(f'Cannot create new evidence directory: {error}', file=sys.stderr)
        return 1
    report = {
        'document': 'Verification_TRI-22391', 'started_utc': now(), 'status': 'RUNNING',
        'verification_conclusion': 'NOT ESTABLISHED - partial automated evidence only',
        'configuration': {key: str(value) if isinstance(value, Path) else value for key, value in vars(args).items()},
        'runtime': {'python': sys.version, 'platform': platform.platform()},
        'tool_sha256': {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in (Path(__file__), CLIENT_PATH)},
        'coverage': {
            'TC1': 'NOT EXECUTED: independent source/specification review required',
            'TC2': 'NOT EXECUTED: XML does not prove initialized module bytes, 246-byte length or element boundary correctness',
            'TC3': 'NOT EXECUTED: production HAL identifier success/error harness required',
            'TC4': 'PARTIAL: live discovery/schema only; offline mode checks saved XML only. Store/enable confirmations, stale record inventory, DUT build identity and three power cycles require external evidence',
            'TC5': 'PARTIAL if SDK channels selected: handshake, nonempty decoded VP responses and reconnects. Other peer roles, clinical correctness, authentication/encryption and concurrent links remain unverified',
            'TC6': 'PARTIAL only on declared BT121 hardware: discovery and selected SDK traffic. Approved baseline comparison and supported variants still require review',
        },
        'unexercised_channels': sorted(set(args.expected_channels) - set(args.sdk_channels)),
        'checks': [],
    }
    save_report(args, report)
    exit_code = 0
    try:
        asyncio.run(run_checks(args, report))
    except KeyboardInterrupt:
        report['status'] = 'INTERRUPTED'
        exit_code = 130
    except Exception as error:
        record_check(args, report, 'runner', 'FAIL', error=f'{type(error).__name__}: {error}')
        exit_code = 1
    finally:
        if report['status'] != 'INTERRUPTED':
            failed = any(check['status'] == 'FAIL' for check in report['checks'])
            report['status'] = 'SELECTED_CHECKS_FAILED' if failed else 'SELECTED_CHECKS_PASSED'
            exit_code = 1 if failed else exit_code
        report['finished_utc'] = now()
        save_report(args, report)
    print(f"{report['status']}: {args.output / 'report.json'}", file=sys.stderr)
    print('Partial evidence only; not a pass of all six verification cases.', file=sys.stderr)
    return exit_code


if __name__ == '__main__':
    raise SystemExit(main())