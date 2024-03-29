function generateHelp( loc , varargin )
% GENERATEHELP generates documentation for a file and adds it to the file
%
%     GENERATEHELP(Location)
%     GENERATEHELP(Location,'ParamName',ParamValue,...)
%
% 
%
% Required Inputs:
%   Location  Default:  CheckFunction: @(x) 5
%     Folder to parse
% Parameter-Value pairs:
%   recursive  Default: false CheckFunction: @islogical
%     when recursive is set to true, all files in a folder and its sub-folder
%     are processed.
%   exclude  Default: {'.git'} CheckFunction: @iscellstr
%     cell array of strings which contains the folders of files that will be excluded
%     from the recursive search through the folder structure
% The input parser has the following properties:
%     KeepUnmatched = false: unmatched parameters will generate an error
%      StructExpand = false
%     CaseSensitive = false
%   PartialMatching = true
% 
% 
%
% 
% See Also: 
% 
if ischar(loc)
    loc = {loc};
elseif ~iscellstr(loc)
    error('The input should be string or a cell array of strings that points to a file or a folder');
end
p = inputParser();
% Folder to parse
p.addRequired('Location',@(x) 5);
% when recursive is set to true, all files in a folder and its sub-folder
% are processed.
p.addParameter('recursive',false,@islogical);
% cell array of strings which contains the folders of files that will be excluded
% from the recursive search through the folder structure
p.addParameter('exclude',{'\.git'},@iscellstr);
p.parse(loc,varargin{:});
args = p.Results;
% prepare the exclude string for the regexp later
excludeStr = ['^' strjoin(args.exclude,'$|^') '$'];
for ll=1:length(loc)
    % if the location is a file, process it. otherwise it is a folder
    if ~isdir(loc{ll})
        % get only the .m files
        [~,~,ext]=fileparts(loc{ll});
        if strcmpi(ext,'.m')
            generateHelpForFile(loc{ll});
        end
    else
        % when the location is a folder, get all the .m files in the folder and
        % apply the function to those .m files
        foldercontents = dir(loc{ll});
        % exclude the contents which we don't want.
        foldercontents = foldercontents(cellfun('isempty',regexp({foldercontents.name},['^\.$|^\.\.$|' excludeStr])));
        % save which of the content in the folder is a directory
        directories = [foldercontents.isdir];
        % and save the names of the content in the folder with the location placed before it
        foldercontents = cellfun(@(x) fullfile(loc{ll},x),{foldercontents.name},'uniformOutput',false);
        % call the function on the files in the directory
        % when the recursive option is enabled, call the function on sub-folders as well
        if args.recursive
            generateHelp(foldercontents              ,args);
        else
            generateHelp(foldercontents(~directories),args);
        end
    end
end
end
% @generateHelp
% @Tagline generates documentation for a file and adds it to the file
%% function to generate and add the help to an .m file
function generateHelpForFile(filename)
% read the code of the file
code = readTextFile(filename);
% look for the @generateHelp tag, when it's not present in the file, skip the file
if all(cellfun('isempty',regexp(code,'^\s*%\s+@generate(Function)?Help')))
    return
end
fprintf('Adding help to: %s\n',filename);
% get the code with the new help
try
    code = functionHelp.replaceHelp(code);
catch err
    fprintf(2,'Problem in file: %s\n',filename);
    rethrow(err);
end
% write the new code to the original file
writeTextFile(code,filename)
end
