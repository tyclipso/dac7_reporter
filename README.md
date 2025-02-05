# DAC7 Reporter

(Go to [English summary](#English-summary))

DAC7 Reporter ist ein Programm zur Übermittlung von Pflichtmitteilungen für das
Plattformen-Steuertransparenzgesetz (PStTG) im XML/DIP-Format über die DPI/DAC7-Schnittstelle (auch
bekannt als ELSTER / CESOP).

Das Desktopprogramm kann für Linux, macOS und Windows kompiliert werden.

## Build Prozess

### Flutter Anwendung

Die Flutter Anwendung kann normal über Flutter gebaut werden, für macOS z.B.:

`flutter build macos`

### Java Anwendung für Signatur

Die Signatur muss im Format SHA256-RSA-MGF1 (http://www.w3.org/2007/05/xmldsig-more#sha256-rsa-MGF1)
erfolgen. In Dart/Flutter scheint dafür noch keine öffentliche Implementation zu existieren.

Da die Signatur nicht direkt in der Dart App erstellt werden kann, wird dafür eine externe
Java Anwendung aufgerufen. Zunächst muss die Datei XmlSigner.java mit Java zu einer Class-Datei
kompiliert werden:

`javac XmlSigner.java`

Optional kann mit der GraalVM noch eine binär kompilierte Version der Java Anwendung erzeugt werden.
Das hat den Vorteil, dass der Nutzer Java nicht installiert haben muss.  Die binäre Variante muss
entsprechend der Plattform benannt werden:

- xmlsigner_macos_arm64 für macOS
- xmlsigner_windows_amd64.exe für Windows
- xmlsigner_linux_amd64 für Linux

Sowohl die Datei `XmlSigner.class`, als auch optional die binäre Version, müssen in das gleiche
Verzeichnis, wie die ausführbare Datei kopiert werden. Unter Windows ist dies die Exe-Datei, unter
macOS das App-Bundle.

Für die Signatur wird zunächst geprüft, ob die kompilierte Java Anwendung vorhanden ist. Wenn nicht,
wird versucht über den `java` Befehl die Java Anwendung zu starten. Schlägt das auch fehl, gibt die
Anwendung einen Fehler aus. Ohne die Java Anwendung können nur bereits signierte XML-Dateien
übermittelt werden.

## Kontakt

- Webseite: https://www.tyclipso.net
- Github: https://github.com/tyclipso/dac7_reporter

## English summary

DAC7 Reporter is a desktop application to submit signed XML files in the DIP format to the DPI/DAC7
API. This is a German government API for reporting tax related information.

The application can be compiled for Linux, macOS and Windows. It is currently only available in
German, as usage outside of Germany is pretty limited.

For any questions about this application or the submit process, visit https://www.tyclipso.net or
https://github.com/tyclipso/dac7_reporter