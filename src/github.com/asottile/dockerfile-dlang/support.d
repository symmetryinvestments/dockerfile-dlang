module support; // dockerfile_parser;

struct Result(T)
{
	string errorMessage;
	T* result;
}

struct Command
{
    string command;
    string subCommand;
    bool json;
    string original;
    int startLine;
    int endLine;
    string[] flags;
    string[] values;
}

export extern(C)
void* return_success(void* ret)
{
	auto result = new Result!(void*)(null,cast(void**)ret);
	return cast(void*) result;
}

export extern(C)
void* raise(const(char)* errorMessage)
{
	import std.string : toStringz, fromStringz;
	import core.stdc.stdlib : free;
	bool shouldFree = true;
	auto niceErrorMessage = (errorMessage is null) ? "UNKNOWN GOLANG ERROR" : errorMessage.fromStringz.idup;
	auto result = new Result!(void*)(niceErrorMessage);
	if (errorMessage !is null)
		free(cast(void*)errorMessage);
	return cast(void*) result;
}

export extern(C)
void* command(char* cmd, char* sub_cmd, int json, char* original, int start_line, int end_line, void* flags, void* value)
{
	import std.string : fromStringz;
	import core.stdc.stdlib : free;

	auto ret = new Command;
	ret.command = cmd.fromStringz.idup;
	ret.subCommand = sub_cmd.fromStringz.idup;
	ret.json = (json != 0);
	ret.original = original.fromStringz.idup;
	ret.startLine = start_line;
	ret.endLine = end_line;
	auto flagsV = cast(StringSlice*) flags;
	ret.flags = (*flagsV).values;
	auto valuesV = cast(StringSlice*) value;
	ret.values = (*valuesV).values;
	free(cmd);
	free(sub_cmd);
	free(original);
	return cast(void*) new Result!Command(null,ret);
}

extern(C) void* parse_string(const(char)* s);
extern(C) void* parse_file(const(char)* filename);
extern(C) void* all_commands();

alias CommandResult = Result!Command;
alias CommandSlice = Slice!Command;
alias CommandSliceResult = Result!(Slice!Command);
alias StringSlice = Slice!string;
alias StringSliceResult = Result!(Slice!string);

Command[] parseString(string s)
{
	import std.string : toStringz, fromStringz;
	import std.exception : enforce;
	auto p = cast(CommandSliceResult*) parse_string(s.toStringz);
	enforce(p !is null, "parse_string failed");
	enforce(p.errorMessage.length ==0, p.errorMessage);
	auto result = *p.result;
	return result.values;
}

Command[] parseFile(string filename)
{
	import std.string : toStringz, fromStringz;
	import std.exception : enforce;
	auto p = cast(CommandSliceResult*) parse_file(filename.toStringz);
	enforce(p !is null, "parse_file failed");
	enforce(p.errorMessage.length ==0, p.errorMessage);
	auto result = *p.result;
	return result.values;
}

string[] allCommands()
{
	import std.string : fromStringz;
	import std.exception : enforce;
	auto p = cast(StringSliceResult*) all_commands();
	enforce(p !is null, "all_commands failed");
	enforce(p.errorMessage.length ==0, p.errorMessage);
	auto result = *p.result;
	return result.values;
}


struct Slice(T)
{
	T[] values;
}

export extern(C)
void* stringSlice(size_t length)
{
	auto ret = new Slice!string;
	ret.values.length = length;
	return cast(void*) ret;
}

export extern(C)
void* commandSlice(size_t length)
{
	auto ret = new Slice!Command;
	ret.values.length = length;
	return cast(void*) ret;
}

export extern(C)
void setStringElement(void* sliceV, size_t i, char* s)
{
	import core.stdc.stdlib : free;
	import std.exception : enforce;
	import std.string : fromStringz;

	auto slice = cast(StringSlice*) sliceV;
	enforce(slice.values.length > i);
	slice.values[i] = fromStringz(s).idup;
	free(s);
}

export extern(C)
void setCommandElement(void* sliceV, size_t i, void* p)
{
	import std.exception : enforce;
	assert(p !is null, "setCommandElement called with null");
	auto slice = cast(CommandSlice*) sliceV;
	enforce(slice.values.length > i);
	auto pTyped = cast(CommandResult*) p;
	slice.values[i] = *pTyped.result;
}

