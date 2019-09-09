module support; // dockerfile_parser;
import std.traits: ReturnType;
import std.experimental.allocator : make, makeArray;
import std.experimental.allocator.building_blocks.region: Region;
import std.experimental.allocator.building_blocks.allocator_list: AllocatorList;
import std.experimental.allocator.gc_allocator : GCAllocator;
import std.experimental.allocator.mallocator : Mallocator;
import std.experimental.allocator.showcase : mmapRegionList;
import std.experimental.allocator.typed: TypedAllocator, AllocFlag;
import std.experimental.allocator.building_blocks.scoped_allocator : ScopedAllocator;
import std.algorithm : max;
//@nogc:

//ScopedAllocator!Mallocator regionalAllocator;
alias MyTypedAllocator = AllocatorList!((size_t n) => Region!Mallocator(max(n,1024*1024)));

// MyTypedAllocator regionalAllocator = MyTypedAllocator();
Region!Mallocator regionalAllocator;

shared static this()
{
	regionalAllocator = Region!Mallocator(1024*1024*40); // Mallocator(1024*1024*100);
}

struct Result(T)
{
	const(char)[] errorMessage;
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
/+
	string toString()
	{
		import std.conv;
		return this.to!string;
	}
+/
	Command deepCopy()
	{
		import std.algorithm : map;
		import std.array : array;
		Command ret;
		ret.command = this.command.idup;
		ret.subCommand = this.subCommand.idup;
		ret.json =  this.json;
		ret.original = this.original.idup;
		ret.startLine = this.startLine;
		ret.endLine = this.endLine;
		ret.flags = this.flags.map!(flag => flag.idup).array;
		ret.values = this.values.map!(value => value.idup).array;
		return ret;
	}

}
/+
auto makeRegionalAllocator()
{
	//alias RawAllocator = Region!MmapAllocator(1024);
	//regionalTypedAllocator!RawAllocator regionalAllocator;
}
+/
export extern(C)
void* return_success(void* ret)
{
	import std.experimental.allocator: make;
	auto result = regionalAllocator.make!(Result!(char))(null,cast(char*)ret);
	return cast(void*) result;
}

T[] allocatorDup(T)(T[] values)
{
	import std.traits: Unqual;
	auto ret = regionalAllocator.makeArray!(Unqual!T)(values.length);
	ret[0..values.length] = cast(Unqual!T[]) values;
	return ret;
}

immutable(T)[] allocatorIdup(T)(T[] values)
{
	import std.traits : Unqual;
	auto ret = regionalAllocator.makeArray!(Unqual!T)(values.length);
	ret[0..values.length] = values;
	return cast(immutable(T)[]) ret;
}

const(char)* toStringz(const(char)[] s)
{
	import std.traits: Unqual;
	if (s.length == 0)
		return null;
	bool needsTerminator = (s.length == 0 || (s[$-1]!='\0'));
	auto requiredLength = s.length + (needsTerminator ? 1 : 0);
	auto p = regionalAllocator.makeArray!char(requiredLength);
	assert(p.length == requiredLength);
	p[0 .. s.length] = s[0.. $];
	if(needsTerminator)
		p[s.length] = '\0';
	return cast(const(char)*) p.ptr;
}

string fromStringz(const(char)* p)
{
	if (p is null)
		return null;
	size_t maxLen = 16384;
	auto s= regionalAllocator.makeArray!char(maxLen);
	assert(s.length == maxLen);
	size_t i = 0;
	while(p[i] != '\0')
	{
		s[i] = p[i];
		++i;
		if (i == maxLen)
		{
			maxLen *= 2;
			auto s2 = regionalAllocator.makeArray!char(maxLen);
			assert(s2.length == maxLen);
			s2[0..s.length] = s[];
			regionalAllocator.deallocate(s);
			s=s2;
		}
	}
	s = s[0..i];
	return cast(string) s;
}


export extern(C)
void* raise(const(char)* errorMessage)
{
	import std.experimental.allocator: make;
	import core.stdc.stdlib : free;
	bool shouldFree = true;
	auto niceErrorMessage = (errorMessage is null) ? "UNKNOWN GOLANG ERROR" : errorMessage.fromStringz;
	auto result = regionalAllocator.make!(Result!(char));
	result.errorMessage = niceErrorMessage;
	if (errorMessage !is null)
		free(cast(void*)errorMessage);
	return cast(void*) result;
}


