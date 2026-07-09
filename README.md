# WebCertInfo
Pull, Check, and Verify SSL Certificates from Web Sites

Do you have a website with a soon-to-expire ssl certificate? Do you have more than one server needing checked? Is it a slow, tedious task to click through your browser to pull that information? Would you like an easiy to script out process? This is your tool!

Examples: Pull the issued/expired dates.
$ ./WebCertInfo.sh github.com date
Start=Jul 3 2026 GMT
Expire=Sep 30 2026 GMT

Examples: Pull the expired date.
$ ./WebCertInfo.sh github.com expire
Sep 30 2026

Examples: Check of the certificate has expired
$ ./WebCertInfo.sh github.com check-expire
valid
