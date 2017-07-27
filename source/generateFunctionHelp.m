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
% The old help present in the function is added to the bottom, as a backup

%% extract the necessary information of the function out of the code

% save the current working directory
currDir = cd;

% find out where the function is saved and move to that location
[loc,~,~] = fileparts(which(funcName));
cd(loc);

% load the fuction content into a cell array of strings
file = readTextFile(funcName);

% look for different tags in the 
tags = lookForTags(file);

% check for the presence of the generateFunctionHelp tag. if it is not present, the file should not be parsed
if ~isfield(tags,'generateFunctionHelp')
    warning(['did not find the @generateFunctionHelp tag in the function: ' funcName '. Skipping it.']);
    return
end

% look for the input parser and the way it parses the inputs
inputs = parseInputParser(file);


%% build the help of the function using this information

helptxt = {};
% the H1 line
helptxt{end+1} = [tags.name ' ' tags.tagline{1}];
helptxt{end+1} = '';
% the different ways to call the function
helptxt = [helptxt indent(5,generateCallInfo(tags,inputs))];
helptxt{end+1} = '';
% long description about what the function does
if isfield(tags,'description')
    helptxt = [helptxt cutIntoPieces(strjoin(tags.description),80)];
end
helptxt{end+1} = '';
% info about the inputs
helptxt = [helptxt generateInputDoc(inputs)];
helptxt{end+1} = '';
% info about the outputs
helptxt = [helptxt generateOutputDoc(tags)];
helptxt{end+1} = '';
% example code
if isfield(tags,'example')
%     helptxt{end+1} = 'Example:';
    for ii=1:length(tags.example)
        helptxt{end+1} = strjoin(indent(2,tags.example(ii)));
    end
    helptxt{end+1} = '';
end
% extra info
if isfield(tags,'extra')
    helptxt = [helptxt cutIntoPieces(strjoin(tags.extra),80)];
    helptxt{end+1} = '';
end
% see also info
if isfield(tags,'seealso')
    helptxt{end+1} = ['see also: ' strjoin(tags.seealso)];
    helptxt{end+1} = '';
end
% author info and institution info
if isfield(tags,'author')
    helptxt{end+1} = strjoin(tags.author);
    if isfield(tags,'institution')
        helptxt{end} = [helptxt{end} ', ' strjoin(tags.institution)];
    end
    helptxt{end+1} = '';
else
    if isfield(tags,'institution')
        helptxt{end} = strjoin(tags.institution);
        helptxt{end+1} = '';
    end
end
% version info
if isfield(tags,'version')
    helptxt{end+1} = 'Version info:';
    for ii=1:length(tags.version);helptxt{end+1} = [' ' tags.version{ii}];end
end


%% add the generated helptext to the file

% put the whole thing in comment
helptxt = comment(helptxt);
% replace the original help of the function
file = replaceHelp(file,helptxt);
% overwrite the original file
writeTextFile(file,funcName);

% move back to the original folder
cd(currDir);

end









%% lookForTags
function res = lookForTags(file)
% this function looks for the different tags in the file and returns the value
% associated to those tags in a struct that contains cell arrays with the value
detected = regexp(file,'^\s*\%\s*\@(?<tag>[a-zA-Z0-9]+)\s?(?<value>.*)','names');
detected = detected(cellfun(@(x) ~isempty(x),detected));
res = struct();
for ii=1:length(detected)
    if isfield(res,detected{ii}.tag)
        res.(detected{ii}.tag){end+1} = detected{ii}.value;
    else
        res.(detected{ii}.tag) = {detected{ii}.value};
    end
end
% Get more info out of the actual function definition
notfound=true;kk=1;
while notfound
    notfound = isempty(regexp(strtrim(file{kk}),'^function\s+','once'));
    kk=kk+1;
end
kk=kk-1;
% parse the function definition better
temp = regexp(file{kk},'^\s*function\s+(?<output>\[?[a-zA-Z0-9_,\s]*\]?)\s*=\s*(?<name>[a-zA-Z0-9_]+)','names');
res.name = temp.name;
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
if isfield(res,'output')
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


% chech whether every output has a description
if any(cellfun(@isempty,res.outputDesc))
    warning('some of the outputs seem to have no explanation');
end
if any(cellfun(@isempty,res.outputType))
    warning('some of the outputs seem to have no type');
end
end
%% parseInputParser
%% replaceHelp
function file = replaceHelp(file,newhelp)
% this function extracts the help from a file and replaces it by the new
% help passed to this function. The old help is moved to the bottom of the
% file

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
helpstop = kk-2;

% look for an old backup of the help and remove it
notfound=true;kk=length(file);% start looking from the back, that's faster
try
    while notfound
        notfound = isempty(regexp(strtrim(file{kk}),'^\%\%\sgenerateFunctionHelp\:','once'));
        kk=kk-1;
    end
    % just remove the backup
    file = file(1:kk);
