
Oracle Error Lookup
===================

At times it would be nice to have a lookup tool for Oracle errors that does not require an oracle installation.

This tool started out to be just for GoldenGate error messages, as I need to look up some GoldenGate error, and don't always have GoldenGate available for that.

The Oracle Error message files are found at $ORACLE_HOME/rdbms/mesg/*.msg.

These should be copied to the same location as this script. 

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

## oerr.pl - Generating msg files from msb files

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

