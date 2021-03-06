package me.aaronshea.silkscreen;

import flash.Vector;
import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.NativeProcessExitEvent;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;
import haxe.Log;

/**
 * @author Aaron M. Shea
 */
class FFMpegProcess
{

	private var process:NativeProcess;
	private var startupInfo:NativeProcessStartupInfo;
	
	public var stdIn:IDataOutput;
	
	public function new(width:Int, height:Int, rate:Int, saveFile:String) 
	{
		this.startupInfo = new NativeProcessStartupInfo();
		var ffmpeg = File.applicationDirectory.resolvePath("ffmpeg.exe");
		startupInfo.executable = ffmpeg;
		var processArgs = new Vector<String>();

		// Overrite existing files
		processArgs.push("-y");
		
		processArgs.push("-threads");
		processArgs.push("4");
		
		// Input format will be raw
		processArgs.push("-f");
		processArgs.push("rawvideo");
		
		// Using ARGB for input format
		processArgs.push("-pix_fmt");
		processArgs.push("argb");
		
		// Size should be what the user wants
		processArgs.push("-s");
		processArgs.push(width + "x" + height);
		
		// Framerate should match swf
		processArgs.push("-r");
		processArgs.push(Std.string(rate));
		
		// Read bytes from stdin
		processArgs.push("-i");
		processArgs.push("-");
		
		// No audio tracks
		processArgs.push("-an");
		
		// Output resolution
		processArgs.push("-aspect");
		processArgs.push(width + ":" + height);
		
		// Output codec is Quicktime Animation
		processArgs.push("-c:v");
		processArgs.push("qtrle");
		
		processArgs.push("-preset");
		processArgs.push("slow");
		
		processArgs.push("-strict");
		processArgs.push("-2");
		
		// Output file name
		processArgs.push(saveFile);
		
		startupInfo.arguments = processArgs;
		
		this.process = new NativeProcess();
		process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
		
		process.addEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, stdError);
		process.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, stdError);
		process.addEventListener(IOErrorEvent.IO_ERROR, stdError);
		
		process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, stdOutput);
		process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, stdOutputError);
	}
	
	public function onExit(evt:NativeProcessExitEvent)
	{
		Log.clear();
		trace("Done!");

		// TODO If this is anything other than zero, bad things
		trace("FFMpeg has exited with code " + evt.exitCode);
	}
	
	public function stdError(evt:IOErrorEvent)
	{
		// TODO some more error checking would be nice
		// trace("FFMpeg ERROR: " + evt.text);
	}
	
	public function stdOutput(evt:ProgressEvent)
	{
		// TODO Nicer log (to a file?)
		var msg = process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable);
		// trace(msg);
	}
	
	public function stdOutputError(evt:ProgressEvent)
	{
		// TODO some more error checking would be nice
		var msg = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
		trace(msg);
	}
	
	public function startProcess()
	{
		process.start(this.startupInfo);
		this.stdIn = process.standardInput;
	}
	
	public function closeProcess()
	{
		// Close off the input stream so FFMpeg can exit cleanly
		this.process.closeInput();
	}
	
}