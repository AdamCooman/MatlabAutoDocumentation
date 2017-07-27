function generateFunctionHelp(funcName)
% generateFunctionHelp generates the help of a function based on the inputParser used in that function
%
%   generateFunctionHelp(funcName)
%
% This function uses the function statement at the beginning of the file and
% the statements arount the input parser. Besides that, the programmer can
% add several tags that contain extra info.
% 
% inputParser info
%
%   Just add the documentation about the inputs above each inputParser
%   statement. The comments there will be used to generate the documentation.
%
% possible tags:
%
%   @tagline      short description of what the function does, used for the H1 line 
%   @description  long description of what the function does, placed afther the function call 
%   @extra        extra info, added to the end of the help, before the author and version info
%   @example      some example code to show how the function works
%   @author       author name(s)
%   @institution  institution at which the code was written
%   @version      different versions of the function
%   @outputX      description of output X
%   @outputTypeX  type of output number X
%
% The generated help will look as follows:
%
%       functionName @tagline
%         possible ways to call the function
%       @description
%         info about the inputs of the function
%         info about the outputs of the function
%       @example
%       @extra
%       @author, @institution
%       @version
%

%% extract the necessary information of the function out of the code
% save the current working directory
currDir = cd;

% find out where the function is saved and move to that location
[loc,~,~] = fileparts(which(funcName));
cd(loc);

% load the fuction content into a cell array of strings
file = readTextFile(funcName);

% look for different tags in the file
tags = lookForTags(file);

% check for the presence of the generateFunctionHelp tag. if it is not present, the file should not be parsed
if ~isfield(tags,'generateFunctionHelp')
    warning(['did not find the @generateFunctionHelp tag in the function: ' funcName '. Skipping it.']);
    return
end

% find the function statement in the file
funcStatement = lookForFunctionStatement(file);

% get the function name out of the statement
tags.name = parseForFunctionName(funcStatement);

% parse the function statement to look for the number of outputs and their name
outputs = parseForOutputs(funcStatement,tags);

% look for the input parser and the way it parses the inputs
inputs = parseInputParser(file);

% build the help of the function using this information
helptxt = createNewHelp(tags,inputs,outputs);

% replace the original help of the function
file = replaceHelp(file,helptxt);

% overwrite the original file
writeTextFile(file,funcName);

% move back to the original folder
cd(currDir);

end

%% lookForFunctionStatement
function res = lookForFunctionStatement()
% Get more info out of the actual function definition
notfound=true;kk=1;
while notfound
    notfound = isempty(regexp(strtrim(file{kk}),'^function\s+','once'));
    kk=kk+1;
end
kk=kk-1;
res = file{kk};
end
%% parseForFunctionName
function res = parseForFunctionName(functionStatement)
% parses the function statement to extract the name of the function
temp = regexp(functionStatement,'\s*=\s*(?<name>[a-zA-Z0-9_]+)','names');
if ~isempty(temp)
    res = temp.name;
else 
    error('function name could not be extracted from the function statement')
end
end
%% lookForOutputs
% TODO: this cannot deal with varargout for the moment
function res = parseForOutputs(functionStatement,tags)
% parses the function statement to extract the names and amount of output arguments
temp = regexp(functionStatement,'^\s*function\s+(?<output>\[?[a-zA-Z0-9_,\s]*\]?)\s*=\s*','names');
% get rid of the spaces
temp.output = temp.output(~isspace(temp.output));
% get rid of the brackets
temp.output = temp.output(~((temp.output=='[')|(temp.output==']')));
% split at the commas 
res.outputs = strsplit(temp.output,',');
numOut = length(res.outputs);
% parse the info about the output tag a little. you can add a number to
% indicate which one it is. If there's only one output, the tag can be
% called 'ouput'
if isfield(tags,'output')
    % there's only one output, just add that one
    res.outputDesc = {strjoin(res.output)}; 
    res = rmfield(res,'output');
else
    % go look for tags of the form outputX
    tags = fieldnames(res);
    temp = regexp(tags.','^output(?<num>[1-9][0-9]*)','names');
    nums=[];
    for ii=1:length(temp)
        if ~isempty(temp{ii})
            nums(end+1) = str2double(temp{ii}.num);
        end
    end
    res.outputDesc = cell(numOut,1);
    for ii=nums
        res.outputDesc{ii}=strjoin(res.(['output' num2str(ii)]));
        res = rmfield(res,['output' num2str(ii)]);
    end
end
% do the same with the outputType
if isfield(res,'outputType')
    % there's only one outputType, just add that one
    res.outputType = {strjoin(res.output)}; 
    res = rmfield(res,'outputType');
else
    % go look for tags of the form outputTypeX
    tags = fieldnames(res);
    temp = regexp(tags.','^outputType(?<num>[1-9][0-9]*)','names');
    nums=[];
    for ii=1:length(temp)
        if ~isempty(temp{ii})
            nums(end+1) = str2double(temp{ii}.num);
        end
    end
    res.outputType = cell(numOut,1);
    for ii=nums
        res.outputType{ii}=strjoin(res.(['outputType' num2str(ii)]));
        res = rmfield(res,['outputType' num2str(ii)]);
    end
end
% check whether every output has a description
if any(cellfun(@isempty,res.outputDesc))
    warning('some of the outputs seem to have no explanation');
end
if any(cellfun(@isempty,res.outputType))
    warning('some of the outputs seem to have no type');
end
end
%% replaceHelp
function file = replaceHelp(file,newhelp)
% REPLACEHELP extracts the help from a file and replaces it by the new help

% look for the old help. start by finding the function call
notfound=true;kk=1;
while notfound
    notfound = isempty(regexp(strtrim(file{kk}),'^function','once'));
    kk=kk+1;
end
helpstart = kk;
% find the end of the help by checking for comments
notfound=true;
while notfound
    temp = strtrim(file{kk});
    if isempty(temp)
        notfound=false;
    else
        notfound =  strcmp(temp(1),'%');
    end
    kk=kk+1;
end
% now place the new help behind the function call
file = [file(1:helpstart-1);newhelp(1:end).';file(helpstart:end)];
end

