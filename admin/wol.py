#!/usr/bin/env python3
import socket
import struct
import click


@click.command()
@click.argument("mac", required=True, nargs=-1)
@click.option("-d", "--destination", default="255.255.255.255")
@click.option("-p", "--port", default=9, help="Specific host to wakeup")
@click.option("-f", "--filename", help="File with mac addresses.")
@click.option("-r", "--raw", is_flag=True, help="Send raw ethernet packet.")
@click.option(
    "-i",
    "--interface",
    default="enp5s0",
    help="Interface to send raw ethernet packet from")
def main(mac, destination, port, filename, raw, interface):
    send_packet = None
    arguments = set()
    if raw:
        send_packet = raw_ether_magic_packet
        arguments = (destination, port, interface)
    else:
        send_packet = udp_magic_packet
        arguments = (destination, port, )
    for m in mac:
        m = m.replace(":", '')
        send_packet(m, *arguments)


def create_magic_packet(mac):
    data = b"FFFFFFFFFFFF" + (mac * 16).encode()
    return pack_payload(data)


def create_raw_magic_packet_frame(mac, interface):
    src_mac = None
    with open("/sys/class/net/{}/address".format(interface)) as f:
        src_mac = f.read().strip()
    src_mac = src_mac.replace(":", "")
    src_mac = pack_payload(src_mac)
    dst_mac = pack_payload("FFFFFFFFFFFF")

    ethtype = pack_payload("0842")
    payload = create_magic_packet(mac)
    return dst_mac + src_mac + ethtype + payload


def pack_payload(data):
    packet = b''
    for i in range(0, len(data), 2):
        packet += struct.pack(b'B', int(data[i: i + 2], 16))
    return packet


def udp_magic_packet(mac, destination, port):
    packet = create_magic_packet(mac)
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    sock.connect((destination, port))
    sock.send(packet)
    sock.close()


def raw_ether_magic_packet(mac, destination, port, interface):
    packet = create_raw_magic_packet_frame(mac, interface)

    sock = socket.socket(socket.AF_PACKET, socket.SOCK_RAW)
    sock.bind((interface, 0))

    sock.send(packet)
    sock.sendto


if __name__ == "__main__":
    main()
