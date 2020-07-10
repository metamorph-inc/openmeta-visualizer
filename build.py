import os
import os.path
import tempfile
import shutil
import zipfile
import subprocess
import requests

url = 'https://nodejs.org/dist/v12.18.2/node-v12.18.2-win-x64.zip'
filename = 'node-v12.18.2-win-x64.zip'
dirname = os.path.splitext(filename)[0]

tab_dir = os.path.join("Dig", "tab-src", "surrogate-modeling")
tab_dst = os.path.join('Dig', 'www', 'SurrogateModeling')

electron_dir = "viz-electron"


def download(url, filename):
    if os.path.isfile(filename):
        return
    print('Downloading ' + url)
    r = requests.get(url, stream=True)
    r.raise_for_status()
    fd, tmp_path = tempfile.mkstemp()
    with os.fdopen(fd, 'wb') as f:
        for chunk in r.iter_content(chunk_size=1024):
            if chunk:  # filter out keep-alive new chunks
                f.write(chunk)
        # n.b. don't use f.tell(), since it will be wrong for Content-Encoding: gzip
        downloaded_octets = r.raw._fp_bytes_read
    if int(r.headers.get('content-length', downloaded_octets)) != downloaded_octets:
        os.unlink(tmp_path)
        raise ValueError('Download of {} was truncated: {}/{} bytes'.format(url, downloaded_octets, r.headers['content-length']))
    else:
        os.rename(tmp_path, filename)
        print('  => {}'.format(filename))


def decompress(filename, dirname):
    # n.b. `dirname` may exist with partial contents due to failed `git clean` ('Filename too long' errors)
    # if os.path.isdir(dirname):
    #    return
    if os.path.isfile(os.path.join(dirname, 'npm')):
       return
    print('Extracting ' + filename)
    for path in (unicode(dirname), u'tmp'):
        if os.path.isdir(path):
            # n.b. \\?\ is for MAXPATH workaround
            # n.b. unicode strings are required for os.listdir
            shutil.rmtree(u'\\\\?\\' + os.path.abspath(path))
    os.mkdir('tmp')
    with zipfile.ZipFile(filename, 'r', allowZip64=True) as zf:
        zf.extractall('\\\\?\\' + os.path.abspath('tmp'))
    os.rename(os.path.join('tmp', dirname), dirname)


def build_tab(node_dirname):
    npm = os.path.join(node_dirname, 'npm.cmd')
    node = os.path.join(node_dirname, 'node.exe')
    print('`npm install`')
    subprocess.check_call([npm, 'install'], cwd=tab_dir)
    print('`npm run build`')
    env = dict(os.environ)
    env['PATH'] = dirname + ';' + env['PATH']
    subprocess.check_call([npm, 'run', 'build'], env=env, cwd=tab_dir)
    if os.path.isdir(tab_dst):
        shutil.rmtree(tab_dst)
    shutil.copytree(os.path.join(tab_dir, 'build'), tab_dst)

def build_electron(node_dirname):
    npm = os.path.join(node_dirname, 'npm.cmd')
    yarn = os.path.join(node_dirname, 'yarn.cmd')
    node = os.path.join(node_dirname, 'node.exe')
    print('`npm install -g yarn`')
    subprocess.check_call([npm, 'install', "-g", "yarn"], cwd=electron_dir)
    print('`yarn install`')
    subprocess.check_call([yarn, 'install'], cwd=electron_dir)
    print('`yarn run dist`')
    env = dict(os.environ)
    env['PATH'] = dirname + ';' + env['PATH']
    subprocess.check_call([yarn, 'run', 'dist'], env=env, cwd=electron_dir)

if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    download(url, filename)
    decompress(filename, dirname)
    build_tab(os.path.abspath(dirname))
    build_electron(os.path.abspath(dirname))
