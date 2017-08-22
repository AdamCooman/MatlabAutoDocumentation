GenerateDocumentation
~~~~~~~~~~~~~~~~~~~~~

Matlab code that can parse functions and classes to generate its documentation automatically. It works best when the function uses an inputParser, as it extracts most of the required information out of that inputParser.

The main function to update the help of a file is the generateHelp function:

::
	generateHelp('mycode.m')
	
will update the help in mycode.m when it contains the following line of code somewhere in the file:

::
	% @generateHelp

depending on whether mycode.m is a function or a class, generateHelp will act slightly differently.
	
Generating help for functions
=============================






Generating help for Classes
===========================

The built-in documentation generator for classes in Matlab is already quite good.
Normally, the only help which is required is the help for the constructor.

When the generateHelp function encounters a class, it will 


Examples
========

Example for functionHelp
------------------------

Consider the following function:

::
	function out = testFunction(varargin)
	p=inputParser();
	% help text for the required input
	p.addRequired('reqinput',@isvector);
	% help text for the optional input
	p.addOptional('optinput',5,@isscalar);
	% help text for the parameter
	p.addParameter('param','default',@ischar);
	p.parse(varargin)
	args = p.result;
	out = args.reqinput;
	end
	% @generateHelp
	% @TagLine Demo function for generateHelp
	% @Description Longer description about what the function does
	% @Description The description can be more than one line
	% @Example We can also add an example on how to use the code
	% @Outputs{1}.Description this is the description for output 1
	% @Outputs{1}.Type double
	% @SeeAlso generateHelp
	% @SeeAlso inputParser

when we call the generateHelp function for this function, the following help text is placed after the function call:

::
	% TESTFUNCTION Demo function for generateHelp
	%
	%    out =  TESTFUNCTION(reqinput)
	%    out =  TESTFUNCTION(reqinput,optinput)
	%    out =  TESTFUNCTION(reqinput,optinput,'ParamName',ParamValue)
	%
	% Longer description about what the function does
	% The description can be more than one line
	%
	% Required Inputs:
	%   reqinput  Default:  CheckFunction: @isvector
	%     help text for the required input
	% Optional Inputs:
	%   optinput  Default: 5 CheckFunction: @isscalar
	%     help text for the optional input
	% Parameter-Value pairs:
	%   param  Default: 'default' CheckFunction: @ischar
	%     help text for the parameter
	% 
	% Outputs: 
	%   out Type: double
	%     this is the description for output 1
	%
	% We can also add an example on how to use the code
	% See Also: GENERATEHELP, INPUTPARSER	
