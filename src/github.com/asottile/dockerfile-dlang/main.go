package main

//#cgo CFLAGS: -I.
//#cgo LDFLAGS: -L. -lsupport
//#include "support.h"
import "C"
import (
	"bytes"
	"unsafe"

	"github.com/asottile/dockerfile"
)



func sliceToTuple(strs []string) unsafe.Pointer {
	slice := C.stringSlice(C.longlong(len(strs)))
	for i, str := range strs {
		C.setStringElement(slice,C.longlong(i),C.CString(str))
	}
	return slice 
}


func convert_commands(cmds []dockerfile.Command) unsafe.Pointer {
	var dCmd, dSubCmd,dOriginal *C.char
	var dJson C.int
	var dStartLine,dEndLine C.int
	var dValue,dFlags,slice unsafe.Pointer

	slice = C.stringSlice(C.longlong(len(cmds)))
	for i, cmd := range cmds {
		dCmd = C.CString(cmd.Cmd)
		dSubCmd = C.CString(cmd.SubCmd)
		if cmd.Json {
			dJson = C.int(1)
		} else {
			dJson = C.int(0)
		}
		dOriginal = C.CString(cmd.Original)
		dStartLine = C.int(cmd.StartLine)
		dEndLine = C.int(cmd.EndLine)
		dFlags = sliceToTuple(cmd.Flags)
		dValue = sliceToTuple(cmd.Value)
		dCmd := C.command(
			dCmd, dSubCmd, dJson, dOriginal, dStartLine, dEndLine, dFlags, dValue,
		)
		C.setCommandElement(slice,C.longlong(i),dCmd)
	}
	return slice 
}

//export all_commands
func all_commands() unsafe.Pointer {
	return C.return_success(sliceToTuple(dockerfile.AllCmds()))
}

//export parse_file
func parse_file(c_filename *C.char) unsafe.Pointer {
	filename := C.GoString(c_filename)
	cmds, err := dockerfile.ParseFile(filename)
	if err != nil {
		return C.raise(C.CString(err.Error()))
	}
	return C.return_success(convert_commands(cmds))
}

//export parse_string
func parse_string(c_string *C.char) unsafe.Pointer {
	s := C.GoString(c_string)
	cmds, err := dockerfile.ParseReader(bytes.NewBufferString(s))
	if err != nil {
		return C.raise(C.CString(err.Error()))
	}
	return C.return_success(convert_commands(cmds))
}

func main() {}
