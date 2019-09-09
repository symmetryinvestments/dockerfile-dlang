module app;
import support; // dockerfile_parser;


void main(string[] args)
{
	import std.stdio;
	import std.file : readText;
	import std.conv : to;
	writeln(allCommands());
	auto buf = readText(args[1]);
	writeln(buf);
	auto commands = parseFile(args[1]).dup; // parseString(buf);
	foreach(command; commands)
		writeln(command.to!string);
}


