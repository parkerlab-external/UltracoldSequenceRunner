# Ultracold Sequence Runner
Write your experimental sequence in a declarative file and send through a USB wire! 
Multiple module types supported.
For more information, see https://arxiv.org/abs/2408.13652.
## Try it out
### Setup!
- Clone the repo with containing library in your system console (Once):
```bash
git clone --recurse-submodules https://github.com/parkerlab-external/UltracoldSequenceRunner.git.
```
- In Matlab's console, load library using script (every time you load Matlab):
```matlab
loadlib
```
### Test it!
- For a test to generate `uint8` command list from the sequence files `oneeach_symb.xml` and `oneeach_numeric.xml` and print out formatted output, simply run
```matlab
testprepall
```
These two sequences should yield the same results in the log files, where you should see something like this:
```
▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ 
Command List for Analog module at address 0x2A (042) 
 ┄ prefix ┄┄ slot id ┄┄ range mode ┄
 ░░░░ G ░░░░░░░ 00 ░░░░░░░░ 08 ░░░░░
 ░░░░ G ░░░░░░░ 01 ░░░░░░░░ 08 ░░░░░
 ░░░░ G ░░░░░░░ 02 ░░░░░░░░ 05 ░░░░░
 ░░░░ G ░░░░░░░ 03 ░░░░░░░░ 07 ░░░░░
 ┄ prefix ┄┄ slot id ┄┄ chkpt count ┄
 ░░░░ E ░░░░░░░ 00 ░░░░░░░ 00 0E ░░░░
 ░░░░ E ░░░░░░░ 01 ░░░░░░░ 00 0E ░░░░
 ░░░░ E ░░░░░░░ 02 ░░░░░░░ 00 09 ░░░░
 ░░░░ E ░░░░░░░ 03 ░░░░░░░ 00 03 ░░░░
 ┄ prefix ┄┄ slot id ┄┄ chkpt pos ┄┄┄┄ duration ┄┄┄┄┄ voltage ┄┄┄
 ░░░░ U ░░░░░░░ 00 ░░░░░░ 00 00 ░░░░ FF FF FF FE ░░ 80 00 80 00 ░
 ░░░░ U ░░░░░░░ 00 ░░░░░░ 00 01 ░░░░ FF FF FF FE ░░ 93 C6 80 00 ░
 ░░░░ U ░░░░░░░ 00 ░░░░░░ 00 02 ░░░░ 00 02 57 9A ░░ 00 00 00 00 ░
 ░░░░ U ░░░░░░░ 00 ░░░░░░ 00 03 ░░░░ FF FF FF FE ░░ 93 C6 80 00 ░
 ░░░░ U ░░░░░░░ 00 ░░░░░░ 00 04 ░░░░ FF FF FF FE ░░ 80 00 80 00 ░
 ░░░░ U ░░░░░░░ 00 ░░░░░░ 00 05 ░░░░ 00 00 05 DA ░░ 00 00 00 00 ░
...
```
You don't need serial connection for this test. It simply outputs to the console.
### Run it!
To test on real modules. You need to connect your PC to the repeater module through USB. Make sure your repeater module is connected to other modules specified in your XML sequence file through the Backplane and all modules are powered. 
- Setup a serial connection
```matlab
sp = serialport("COM4", 115200); 
```
Replace `"COM4"` with whatever COM that connects your PC to the repeater module. You may need to try and fail several times to find out which one it is.
- Run by 
```matlab
QuickUpdate(dicts, sp, address, filename_xml)
```
where `address` is the address of the leader module (which sends off the START signal). You can also breakup the commands by
```matlab
UpdateFromXML(dicts, sp, filename_xml);
SerialStartDevice(sp, address);
SerialStartDevice(sp, address);
SerialStartDevice(sp, address);
```
This will update all modules once and run three times. You may need to manually insert pauses in between start commands.
## Do It Yourself!
To use this library, you need the following configurations:
- A sequence file in XML format. The root node of the file is
```xml
<?xml version="1.0" encoding="utf-8"?>
<experiment_sequence>
</experiment_sequence>
```
Within the file, you can add sequences of different modules. Each module is represented by a XML element with the tag name matching the module type. Inside are tags for channels, and each channel contains a CSV.
```xml
<module_type>
    <channel attr="010" attr2="attribute value">
        expr0,   expr1,   expr2
        ...
    </channel>
    <channel>
     ...
</module_type>
```
The values in the CSV can be numeric or symbolic expressions.
- The dictionary: a structure containing key-value pairs representing the values of the parameters. If you use an all-numeric sequence file, you can simply use an empty structure `struct()`. You can also generate these dictionaries using declarative YAML files using our library [TestRunner](https://github.com/KySpace/TestRunner/).
- A log file's `fid` to write to, by default, this is `1`, which prints to the console. Create the file by
```matlab
fid = fopen("seq_cmd.txt", "w");
```
## Extend it!
If you want to add your own modules, you need to include the following custom functions to your path for each module:
- The parser: `seq_symb = ParseXXX(node)`, that turns the XML node of the module to a sequence containing symbolic expressions as data. The returned structure needs to include the required fields.
- The command builder: `seq_cmd_u8 = BuildCmdXXX(seq_num, time_last, mod_info, file_log)`, that builds the flattened `uint8` array of command list from a numeric sequence: the sequence where expressions are evaluated into numeric values. The `time_last` is the longest time of the entire multi-module sequence. `mod_info` contains additional information for the module type.
- The scaler: `ScaleToXXX(vals, range)` which scales the numeric values from natural units to values recognized by the devices. The scaling is different for different data type and gain modes and is encoded in the `range` parameter: an array of minimum and maximum values. You can also avoid scaling by using `id1` function, which returns the first input argument.

To tell the sequence runner which custom functions to look to, as well as how the `uint8` command list is formatted, modify `map_module.json`, where you can also specify how the logs are printed.
## Peek inside
### Call Hierarchy and data flow.
```rust
                                          ┌─────┬────────────────────────┐ // The address of the Leader
QuickUpdate                      (dicts, sp, address, filename_xml, ...) │
    │                              │      │     ┌────────┘               │
    ├─ UpdateFromXML             (dicts, sp, filename_xml)               │
    │    │                         │            │                        │
    │    │ /*generate sequence*/   │            │                        │
    │    │ /*no communication*/    ↓            │                        │
    │    ├─ PrepFromXML          (dicts,     filename_xml, file_debug)   │    
    │    │    │                    │            ↓                        │
    │    │    ├ ParseXML           │        (filename_xml, map_mod)      │    
    │    │    │   └ Parse...           (node) ─┐              // seq_symb : sequence with symbolic values   
    │    │    │   /*per mod type*/ ↓           ↓                         │    
    │    │    ├ MakeNumericQueue (dicts, seq_symb, map_mod) ┐ // seq_num : sequence with numeric values    
    │    │    │   └ ScaleTo...         (...)  ┌─────────────┘            │  
    │    │    │   /*per mod type*/            ↓                          │
    │    │    └ BuildCmd...            (seq_num, ...) ────┐   // cmdlist_u8 : sequence converted to uint8 array, log is printed here
    │    │        /*per mod type*/                        │              │
    │    │                                 ┌─────┬───────────────────────┤ 
    │    │ /*update by writing*/           ↓     ↓        ↓              │
    │    ├─ SerialWriteToDevice          (sp, address, cmdlist_u8) ┐ // response : containing the response type    
    │    ├─ HandleResponse                 ↓ (address, response) ←─┘     │               
    │    └─ SerialEndMessage             (sp)                            │ 
    │                                      ┌─────┬───────────────────────┘                      
    │   /*start with sync*/                ↓     ↓                          
    └── SerialStartDevice                (sp, address)                                      
         └─ SerialEndMessage             (sp)
```
