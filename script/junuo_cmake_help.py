import sys
import os
import concurrent.futures
import subprocess
import re
from pathlib import Path
import json
import hashlib

g_strClass = 'class'
g_strMethod = 'method'
g_strContent = 'content'
g_strSourceDir = 'source-dir'
g_strOutputDir = 'output-dir'
g_strOutputFile = 'output-file'
g_strQtBinDir = 'qt-bin-dir'

def parseCommandLine(commandLineList: list) -> dict:
    ret = {}
    ret[g_strClass] = commandLineList[0]
    ret[g_strMethod] = commandLineList[1][2:]
    ret[g_strContent] = commandLineList[2].split(';')
    if '' in ret[g_strContent]:
        ret[g_strContent].remove('')
    index = 3
    while index < len(commandLineList):
        currentStr = commandLineList[index]
        if currentStr.startswith('--'):
            ret[currentStr[2:]] = commandLineList[index + 1]
        elif currentStr.startswith('-'):
            ret[currentStr[1:]] = commandLineList[index + 1]
        index += 2
    return ret

def calculateMd5(filePath: str) -> str:
    with open(filePath, 'rb') as file:
        md5 = hashlib.md5()
        while True:
            data = file.read(4096)
            if not data:
                break
            md5.update(data)
        return md5.hexdigest()

def toStandardPath(path: str) -> str:
    return path.replace('\\\\', '/').replace('\\', '/')

class JunuoMoc:
    def __init__(self, argMap: dict):
        self.checkMethodName = 'check'
        self.compiltMethodName = 'compile'
        self.method = argMap[g_strMethod]
        self.sourceDir = toStandardPath(argMap[g_strSourceDir])
        self.content = argMap[g_strContent]
        for i in range(len(self.content)):
            self.content[i] = toStandardPath(os.path.join(self.sourceDir.rstrip('/'), self.content[i]))
        if self.method == self.compiltMethodName:
            self.qtBinDir = toStandardPath(argMap[g_strQtBinDir]).rstrip('/')
            self.outputDir = toStandardPath(argMap[g_strOutputDir]).rstrip('/') + '/moc'
            self.outputFileName = self.outputDir + '/' + toStandardPath(argMap[g_strOutputFile])
            self.mocCacheFileName = self.outputDir + '/junuo_moc.cache'
            if os.path.exists(self.mocCacheFileName):
                with open(self.mocCacheFileName, 'r') as file:
                    self.mocCache = json.load(file)
            else:
                self.mocCache = {}
            self.strMd5Key = 'md5'
            self.strMocFileKey = 'moc_file'

    def __del__(self):
        if self.method == self.compiltMethodName:
            with open(self.mocCacheFileName, 'w') as file:
                json.dump(self.mocCache, file, indent=4)

    def doWork(self):
        match self.method:
            case self.checkMethodName:
                self.check()
            case self.compiltMethodName:
                self.compile()

    def check(self):
        for absoluteFileName in self.content:
            if self.isNeedMoc(absoluteFileName):
                print(os.path.relpath(absoluteFileName, self.sourceDir))

    def compile(self):
        isNeedCombine = False
        maxWorkerCount = os.cpu_count()
        if maxWorkerCount is None:
            maxWorkerCount = 1
        with concurrent.futures.ThreadPoolExecutor(max_workers=maxWorkerCount) as executor:
            for absoluteFileName in self.content:
                if not self.isNeedReMoc(absoluteFileName):
                    continue
                isNeedCombine = True
                if absoluteFileName in self.mocCache.keys():
                    mocFileName = self.mocCache[absoluteFileName][self.strMocFileKey]
                else:
                    fileNameWithoutExt, _ = os.path.splitext(os.path.basename(absoluteFileName))
                    mocFileName = '/'.join([self.outputDir, 'moc_' + fileNameWithoutExt + '.moc'])
                    index = 1
                    while os.path.exists(mocFileName):
                        mocFileName = '/'.join([self.outputDir, 'moc_' + fileNameWithoutExt + '_' + str(index) + '.moc'])
                        index += 1
                self.mocCache[absoluteFileName] = {self.strMd5Key : calculateMd5(absoluteFileName), self.strMocFileKey : mocFileName}
                executor.submit(self.moc, absoluteFileName, mocFileName)
        if not isNeedCombine:
            return
        with open(self.outputFileName, 'w') as file:
            for mocFileName in list(Path(self.outputDir).rglob('*.moc')):
                with open(mocFileName, 'r') as mocFile:
                    file.write(mocFile.read())

    def moc(self, absoluteFileName: str, outputFileName: str):
        mocExecName = 'moc'
        if os.name == 'nt':
            mocExecName = 'moc.exe'
        absoluteMocExecPath = '/'.join([self.qtBinDir, mocExecName])
        commandLine = [absoluteMocExecPath, absoluteFileName, '-o', outputFileName]
        subprocess.run(commandLine)

    def isNeedMoc(self, absoluteFileName: str) -> bool:
        with open(absoluteFileName, 'r', encoding='utf8') as file:
            line = file.readline()
            while line:
                if 'Q_OBJECT' in line:
                    return True
                line = file.readline()
        return False

    def isNeedReMoc(self, absoluteFileName: str) -> bool:
        if not self.isNeedMoc(absoluteFileName):
            return False
        if absoluteFileName not in self.mocCache.keys():
            return True
        return self.mocCache[absoluteFileName][self.strMd5Key] != calculateMd5(absoluteFileName)

class JunuoRcc:
    def __init__(self, argMap: dict):
        self.checkMethodName = 'check'
        self.method = argMap[g_strMethod]
        self.sourceDir = toStandardPath(argMap[g_strSourceDir])
        self.content = argMap[g_strContent]
        for i in range(len(self.content)):
            self.content[i] = toStandardPath(os.path.join(self.sourceDir.rstrip('/'), self.content[i]))

    def doWork(self):
        match self.method:
            case self.checkMethodName:
                self.check()

    def check(self):
        pattern = re.compile('<file>(.*)</file>')
        for absoluteFileName in self.content:
            path = os.path.dirname(absoluteFileName)
            relPath = os.path.relpath(path, self.sourceDir)
            with open(absoluteFileName, 'r', encoding='utf8') as file:
                line = file.readline()
                while line:
                    match = pattern.search(line)
                    if match:
                        print('/'.join([relPath, match.group(1)]))
                    line = file.readline()

if __name__ == "__main__":
    if len(sys.argv) <= 1:
        sys.exit(0)
    with open('D:/1.txt', 'a') as file:
        file.write(str(sys.argv))
        file.write('\n')
    argMap = parseCommandLine(sys.argv[1:])
    match argMap[g_strClass]:
        case 'moc':
            JunuoMoc(argMap).doWork()
        case 'rcc':
            JunuoRcc(argMap).doWork()
