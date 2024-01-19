# Ren'Py Decompiler Backend

This tool allows you to work with Ren'Py's `.rpa` and `.rpyc` files.

This piece of software decompiles `.rpa` and `.rpyc` files, 
allowing you to scrape the original assets used in a Ren'Py game, where RPAs are used.

## Feature list/Roadmap
- [x] Decompiling RPA files
- Decompiling RPYC files
  - [x] Normal RPYC decompiler (successfully decompiled 96.75% of the .RPYC files I tested, tests mainly done on DDLC)
  - [ ] Screen RPYC decompiler
  - [x] SL2 RPYC decompiler (successfully decompiled the remaining 3.25% of the .RPYC files I tested, same conditions)
  - [ ] Testcase RPYC decompiler
- [x] CLI to decompile RPAs
- [ ] CLI to decompile RPYC files