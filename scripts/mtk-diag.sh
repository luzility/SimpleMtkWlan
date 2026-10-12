#!/bin/sh
# Collects everything needed to see why SimpleMtkWlan did or did not start.
# Run on the macOS side after booting with the kext:
#     sudo sh /Volumes/EFI/mtk-diag.sh
# Output goes to <EFI>/mtk-diag (readable from Windows too), else ~/Desktop.

OUT=/Volumes/EFI/mtk-diag
[ -d /Volumes/EFI/EFI/OC ] || OUT="${HOME:-/tmp}/Desktop/mtk-diag"
mkdir -p "$OUT" && cd "$OUT" || exit 1
echo "Writing to $OUT ..."

PRED='sender == "SimpleMtkWlan" OR eventMessage CONTAINS[c] "SimpleMtkWlan" OR eventMessage CONTAINS[c] "MtkWlan" OR eventMessage CONTAINS[c] "mwx"'

{
	date
	sw_vers
	uname -a
	echo "--- boot-args"
	nvram boot-args 2>&1
	echo "--- loaded kexts (mtk/mediatek)"
	kmutil showloaded --list-only 2>/dev/null | grep -iE 'mtk|mediatek|7922' || echo "(none)"
	echo "--- MediaTek kexts installed on disk"
	ls -d /Library/Extensions/*.kext 2>/dev/null | grep -iE 'mtk|mediatek|7922' || echo "(none)"
	echo "--- IOService nodes for 14c3"
	ioreg -w0 -p IOService -l | grep -nE '"vendor-id" = <c3140000>' || echo "(no PCI device with vendor 14c3)"
	echo "--- SimpleMtkWlan driver instances"
	ioreg -w0 -p IOService -c SimpleMtkWlan | grep -E 'SimpleMtkWlan|en[0-9]' || echo "(none attached)"
} > summary.txt 2>&1

# The driver keeps its own log on the PCI nub; it survives a failed start.
ioreg -w0 -a -p IOService -r -k SimpleMtkWlan-log > driver-log.plist 2>&1
plutil -extract 0.SimpleMtkWlan-log raw -o driver-log.txt driver-log.plist 2>/dev/null \
	|| echo "(no SimpleMtkWlan-log property: driver never probed, or an older build)" > driver-log.txt

ioreg -w0 -p IOService -l -c IOPCIDevice > ioreg-pci.txt 2>&1
ioreg -w0 -p IOService -t > ioreg-tree.txt 2>&1
ioreg -w0 -p IOService -l -c IOEthernetController > ioreg-ethernet.txt 2>&1
system_profiler SPPCIDataType > system-profiler-pci.txt 2>&1

echo "Reading unified log (this can take a minute) ..."
log show --last boot --style compact --predicate "$PRED" > log-driver.txt 2>&1
log show --last boot --style compact --predicate 'process == "kernelmanagerd"' 2>/dev/null \
	| grep -iE 'mtk|mediatek|laobamac|7922' > log-kernelmanagerd.txt
dmesg > dmesg.txt 2>&1

# Most recent kernel panic report, if any.
ls -t /Library/Logs/DiagnosticReports/*panic* 2>/dev/null | head -2 | while read -r f; do cp "$f" .; done

echo "Done. Files:"
ls -l
