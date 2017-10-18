#!python -u

import sys
import os
import os.path
import win32com.client
import gen_dir_wxi
from gen_dir_wxi import system
import glob
import subprocess
import re

import xml.etree.ElementTree as ET

this_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(this_dir)

os.environ['PATH'] = os.environ['PATH'].replace('"', '')


def generate_license_rtf():
    with open('../license.rtf', 'wb') as rtf:
        txt = open('../license.txt').read()
        txt = txt.replace('\r', '')
        txt = re.sub('([^\\n])\\n(?!\\n)', '\\1 ', txt)
        txt = re.sub(r'([\\{}])', r'\\\1', txt)
        rtf.write('{\\rtf1\n')
        rtf.write(txt.replace('\n\n', '\\par\n'))
        rtf.write('\n}')


def build_msi():
    generate_license_rtf()

    def get_wixobj(file):
        return os.path.splitext(file)[0] + ".wixobj"

    def adjacent_file(file):
        return os.path.join(os.path.dirname(__file__), file)

    # gen_dir_from_vc: "explicit is better than implicit"
    #  consider: generated files are left on disk after an svn switch, and get included in an installer that shouldn't have them
    gen_dir_wxi.gen_dir_from_vc(r"..\R",)
    gen_dir_wxi.gen_dir_from_vc(r"..\Dig",)
    gen_dir_wxi.main(r"..\Dig\www\SurrogateModeling")

    def get_vcsversion():
        p = subprocess.Popen("git rev-list HEAD --count".split(), stdout=subprocess.PIPE)
        out, err = p.communicate()
        return out.strip() or '2'
    vcsversion = get_vcsversion()

    print "VCS version: " + str(vcsversion)
    sourcedir = os.path.relpath(this_dir) + '/'

    def get_githash():
        p = subprocess.Popen("git rev-parse --short HEAD".split(), stdout=subprocess.PIPE)
        out, err = p.communicate()
        return out.strip() or 'unknown'

    vcshash = get_githash()

    import glob
    if len(sys.argv[1:]) > 0:
        source_wxs = sys.argv[1]
    else:
        source_wxs = 'openmeta-visualizer_x64.wxs'
    sources_all = glob.glob(sourcedir + '*.wxi') + glob.glob(sourcedir + source_wxs)
    sources = []
    include_wxis = []

    # For each each ComponentGroupRef in "source_wxs" and "analysis_tools.wxi",
    # add its corresponding file to "include_wxis"
    for wxs in glob.glob(sourcedir + source_wxs) + glob.glob(sourcedir + 'analysis_tools.wxi'):
        print 'Processing WXS: ' + wxs
        tree = ET.parse(wxs)
        root = tree.getroot()
        # print root
        all_nodes = root.findall('.//')
        for node in all_nodes:
            if node.tag == '{http://schemas.microsoft.com/wix/2006/wi}ComponentGroupRef':
                include_wxis.append(node.attrib['Id'] + '.wxi')
                include_wxis.append(node.attrib['Id'] + '_x64.wxi')
                if 'Proe' in node.attrib['Id'] + '_x64.wxi':
                    print node.attrib['Id'] + '_x64.wxi'
            if node.tag == '{http://schemas.microsoft.com/wix/2006/wi}ComponentRef':
                include_wxis.append(node.attrib['Id'].rsplit(".", 1)[0] + '.wxi')
                include_wxis.append(node.attrib['Id'].rsplit(".", 1)[0] + '_x64.wxi')

    # For each file in include_wxis, check for ComponentGroupRef and ComponentRef.
    # Add any that you find
    index = 0
    while index < len(include_wxis):
        wxi = include_wxis[index]
        index += 1

        if not os.path.exists(wxi):
            continue

        tree = ET.parse(wxi)
        root = tree.getroot()

        all_nodes = root.findall('.//')
        for node in all_nodes:
            if node.tag == '{http://schemas.microsoft.com/wix/2006/wi}ComponentGroupRef':
                include_wxis.append(node.attrib['Id'] + '.wxi')
                include_wxis.append(node.attrib['Id'] + '_x64.wxi')
            if node.tag == '{http://schemas.microsoft.com/wix/2006/wi}ComponentRef':
                include_wxis.append(node.attrib['Id'].rsplit(".", 1)[0] + '.wxi')
                include_wxis.append(node.attrib['Id'].rsplit(".", 1)[0] + '_x64.wxi')

    sources = [source for source in sources_all if (os.path.basename(source) in include_wxis)]
    sources.append(source_wxs)

    if len(sources) == 0:
        raise Exception("0 sources found in " + sourcedir)

    defines = []

    version = '14.13.' + str(int(vcsversion))
    print 'Installer version: ' + version
    defines.append(('VERSIONSTR', version))
    defines.append(('VCSVERSION', vcsversion))
    defines.append(('VCSHASH', vcshash))

    from multiprocessing.pool import ThreadPool
    pool = ThreadPool()
    pool_exceptions = []

    def candle(source):
        try:
            arch = ['-arch', ('x86' if source.find('x64') == -1 else 'x64')]
            system(['candle', '-ext', 'WiXUtilExtension'] + ['-d' + d[0] + '=' + d[1] for d in defines] + arch + ['-out', get_wixobj(source), source] + ['-nologo'])
        except Exception as e:
            pool_exceptions.append(e)
            raise
    candle_results = pool.map_async(candle, sources, chunksize=1)
    pool.close()
    pool.join()
    if pool_exceptions:
        raise pool_exceptions[0]
    assert candle_results.successful()

    # ignore warning 1055, ICE82 from VC10 merge modules
    # ICE69: Mismatched component reference. Entry 'reg491FAFEB7F990D99C4A4D719B2A95253' of the Registry table belongs to component 'CyPhySoT.dll'. However, the formatted string in column 'Value' references file 'CyPhySoT.ico' which belongs to component 'CyPhySoT.ico'
    # ICE60: The file fil_5b64d789d9ad5473bc580ea7258a0fac is not a Font, and its version is not a companion file reference. It should have a language specified in the Language column.
    import datetime
    starttime = datetime.datetime.now()
    system(['light', '-sw1055', '-sice:ICE82', '-sice:ICE57', '-sice:ICE60', '-sice:ICE69', '-ext', 'WixNetFxExtension', '-ext', 'WixUIExtension', '-ext', 'WixUtilExtension',
        # '-cc', os.path.join(this_dir, 'cab_cache'), '-reusecab', # we were getting errors during installation relating to corrupted cab files => disable cab cache
        # udm.pyd depends on UdmDll_VC10
        '-o', os.path.splitext(source_wxs)[0] + ".msi"] + [get_wixobj(file) for file in sources])

    print "elapsed time: %d seconds" % (datetime.datetime.now() - starttime).seconds


class MSBuildErrorWriter(object):
    def write(self, d):
        sys.stderr.write("error: ")
        sys.stderr.write(d)

if __name__ == '__main__':
    os.chdir(this_dir)
    import traceback
    try:
        build_msi()
    except:
        traceback.print_exc(None, MSBuildErrorWriter())
        sys.exit(2)
