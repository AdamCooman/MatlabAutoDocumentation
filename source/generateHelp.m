function helptxt = generateHelp( tags , inputs , outputs)
%GENERATEHELP generates the help of a function starting from its tags


helptxt = {};
% the H1 line
helptxt{end+1} = [upper(tags.name) ' ' tags.tagline{1}];
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

% put the whole thing in comment
helptxt = comment(helptxt);

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
        res = [res indent(5,cutIntoPieces(instruct(ii).description,60))]; %#ok<*AGROW>
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
    possibs{ii} = [out upper(tags.name) possibs{ii}];
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

