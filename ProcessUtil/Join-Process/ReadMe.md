# Join-Process
A utility that allows you to wait until another process (and it's descendants) finish.

usage: Join-Process [-pid <pid> | -name <process name>] [-i <sec>] [-wait-for-children] [-v] [-help]

* -help ... Print this help text
* -v .. be verbose
* -pid ... attaches to a process by its id
* -name ... attaches to a process by its name
* -i ... specify the interval (in seconds) to check for changes (default is 1)"
* -wait-for-children ... wait until all of the processes child processes also terminated

NOTE: -wait-for-children implies all descendants, also those which descent from child processes!
