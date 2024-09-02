
Oracle Error Lookup
===================

At times it would be nice to have a standalone lookup tool for Oracle errors, one that does not require an oracle installation.

This tool started out to be just for GoldenGate error messages, as I need to look up some GoldenGate error, and don't always have GoldenGate available for that.

The Oracle Error message files are found at $ORACLE_HOME/rdbms/mesg/*.msg.

The `oerr.pl` script can read the `*.msg` files and return the error text.

The `*.msg` files should be copied to the same location as this script.  A soft link to each file will also work.

## GoldenGate

While the RDBMS has handy text files for error messages, GoldenGate does not.

The `oggus.msg` message file for GoldenGate may be created by copying the `gen-oggus.sh` script to a server that has GoldenGate installed.

Set the environment appropriately by `gen-oggus.sh` , and retrieving `oggus.msg` back to the directory where `oerr.pl` is located.

## Examples

### RDBMS

'ora' is the default message type, so just the error number is needed:

```text
$  ./oerr.pl 1555
01555, 00000, "snapshot too old: rollback segment number %s with name \"%s\" too small"
// *Cause: rollback records needed by a reader for consistent read are
//         overwritten by other writers
// *Action: If in Automatic Undo Management mode, increase undo_retention
//          setting. Otherwise, use larger rollback segments
```

### RMAN

```text
$  ./oerr.pl 5017 rman
5017, 1, "no copy of datafile %d found to recover"
// *Cause: A RECOVER COPY command was not able to proceed because no
//         copy of indicated file was found to recover.
//         Possible causes include the following:
//         1. no copy of indicated file exists on disk that satisfy the
//            criteria specified in the user's recover operands.
//         2. copy of indicated datafile exists on disk but no incremental
//            backup was found to apply to the datafile copy.
// *Action: One of the following:
//         1. Use or correct TAG specification to recover a different
//            datafile copy.
//         2. Use BACKUP FOR RECOVER OF COPY command to create necessary
//            incremental backup or copy.
```

### asmcmd

```text
$  ./oerr.pl 8003 asmcmd
8003,  1,  "command disallowed by current instance type"
// *Cause:  ASMCMD was connected to an instance with an instance type other than
//          Oracle Automatic Storage Management (Oracle ASM).
// *Action: Ensure you are connecting to an instance whose INSTANCE_TYPE
//          parameter is Oracle ASM.
/
```

## See all message types

```text

$  ./oerr.pl -h

oerr.pl -h
oerr.pl ERRNUM
oerr.pl ERRNUM MSGTYPE

Message Types:
    amdu: ASM amdu messages
  asmcmd: ASM asmcmd messages
     dbv: DataGuard broker messages
     dia: Diagnosibility Workbench messages
     exp: oracle exp messages
     gim: generic instance monitor messages
     imp: oracle imp messages
    kfed: ASM kfed messages
    kfod: ASM kfod messages
    kfsg: ASM kfsg (kernel file set gid utility) messages
     kgp: KG Platform
     kop: KOPZ?
     kup: XAD?
     lcd: Error messages for LCD and LCC
     nid: nid - newid utitilty
     oci: oracle call interface messages
     ogg: oracle goldengate messages
     opw: orapwd utitilty messages
     ora: oracle rdbms messages
     qsm: oracle summary management advisor messages
    rman: RMAN messages
     sbt: SBTTEST error messages - RMAN test tape driver
     smg: Oracle server manageability messages
     ude: Oracle Data Pump messages
     udi: Oracle Data Pump In Memory messages
      ul: Oracle SQLLDR messages



        oerr.pl errnum [msg type]

        where [msg type] is ora|amdu|gg|ogg|...

        default is 'ora'
```

## oerr-gen.pl - Generating msg files from msb files

Should you want to generate the a msg file from an msb file, this script will do that.

Why would you want to do that?  

Perhaps you have installed Oracle as US English, and would like a copy of the message file in French.

`oerr.pl` can generate the file 'oraf.msg'

```text
  ./oerr-gen.pl  $ORACLE_HOME/rdbms/mesg/oraf.msb  > oraf.msg
```

Then the French error text can be retrieved with oerr.pl by including a language flag.

```text
 $  ./oerr.pl 1555 ora f
 01555, 00000, "clich�s trop vieux : rollback segment no %s, nomm� "%s", trop petit"
```

Multibyte characters do not yet work properly.

Also, the comments normally seen when using oerr do not appear, as the comments are not stored in the msb file.

```text
  $ ./oerr.pl 1555
  01555, 00000, "snapshot too old: rollback segment number %s with name \"%s\" too small"
  // *Cause: rollback records needed by a reader for consistent read are
  //	   overwritten by other writers
  // *Action: If in Automatic Undo Management mode, increase undo_retention
  //          setting. Otherwise, use larger rollback segments
```

## oerrs.pl - Standalone lookup utility

The messages are embedded into the oerrs.pl script so that only 1 file needs to be copied.

See `oerrs.pl -h` and `perldoc oerrs.pl` on how to generate the error hash file for insertion into the script.

```text

    $  ./oerrs.pl 6502
    06502  "PL/SQL: numeric or value error%s"
    // *Cause: An arithmetic, numeric, string, conversion, or constraint error
    //         occurred. For example, this error occurs if an attempt is made to
    //         assign the value NULL to a variable declared NOT NULL, or if an
    //         attempt is made to assign an integer larger than 99 to a variable
    //         declared NUMBER(2).
    // *Action: Change the data, how it is manipulated, or how it is declared so
    //          that values do not violate constraints.
```

The are currently 2 sets of error messages loaded:

  - ora
  - ogg

```text
    ./oerrs.pl 171 ogg
    00717  "Found unsupported in-memory undo record in sequence {0}, at RBA {1}, with SCN {2} ... Minimum supplemental logging must be enabled to prevent data loss."
    // *{0}: seqNo (Number)
    // *{1}: RBA (Number)
    // *{2}: SCN (String)
    // *Cause:  Minimal supplemental logging is not enabled, so Oracle may use
    //          in-memory undo. This causes multiple undo/redo pairs to be written
    //          within the same redo record. Extract does not support these types
    //          of records.
    // *Action: Enable minimal supplemental logging. For instructions on how to set
    //          logging for Oracle GoldenGate, see the Oracle GoldenGate
    //          installation and setup documentation for the Oracle database.
```

## oerrs - Golang

A Golang version has been created as well.  This is convenient for cross compilation.

The script `golang/build.sh` will create both a Linux and a Windows executable.

The errors for Oracle 19.3 and Golden Gate (sorry, do not have version info handy) are included in the executable.

The following are done by the build script:

- build the linux version
- build the windows version
- run the linux version

```text
$  ./build.sh
oerrs.exe: PE32+ executable (console) x86-64 (stripped to external PDB), for MS Windows
oerrs: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=fWrm413cbHrj1cCFNvmq/OtBKzWElVNilLIfpNh46/ipfTyf6fNqu4LGDSSzaw/8RfCt3Ou2kGP8gPgr7po, not stripped
06502  "PL/SQL: numeric or value error%s"
// *Cause: An arithmetic, numeric, string, conversion, or constraint error
//         occurred. For example, this error occurs if an attempt is made to
//         assign the value NULL to a variable declared NOT NULL, or if an
//         attempt is made to assign an integer larger than 99 to a variable
//         declared NUMBER(2).
// *Action: Change the data, how it is manipulated, or how it is declared so
//          that values do not violate constraints.
```

### Create Oracle Error Message JSON

The JSON embedded in the `oerrs.go` source is created by loading error messages into memory, then dumpig the Perl Hash.

That Perl Hash file is then read by another script to convert it to JSON.

The JSON is then directly embedded into the Go source.

#### Create the Hash file

```text
$  ./oerr-gen-hash.pl rman > rman.has
$  ls -l rman.hash
-rw-r--r-- 1 jkstill dba 671201 Sep  2 12:39 rman.hash
```

#### Convert the Hash to JSON

```text
$ cd golang
$  ./convert-hash-to-json.pl ../rman.hash > rman.json

```

#### Embed JSON into go source

The structure the Hash and the resulting JSON is Language->Facility->Error#

As the source already includes the Language, those bits from the resulting JSON are not needed.

Remove the unnecessary lines at the beginning and end of the JSON file:

##### Before

Beginning:

```json
{ <--- remove
   "us" : { <--- remove
      "rman" : { 
         "6834" : {
            "DESC" : " \"pluggable database %s does not have any data files\"",
            "TEXT" : [
               "// *Cause: An attempt was made to back up data files from a pluggable",
               "//         database (PDB) that did not have any data files.",
               "// *Action: Remove the PDB from the command and retry."
            ]
         }, 
         "6501" : {
...
```

End:

```json
... 
         },    
         "6773" : {
            "TEXT" : [
               "// *Cause:  This is an informational message only.",
               "// *Action: No action is required."
            ],
            "DESC" : " \"connected to source recovery catalog database\""
         }     
      }        
   } <--- remove
} <--- remove

```


##### After

Beginning:

```json
      "rman" : {
         "6834" : {
            "DESC" : " \"pluggable database %s does not have any data files\"",
            "TEXT" : [
               "// *Cause: An attempt was made to back up data files from a pluggable",
               "//         database (PDB) that did not have any data files.",
               "// *Action: Remove the PDB from the command and retry."
            ]
         }, 
         "6501" : {

```

End:

```json
         },    
         "6773" : {
            "TEXT" : [
               "// *Cause:  This is an informational message only.",
               "// *Action: No action is required."
            ],
            "DESC" : " \"connected to source recovery catalog database\""
         }     
      }   
```

##### Insert rman.json into go source

At the end of the file:

```text

        "01130" : {
            "TEXT" : [
               "// *{0}: functionName (String)",
               "// *{1}: errorCode (Number)",
               "// *{2}: nsortErrorText (String)",
               "// *Cause:  The Nsort sorting function failed with the specified error.",
               "// *Action: Fix the problem according to the Nsort error message."
            ],
            "DESC" : " \"NSort function {0} failed with {1} - {2}\""
         }
      },  <--- comma added here.  add rman.json after this line
   }
}`

```

##### Add rman to msg facilities:

```go

   // rman error numbers of 3 digits may be padded to 4 with a zero
   msgFacility := map[string][]interface{}{
      "ora":   {5, false, false, "oracle rdbms messages"},
      "ogg":   {5, false, false, "oracle goldengate messages"},
      "rman":   {4, false, false, "oracle rman messages"},
      "amdu":  {4, false, true, "ASM amdu messages"},
      "asmcmd": {0, true, true, "ASM asmcmd messages"},
      // add more entries as needed
   }
```

Now run `build.sh`

```text
$  ./build.sh
oerrs.exe: PE32+ executable (console) x86-64 (stripped to external PDB), for MS Windows
oerrs: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=NO6M1wZHJbTrscxxLsuA/b4lWtMlifgxy1E879cTi/3xrWVr_prpXoPb0WUbqv/vd60KIC__6IyFmapgXL8, not stripped
06502  "PL/SQL: numeric or value error%s"
// *Cause: An arithmetic, numeric, string, conversion, or constraint error
//         occurred. For example, this error occurs if an attempt is made to
//         assign the value NULL to a variable declared NOT NULL, or if an
//         attempt is made to assign an integer larger than 99 to a variable
//         declared NUMBER(2).   
// *Action: Change the data, how it is manipulated, or how it is declared so
//          that values do not violate constraints. 

```

Get RMAN specific errors:

```text

$  ./oerrs 597 rman
0597  "checksyntax  none           check the command file for syntax errors"


$  ./oerrs 0597 rman
0597  "checksyntax  none           check the command file for syntax errors"


$  ./oerrs 6058 rman
6058  "a current control file cannot be included along with a standby control file"
// *Cause:  "standby control file" was specified along with
//          "current control file".
// *Action: Remove "standby control file" or "current control file" from
//          backup specification.


```