export extern(C)
void* command(char* cmd, char* sub_cmd, int json, char* original, int start_line, int end_line, void* flags, void* value)
{
	import core.stdc.stdlib : free;
	import std.experimental.allocator: make;

	auto ret = regionalAllocator.make!Command;
	ret.command = cmd.fromStringz.allocatorIdup;
	ret.subCommand = sub_cmd.fromStringz.allocatorIdup;
	ret.json = (json != 0);
	ret.original = original.fromStringz.allocatorIdup;
	ret.startLine = start_line;
	ret.endLine = end_line;
	auto flagsV = cast(StringSlice*) flags;
	ret.flags = (*flagsV).values.allocatorDup;
	auto valuesV = cast(StringSlice*) value;
	ret.values = (*valuesV).values.allocatorDup;
	free(cmd);
	free(sub_cmd);
	free(original);
	return cast(void*) regionalAllocator.make!(Result!Command)(null,ret);
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
	import std.algorithm : map;
	import std.array : array;
	import std.exception : enforce;
	scope(exit)
	{
		regionalAllocator.deallocateAll();
	}
	auto p = cast(CommandSliceResult*) parse_string(s.toStringz);
	enforce(p !is null, "parse_string failed");
	enforce(p.errorMessage.length ==0, p.errorMessage);
	auto result = *((*p).result);
	return result.values.map!(command => command.deepCopy).array;
}

Command[] parseFile(string filename)
{
	import std.algorithm : map;
	import std.array : array;
	import std.exception : enforce;
	scope(exit)
	{
		regionalAllocator.deallocateAll();
	}
	auto p = cast(CommandSliceResult*) parse_file(filename.toStringz);
	enforce(p !is null, "parse_file failed");
	enforce(p.errorMessage.length ==0, p.errorMessage);
	auto result = *((*p).result);
	return result.values.map!(command => command.deepCopy).array;
}

string[] allCommands()
{
	import std.algorithm : map;
	import std.array : array;
	import std.exception : enforce;
	//regionalAllocator = TypedAllocator!(ScopedAllocator!(Mallocator))(Mallocator.instance);
	scope(exit)
	{
		regionalAllocator.deallocateAll();
	}
	auto p = cast(StringSliceResult*) all_commands();
	enforce(p !is null, "all_commands failed");
	enforce(p.errorMessage.length ==0, p.errorMessage);
	auto result = *p.result;
	return result.values.map!(value => value.idup).array;
}


struct Slice(T)
{
	T[] values;
}

export extern(C)
void* stringSlice(size_t length)
{
	import std.experimental.allocator : make;
	assert(length >= 0);
	auto ret = regionalAllocator.make!(Slice!string);
	assert(ret !is null);
	auto buf = regionalAllocator.makeArray!string(length,"");
	assert(buf.length == length);
	ret.values = buf;
	assert(ret.values.length == length);
	return cast(void*) ret;
}

export extern(C)
void* commandSlice(size_t length)
{
	import std.experimental.allocator : make;
	auto ret = regionalAllocator.make!(Slice!Command);
	assert(ret !is null);
	ret.values = regionalAllocator.makeArray!Command(length,Command.init);
	return cast(void*) ret;
}

export extern(C)
void setStringElement(void* sliceV, size_t i, const(char)* s)
{
	import core.stdc.stdlib : free;
	import std.exception : enforce;

	assert(s !is null);
	auto slice = cast(StringSlice*) sliceV;
	assert(slice !is null);
	assert(i >=0);
	assert(slice.values.length > i);
	slice.values[i] = fromStringz(s);
	free(cast(void*)s);
}

export extern(C)
void setCommandElement(void* sliceV, size_t i, void* p)
{
	import std.exception : enforce;
	assert(p !is null, "setCommandElement called with null");
	auto slice = cast(CommandSlice*) sliceV;
	enforce(slice.values.length > i);
	auto pTyped = *cast(CommandResult*) p;
	slice.values[i] = *pTyped.result;
}

