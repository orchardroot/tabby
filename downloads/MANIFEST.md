# Downloads manifest

All artefacts verified 2026-09-29. Hashes are SHA-256 unless stated.

| File | Source | Bytes | Hash | Notes |
|---|---|---|---|---|
| twrp_3.1.0-1_sm-t555_13317.tar | Google Drive re-upload linked from XDA thread 4649476 (MCIV800, July 2026) | 15642624 | md5 6c243bd95565529a770544badbb126ed, sha256 503524f7062a51df37aebe4eedb17f9cdc7d74fca0ed0838adf3853e70f08441 | MD5 matches the value published in the thread. Contains recovery.img (15640592 bytes, 2017-03-13). Flashed 2026-09-29, boots TWRP 3.1.0-0. |
| SAMFW.COM_SM-T555_BTU_T555XXU1CRG1_fac.zip | https://samfw.com/firmware/SM-T555/BTU/T555XXU1CRG1 | 1798250591 | f9ba9109cdeb13dbf4d65e7a2bf361be63fd6bf1487b81c7f3156bf7f1b4415c | Stock BTU firmware for rollback. `unzip -t` clean. Contains AP (CRG1), BL (CRG1), CP (CQHA), CSC (BTU CRH1). Newer than the CQJ5 the tablet shipped with; same bootloader revision U1, so heimdall flash is safe. |
| e-1.20-r-20240321-UNOFFICIAL-gt510lte.zip | https://sourceforge.net/projects/eosbuildsronnz98/files/SamsungSmartphones/e-1.20-r-20240321-UNOFFICIAL-gt510lte.zip/download | 853074046 | see below | /e/OS-R 1.20, Android 11, built by ronnz98 from blizzard4591's lineage-18.1 gt510lte tree. |
| pit.txt | `heimdall print-pit` on this unit | | | Tracked in git. 32 partitions. |

## ROM hash

Filled in once the download completes and `unzip -t` passes.
