import click
import string

class Struct():
    def __init__(self):
        pass

@click.group("caesar.py")
@click.pass_context
def main(ctx):
    data = Struct()
    plaintext = set(string.printable) - set(string.whitespace)
    plaintext = "".join(sorted(list(plaintext)))
    data.plaintext = plaintext
    ctx.obj = data


@main.command("encrypt")
@click.argument("plaintext", required=True)
@click.argument("stdin", "-", required=False)
@click.option("-s","--shift", default=10)
@click.pass_obj
def main_encrypt(data, plaintext, stdin, shift):
    cipher = list()
    for c in plaintext:
        r = encrypt(data.plaintext, c, shift)
        cipher.append(r)
    print("".join(cipher))

@main.command("decrypt")
@click.argument("cipher", required=True)
@click.argument("stdin", "-", required=False)
@click.option("-s","--shift", default=10)
@click.pass_obj
def main_decrypt(data, cipher, stdin, shift):
    plaintext = list()
    for c in cipher:
        r = decrypt(data.plaintext, c, shift)
        plaintext.append(r)
    print("".join(plaintext))

def encrypt(plaintext, x, n):
    pos = plaintext.find(x)
    r = (pos + n) % len(plaintext)
    return plaintext[r]

def decrypt(plaintext, x, n):
    pos = plaintext.find(x)
    r = (pos - n) % len(plaintext)
    return plaintext[r]

if __name__ == "__main__":
    main()
