import sys
import subprocess
import os
import os.path
import hashlib
import re
import errno
import tempfile

import requests

from xml.etree import ElementTree

_this_dir = os.path.dirname(os.path.abspath(__file__))


def system(args, dirname=None):
    """
    Executes a system command (throws an exception on error)
    params
        args : [command, arg1, arg2, ...]
        dirname : if set, execute the command within this directory
    """
    # print args
    # n.b. stderr=subprocess.STDOUT fails mysteriously
    subprocess.check_call(args, stdout=sys.stdout, stderr=subprocess.STDOUT, shell=False, cwd=dirname)


# http://bugs.python.org/issue8277
class CommentedTreeBuilder(ElementTree.TreeBuilder):
    def __init__(self, *args):
        ElementTree.TreeBuilder.__init__(self, *args)
        self._parser.CommentHandler = self.handle_comment

    def handle_comment(self, data):
        self._target.start(ElementTree.Comment, {})
        self._target.data(data)
        self._target.end(ElementTree.Comment)


def _adjacent_file(file):
    import os.path
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), file)


#http://effbot.org/zone/element-lib.htm#prettyprint
def _indent(elem, level=0):
    i = "\n" + level*"    "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "    "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            _indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i


def gen_dir_from_vc(src, output_filename=None, id=None, diskId=None):
    while src[-1] in ('/', '\\'):
        src = src[:-1]
    name = os.path.basename(src)
    id = id or name.replace('-', '_').replace(' ', '_')
    output_filename = output_filename or _adjacent_file(id + ".wxi")

    ElementTree.register_namespace("", "http://schemas.microsoft.com/wix/2006/wi")
    wix = ElementTree.Element("{http://schemas.microsoft.com/wix/2006/wi}Wix")
    SubElement = ElementTree.SubElement
    fragment = SubElement(wix, "Fragment")
    root_dir = SubElement(fragment, "DirectoryRef")
    root_dir.set("Id", id)
    component_group = SubElement(fragment, "ComponentGroup")
    component_group.set("Id", id)
    dirs = {}

    def get_dir(dirname):
        if dirname == src:
            return root_dir
        dir_ = dirs.get(dirname)
        if dir_ is None:
            parent = get_dir(os.path.dirname(dirname))
            dir_ = SubElement(parent, 'Directory')
            dir_.set('Name', os.path.basename(dirname))
            # "Identifiers may contain ASCII characters A-Z, a-z, digits, underscores (_), or periods (.)"
            dir_.set('Id', 'dir_' + re.sub('[^A-Za-z0-9_]', '_', os.path.relpath(dirname, '..').replace('\\', '_').replace('.', '_').replace('-', '_')))
            # "Standard identifiers are 72 characters long or less."
            if len(dir_.attrib['Id']) > 72:
                dir_.set('Id', 'dir_' + hashlib.md5(dirname.encode('utf8')).hexdigest())
            dirs[dirname] = dir_
        return dir_

    import subprocess
    # git ls-files should show files to-be-added too
    svn_status = subprocess.Popen('git ls-files'.split() + [src], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = svn_status.communicate()
    out = out.decode('utf8')
    err = err.decode('utf8')
    exit_code = svn_status.poll()
    if exit_code != 0:
        raise Exception('svn status failed: ' + err)
    for filename in (line.replace("/", "\\") for line in out.splitlines()):
        # print filename
        if filename == src or os.path.isdir(filename):
            continue
        dir_ = get_dir(os.path.dirname(filename))

        component = SubElement(component_group, 'Component')
        component.set('Directory', dir_.attrib['Id'])
        component.set('Id', 'cmp_' + hashlib.md5(filename.encode('utf8')).hexdigest())
        file_ = SubElement(component, 'File')
        file_.set('Source', filename)
        file_.set('Id', 'fil_' + hashlib.md5(filename.encode('utf8')).hexdigest())
        if diskId:
            component.attrib['DiskId'] = diskId

    _indent(wix)
    ElementTree.ElementTree(wix).write(output_filename, xml_declaration=True, encoding='utf-8')


def download_file(url, filename):
    if os.path.isfile(filename):
        return
    print('Downloading {} => {}'.format(url, filename))
    if os.path.dirname(filename):
        try:
            os.makedirs(os.path.dirname(filename))
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
    r = requests.get(url, stream=True)
    r.raise_for_status()
    fd, tmp_path = tempfile.mkstemp()
    # wix bootstrapper uses SHA1
    hash = hashlib.sha1()
    with os.fdopen(fd, 'wb') as f:
        for chunk in r.iter_content(chunk_size=1024):
            if chunk:  # filter out keep-alive new chunks
                hash.update(chunk)
                f.write(chunk)
        # n.b. don't use f.tell(), since it will be wrong for Content-Encoding: gzip
        downloaded_octets = r.raw._fp_bytes_read
    if int(r.headers.get('content-length', downloaded_octets)) != downloaded_octets:
        os.unlink(tmp_path)
        raise ValueError('Download of {} was truncated: {}/{} bytes'.format(url, downloaded_octets, r.headers['content-length']))
    else:
        os.rename(tmp_path, filename)
        print('  => {} {}'.format(filename, hash.hexdigest()))


def main(src, output_filename=None, id=None, diskId=None):
    while src[-1] in ('/', '\\'):
        src = src[:-1]
    name = os.path.basename(src)
    id = id or name.replace('-', '_').replace(' ', '_')
    output_filename = output_filename or _adjacent_file(id + ".wxi")

    import subprocess

    def check_call(args):
        print(" ".join(args))
        subprocess.check_call(args)
    # subprocess.check_call('set path'.split(), shell=True)
    # subprocess.check_call('where heat'.split(), shell=True)

    check_call(['heat', 'dir', _adjacent_file(src), '-template', 'fragment', '-sreg', '-scom',
      '-o', output_filename, '-ag', '-cg', id, '-srd', '-var', 'var.' + id, '-dr', id, '-nologo'])

    ElementTree.register_namespace("", "http://schemas.microsoft.com/wix/2006/wi")
    parser = ElementTree.XMLParser(encoding='UTF-8', target=ElementTree.TreeBuilder(insert_comments=True))
    xml_contents = open(output_filename, 'rt', encoding='utf-8-sig').read()
    parser.feed(xml_contents)
    tree = parser.close()

    tree.insert(0, ElementTree.Comment('generated with gen_dir_wxi.py %s\n' % src))
    tree.insert(0, ElementTree.ProcessingInstruction('define', '%s=%s' % (id, os.path.normpath(src))))
    # import pdb; pdb.set_trace()
    parent_map = dict((c, p) for p in tree.iter() for c in p)
    for file in tree.findall(".//{http://schemas.microsoft.com/wix/2006/wi}Component/{http://schemas.microsoft.com/wix/2006/wi}File"):
        file_Source = file.get('Source', '')
        if file_Source.find('.svn') != -1 or os.path.basename(file_Source) in ('Thumbs.db', 'desktop.ini', '.DS_Store') or file_Source.endswith('.pyc'):
            comp = parent_map[file]
            parent_map[comp].remove(comp)
    for dir in tree.findall(".//{http://schemas.microsoft.com/wix/2006/wi}Directory"):
        if dir.get('Name', '') == '.svn':
            for dirref in tree.findall(".//{http://schemas.microsoft.com/wix/2006/wi}DirectoryRef"):
                if dirref.get('Id', '') == dir.get('Id', ''):
                    frag = parent_map[dirref]
                    parent_map[frag].remove(frag)
            parent_map[dir].remove(dir)
    if diskId:
        for component in tree.findall(".//{http://schemas.microsoft.com/wix/2006/wi}Component"):
            component.attrib['DiskId'] = diskId

    ElementTree.ElementTree(tree).write(output_filename, xml_declaration=True, encoding='utf-8')


if __name__ == '__main__':
    main(sys.argv[1])
    # download_bundle_deps("META_bundle_x64.wxs")

# heat dir ../runtime/MATLAB/Scenario-matlab-library -template fragment -o Scenario-matlab-library.wxi -gg -cg Scenario_matlab_library -srd -var var.Scenario_matlab_library -dr Scenario_matlab_library
