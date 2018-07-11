#!/usr/bin/env python3
import http.server
import string
import click
import pathlib
import urllib.parse
import os


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

class PostHandler(http.server.BaseHTTPRequestHandler):
    cwd = pathlib.Path(".")

    def do_GET(self):
        body_file_cat = string.Template("$content")
        body_dir_list = string.Template("""
<h1>Directory listing for $cwd</h1>
<ul>
$items
</ul>
""")
        page = string.Template("""<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for $cwd</title>
</head>
<body>
$body
</body>
</html>
""")
        path = urllib.parse.urlparse(self.path)
        fs_path = pathlib.Path("{}{}".format(self.cwd, path.path))
        prefix_ref = "{}/".format(path.path)
        if fs_path.is_file():
            body = body_file_cat
            content = ""
            with fs_path.open() as f:
                content = "".join(f.readlines())
                content = "<pre>{}</pre>".format(content)
            body = body.substitute(content=content)

        else:
            body = body_dir_list
            items = list()
            item_template = string.Template('<li><a href="$item_path">$item_name</a></li>')
            for p in fs_path.iterdir():
                item_path = urllib.parse.urljoin(prefix_ref, p.name)
                item_name = p.name
                if os.path.isdir(p):
                    item_name = "{}/".format(item_name)
                items.append(item_template.substitute(item_path=item_path, item_name=item_name))
            body = body.substitute(cwd=fs_path, items="\n".join(items))

        page = page.substitute(cwd=fs_path, body=body)

        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(page.encode("UTF-8"))


if __name__ == '__main__':
    main()
