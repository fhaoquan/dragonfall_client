# coding=utf-8
# DannyHe
# read project infomation on different platform
import xml.dom.minidom
import sys
import getopt
from basic import *
from batcat import *

platform = ""
isReadVersion = False
isReadMinVersion = False


def usage():
    print("usage:")
    print("readProject -p platform [-v][-m]")
    print("platform:iOS,Android,WP")
    print("v:version")
    print("m:appMinVersion")
    print("readProject -p iOS -v")


def initData():
    if platform == 'Android':
        initAndroidData()
    if platform == 'WP':
        pass
    if platform == 'iOS':
        pass


def getAppVersion():
    if platform == 'Android':
        return getAndroidAppVersion()
    if platform == 'WP':
        return getWPAppVersion()
    if platform == 'iOS':
        pass


def getAppMinVersion():
    if platform == 'Android':
        return getAndroidAppMinVersion()
    if platform == 'WP':
        return getWPAppMinVersion()
    if platform == 'iOS':
        pass

# Android


def initAndroidData():
    if platform != 'Android':
        return
    m_file_path = getProjConfigPath('Android')
    dom = xml.dom.minidom.parse(m_file_path)
    global root
    root = dom.documentElement


def getAndroidAllMetaDataElements():
    if platform != 'Android':
        return
    applications = root.getElementsByTagName("application")
    if applications[0].nodeName == 'application':
        return applications[0].getElementsByTagName("meta-data")


def getAndroidAppVersion():
    if platform != 'Android':
        return
    version = root.getAttribute("android:versionName")
    return version


def getAndroidAppMinVersion():
    if platform != 'Android':
        return
    metaDatas = getAndroidAllMetaDataElements()
    for meta in metaDatas:
        if meta.getAttribute("android:name") == "AppMinVersion":
            return meta.getAttribute("android:value")

# WindowsPhone


def getWPAppVersion():
    if platform != 'WP':
        return
    xmlPath = getProjConfigPath('WP')
    dom = xml.dom.minidom.parse(xmlPath)
    root = dom.documentElement
    applications = root.getElementsByTagName("Identity")
    if len(applications) > 0 and applications[0].nodeName == 'Identity':
        version = applications[0].getAttribute("Version")
        lastIndex = version.rfind(".")
        return version[:lastIndex]
    else:
        return None


def getWPAllMetaDataElements(root):
    applications = root.getElementsByTagName("Application.Resources")
    if applications[0].nodeName == 'Application.Resources':
        return applications[0].getElementsByTagName("x:String")


def getWPAppMinVersion():
    if platform != 'WP':
        return
    xmlPath = getWPAppXmlPath()
    dom = xml.dom.minidom.parse(xmlPath)
    root = dom.documentElement
    metaDatas = getWPAllMetaDataElements(root)
    for meta in metaDatas:
        if meta.getAttribute("x:Key") == "AppMinVersion":
            return meta.firstChild.data
# iOS

if __name__ == "__main__":
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'p:vm')
        for opt, arg in opts:
            if opt in ('-p'):
                platform = arg
                initData()
            elif opt in ('-m'):
                isReadMinVersion = True
            elif opt in ('-v'):
                isReadVersion = True

        if isReadVersion:
            print getAppVersion()
            sys.exit(0)
        elif isReadMinVersion:
            print getAppMinVersion()
            sys.exit(0)
    except getopt.GetoptError:
        usage()
        sys.exit()