end
% if you found help, move it to the end of the file
if helpstop>=helpstart
    file{end+1} = ['%% generateFunctionHelp: old help, backed up at ' date '. leave this at the end of the function'];
    file(end+1:end+1+(helpstop-helpstart)) = file(helpstart:helpstop);
    file(helpstart:helpstop) = [];
end
% now place the new help behind the function call
file = [file(1:helpstart-1);newhelp(1:end).';file(helpstart:end)];
end
%% generateInputDoc
function res = generateInputDoc(instruct)
% generates documentation about the inputs of the function that has been
% extracted from the inputParser statement
res = {};
% find the required inputs and show their info
bins = find(cellfun(@(x) strcmp(x,'required'),{instruct.mode}));
if ~isempty(bins)
    res{end+1} = 'Required inputs:';
    for ii=bins
        % add the parameter name and the check function called
        res{end+1} = ['- ' instruct(ii).paramName '      check: ' instruct(ii).check];
        % add the description
        res = [res indent(5,cutIntoPieces(instruct(ii).description,60))];
    end
end
% find the optional inputs and show their info
bins = find(cellfun(@(x) strcmp(x,'optional'),{instruct.mode}));
if ~isempty(bins)
    res{end+1} = '';
    res{end+1} = 'Optional inputs:';
    for ii=bins
        % add the parameter name and the check function called
        res{end+1} = ['- ' instruct(ii).paramName '     default: ' instruct(ii).default '  check: ' instruct(ii).check];
        % add the description
        res = [res indent(5,cutIntoPieces(instruct(ii).description,60))];
    end
end
% find the parameter/value pairs and show their info
bins = find(cellfun(@(x) strcmp(x,'paramvalue'),{instruct.mode}));
if ~isempty(bins)
    res{end+1} = '';
    res{end+1} = 'Parameter/Value pairs:';
    for ii=bins
        % add the parameter name and the check function called
        res{end+1} = ['- ''' instruct(ii).paramName '''     default: ' instruct(ii).default '  check: ' instruct(ii).check];
        % add the description
        res = [res indent(5,cutIntoPieces(instruct(ii).description,60))];
    end
end
end
%% generateCallInfo
function possibs = generateCallInfo(tags,inputs)
% get the possible input calls
possibs={};
call = '(';
% get the required parameters
bins = find(cellfun(@(x) strcmp(x,'required'),{inputs.mode}));
if ~isempty(bins)
    for ii=bins
        call = [call inputs(ii).paramName ','];
    end
    possibs{end+1} = [ call(1:end-1) ');'];
else
    possibs{end+1} = [ call ');'];
end
% get the optional parameters
bins = find(cellfun(@(x) strcmp(x,'optional'),{inputs.mode}));
if ~isempty(bins)
    for ii=bins
        call = [call inputs(ii).paramName ','];
    end
    possibs{end+1} = [call(1:end-1) ');'];
end
% check whether there are paramvalues present
if ~isempty(find(cellfun(@(x) strcmp(x,'paramvalue'),{inputs.mode}),1))
    possibs{end+1} = [ call '''ParamName'',paramValue,...);'];
end
% get the output call
if ~isempty(tags.outputs)
    if length(tags.outputs)==1
        out = [tags.outputs{1} ' = '];
    else
        out = '[';
        for ii=1:length(tags.outputs)
            out = [out tags.outputs{ii} ','];
        end
        out(end:end+3) = '] = ';
    end
else
    out='';
end
% add the output and function name to the possibilities
for ii=1:length(possibs)
    possibs{ii} = [out tags.name possibs{ii}];
end

end
%% generateOutputDoc
function res=generateOutputDoc(tags)
res={};
for ii=1:length(tags.outputs)
    if ii==1
        res{end+1}='Outputs:';
    end
    % add the parameter name and the check function called
    if ~isempty(tags.outputType{ii})
        res{end+1} = ['- ' tags.outputs{ii} '      Type: ' tags.outputType{ii} ];
    else
        res{end+1} = ['- ' tags.outputs{ii}];
    end
    % add the description
    if ~isempty(tags.outputDesc{ii})
        res = [res indent(5,cutIntoPieces(tags.outputDesc{ii},60))];
    end
end
end
%% Text utility functions
function res = cutIntoPieces(str,limit)
% this function splits a long string into several blocks which are just
% larger than the specified limit. It can only cut at the spaces

% split the string at the spaces
pieces = regexp(str,'\s','split');
% reconstruct into smaller sentences
res={};
kk = 0;
while kk<length(pieces)
    L=0;
    start=kk+1;
    while L<limit
        kk=kk+1;
        if kk<length(pieces)
            L = L+1+length(pieces{kk});
        else
            L=inf;
        end
    end
    stop = kk;
    res{end+1} = strjoin(strtrim(pieces(start:stop)));
end
end

function res = indent(num,res)
    for ii=1:length(res)
        res{ii} = [repmat(' ',1,num) res{ii}];
    end
end

function res = comment(res)
    for ii=1:length(res)
        res{ii} = ['% ' res{ii}];
    end
end