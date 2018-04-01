#!/bin/env python3
import http.server
import random
import string
import click


@click.command()
@click.argument("port", required=False)
@click.option("-s", "--server", default="0.0.0.0")
def main(port, server):
    if not port:
        port = 8888
    http_server = http.server.HTTPServer((server, port), PostHandler)
    print('Starting server on {0}:{1}, use <Ctrl-C> to stop'.format(
        server, port))
    http_server.serve_forever()


def get_filename():
    chars = "{}{}".format(string.ascii_letters, string.digits)
    fn = ''.join([random.choice(chars) for i in range(12)])

    return fn


class PostHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = self.headers['content-length']
        data = self.rfile.read(int(length))

        fn = get_filename()
        with open(fn, 'w') as fh:
            fh.write(data.decode())

        self.send_response(200)

    def do_GET(self):
        page = """<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>
<h1>Upload a File</h1>
<form action="/" method="post" enctype="multipart/form-data">
<input type="file" name="file" placeholder="Enter a filename."></input><br />
<input type="submit" value="Import">
</form>
</html>
"""

        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(page.encode("UTF-8"))


if __name__ == '__main__':
    main()
