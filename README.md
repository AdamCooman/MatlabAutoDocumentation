# GenerateDocumentation

Matlab code that can parse functions and classes to generate its documentation automatically. It works best when the function uses an inputParser, as it extracts most of the required information out of that inputParser.

The main function to update the help of a file is the generateHelp function:

```matlab
	generateHelp('mycode.m')
```
	
will update the help in mycode.m when it contains the following line of code somewhere in the file:

```matlab
	% @generateHelp
```

depending on whether mycode.m is a function or a class, generateHelp will act slightly differently.
	
## Generating help for functions

when generating help for a function, the following steps are performed:

1. The function statement is parsed to extract the name of the function and its outputs
2. The input parser in the function is parsed to extract the information about its inputs
3. The function looks for tags of the shape `@xxx` in the comments of the function to assign extra fields to the help
4. The functionHelp is generated according to its `Format` field
5. The old help in the code is replaced by the new help

### Parsing the inputParser

**TODO:** Explain how the information is extracted from the inputParser code

### Extracting the tags

Supported tags are:

`@Description`, `@Tagline`, `@Example`, `@SeeAlso`

**TODO:** Explain how the `@Output{1}.Description` works

### Generating new help from the Format field

Once all info is extracted from the function, the new help is generated. The lay-out of this new help is determined by the `Format` field in the functionHelp class.

The `Format` field contains a cell array of strings in which the elements of the functionHelp object can be printed

The default Formatting is the following:

```matlab
DefaultFormat = {...
'% #Name# #Tagline#';...
'%';...
'%    #CallTypes#';...
'%';...
'% #Description#';...
'%';...
'% #InputDescription#';...
'% ';
'% #OutputDescription#';...
'%';...
'% #Example#';...
'% #SeeAlsoList#'};
```


## Generating help for Classes

The built-in documentation generator for classes in Matlab is already quite good.
Normally, the only help which is required is the help for the constructor.

**TODO:** Explain that only limited tags are allowed in classHelp
**TODO:** Explain that the constructor is pulled out and that it is considered as a function. As a consequence, its tags need to be inside of the constructor code
**TODO:** Explain that only the constructor is done like that. When other functions in a class need to use the generateHelp, they should be placed in the class folder instead of in the main class code.

## Examples


### Example for functionHelp


Consider the following function:

```matlab
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
% @Tagline Demo function for generateHelp
% @Description Longer description about what the function does
% @Description The description can be more than one line
% @Example We can also add an example on how to use the code
% @Outputs{1}.Description this is the description for output 1
% @Outputs{1}.Type double
% @SeeAlso generateHelp
% @SeeAlso inputParser
```

when we call the generateHelp function for this function, the following help text is placed after the function call:

```matlab
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
```
	
### Example for classHelp

**TODO:** Add this example