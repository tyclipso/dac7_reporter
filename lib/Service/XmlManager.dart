import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

/// Class for XML operations
class XmlManager {
  static final XmlManager _defaultManager = XmlManager();

  static XmlManager defaultManager() {
    return _defaultManager;
  }

  /// Sign the XML file
  Future<String?> signXml(String originalXmlFile, String privateKeyPemFile, String certificatePemFile) async {
    ProcessResult processResult;
    String execPath = Platform.resolvedExecutable;
    File execFile = File(execPath);
    Directory execDir = execFile.parent;
    // We can't include the executables into the bundle, go up 3 levels (from .app/Contents/MacOS)
    if (Platform.isMacOS) {
      execDir = execDir.parent.parent.parent;
    }
    String dirName = execDir.path;
    // Check if the precompiled java executable exists, otherwise try the java class and hope java exists in the path
    final deskTopArguments = [privateKeyPemFile, certificatePemFile, originalXmlFile];
    if (Platform.isMacOS && _fileExists("xmlsigner_macos_arm64", dirName)) {
      processResult = await Process.run("$dirName${Platform.pathSeparator}xmlsigner_macos_arm64", deskTopArguments, workingDirectory: dirName, runInShell: false);
    } else if (Platform.isWindows && _fileExists("xmlsigner_windows_amd64.exe", dirName)) {
      processResult = await Process.run("$dirName${Platform.pathSeparator}xmlsigner_windows_amd64.exe", deskTopArguments, workingDirectory: dirName, runInShell: false);
    } else if (Platform.isLinux && _fileExists("xmlsigner_linux_amd64", dirName)) {
      processResult = await Process.run("$dirName${Platform.pathSeparator}xmlsigner_linux_amd64", deskTopArguments, workingDirectory: dirName, runInShell: false);
    } else {
      final arguments = ["-cp", dirName, "XmlSigner", privateKeyPemFile, certificatePemFile, originalXmlFile];
      processResult = await Process.run("java", arguments, workingDirectory: dirName, runInShell: false);
    }
    var resultString = processResult.stdout;
    var errorString = processResult.stderr;
    if (errorString.toString().isEmpty && resultString.toString().isNotEmpty) {
      // Transfer the data as base64
      resultString = Utf8Decoder().convert(base64.decode(resultString.toString().trim()));
      return resultString;
    } else {
      dev.log("result: $errorString");
      return null;
    }
  }

  /// Check if a file exists in the specified directory
  bool _fileExists(String fileName, String dirName) {
    String completePath = "$dirName${Platform.pathSeparator}$fileName";
    File platformExec = File(completePath);
    return platformExec.existsSync();
  }
}