#!/bin/bash
# Reset Question 17 - Binary Verification

rm -rf /opt/course/17
# Remove suspicious kubelet binary created by setup
rm -f /tmp/kubelet-suspicious
# Remove any downloaded checksum files
rm -f kubectl.sha512 kubelet.sha512 2>/dev/null

echo "Question 17 reset complete!"
