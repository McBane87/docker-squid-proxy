#!/usr/bin/python <span style="color: #993300;">-u</span>
import re
import sys

# http://sim34232.agni.lindenlab.com/cap/foo/?texture_id=klkjalkjsd
# http://asset-cdn.glb.agni.lindenlab.com/?texture_id=klklkjlkjs
# group 1 is the host - simNNNN or a CDN server
# group 2 is the port on the server
# group 3 cap
# group 4 is either 'texture' or 'mesh'
# group 5 the actual id
texturl_patt = re.compile('(.*)\.agni\.lindenlab\.com(.*)/(.*/?)\?(texture|mesh)_id=(.*)')

def rewrite(texturl):
    m = texturl_patt.search(texturl)
    if m is not None:
        r = 'http://{}.lindenlab.com/{}'.format(m.group(4),m.group(5))
        return r
    else:
        return None

def process(line):
    if line == 'quit':
        sys.exit(0)
        
    stuff = line.split()
    if stuff[0].isdigit():
        r = rewrite(stuff[1])
        if r is not None:
            print('{} OK store-id={}'.format(stuff[0], r))
        else:
            print('{} ERR'.format(stuff[0]))
    else:
        r=rewrite(stuff[0])
        if r is not None:
            print('OK store-id={}'.format(r))
        else:
            print('ERR')

while True:
    line = sys.stdin.readline().strip()
    if not line:
        break
    process(line)
