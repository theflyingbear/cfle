
This is intended as a hook to be used with [dehydrated](https://github.com/lukas2511/dehydrated), to use **dns-01** challenges with DNS hosted at CloudFlare.

Dependencies (only tools you should already have on your system):
- bash
- awk / sed / cut / tr / python (2.x) / ...
- curl 

Usage:
- locate your installation of dehydrated
- go in the `hooks` folder
- clone this
- edit `cf.cfg.sh` to set you CloudFlare API Key
- in you `config` or `config.txt` file (for dehydrated), set:

`HOOK=${BASEDIR}/hooks/cfle/cf-hook.sh`


