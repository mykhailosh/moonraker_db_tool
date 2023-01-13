## Disclaimer
The work is in progress, the script is not tested yet.

Use it at your own risk.

Always backup your moonraker database before using this tool!

## What this script can do?
* Export moonraker history
* Import moonraker history data from json file
* Merge moonraker history data from json file

## Installation
This script requires some Perl modules:

* [Getopt::Long](https://metacpan.org/pod/Getopt::Long)
* [LMDB_File](https://metacpan.org/pod/LMDB_File)
* [JSON](https://metacpan.org/pod/JSON)
* [local::lib](https://metacpan.org/pod/local::lib)

To install it, use [cpanminus](https://metacpan.org/pod/App::cpanminus) 
```
sudo apt install cpanminus
cpanm JSON Getopt::Long LMDB_File local::lib
```

Add this line to your ~/.profile or ~/.bashrc
```
eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
```

## Usage
Before use this tool, you should stop moonraker service
```
service moonraker stop
```

### Export
```
moonraker_dbtool.pl --database /home/klipper/printer_data/database --action export
```

```
# Data written to /tmp/moonraker_database_export_1673651072.json
```


### Import
```
moonraker_dbtool.pl --database /home/klipper/printer_data/database --action import --data /tmp/moonraker_database_export_1673651072.json
```
```
# Data has been written to moonraker database
```

### Merge
```
moonraker_dbtool.pl --database /home/klipper/printer_data/database --action merge --data /tmp/moonraker_database_export_1673651072.json
```
```
# Data has been written to moonraker database
```
