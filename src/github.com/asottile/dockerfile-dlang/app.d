module app;
import support; // dockerfile_parser;


void main(string[] args)
{
	import std.stdio;
	import std.file : readText;
	writeln(allCommands());
	auto buf = readText(args[1]);
	writeln(buf);
	auto commands = parseString(buf);
	foreach(command; commands)
		writeln(command);
}


