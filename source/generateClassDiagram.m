function generateClassDiagram(varargin)
% GENERATECLASSDIAGRAM This function creates a pdf file with the class diagram of all classes in a specified folder
%
%     GENERATECLASSDIAGRAM('ParamName',ParamValue,...)
%
% The function first uses matlab builtin metaclass functionality to parse all the classes in the specified folder. 
% We then convert that information into a class diagram for yUML.me
% We then send that class diagram to yUML and download the resulting pdf file.
% You will need internet access for this function to work.
%
% Parameter-Value pairs:
%   CodeFolder  Default: [] CheckFunction: @ischar
%     folder with the matlab code. The function will look for class definitions in the specified folder and its subfolders.
%     It will then generate the class diagram for each of the classes.
%   OutputFileName  Default: [] CheckFunction: @ischar
%     Name of the resulting class diagram file.
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
p=inputParser();
% folder with the matlab code. The function will look for class definitions in the specified folder and its subfolders.
% It will then generate the class diagram for each of the classes.
p.addParameter('CodeFolder',[],@ischar);
% Name of the resulting class diagram file. 
p.addParameter('OutputFileName',[],@ischar);
p.parse(varargin{:});
args = p.Results;
if isempty(args.CodeFolder)
	error('You have to specify the CodeFolder parameter')
end
if isempty(args.OutputFileName)
	args.OutputFileName = [args.CodeFolder 'classDiagram'];
else
	% remove the extension from the specified filename
	[path,name] = fileparts(args.OutputFileName);
	args.OutputFileName = fullfile(path,name);
end
% get all the class names from the folder
classNames = getAllClassesInFolder(args.CodeFolder);
% make sure the folder is on the matlab path
addpath(genpath(args.CodeFolder));
% get the metaclass info for each of the classes
for cc=1:length(classNames)
    classInfo{cc} = meta.class.fromName(classNames{cc});
end
link = generateUMLdiagram(classInfo);
writeUMLfile(args.OutputFileName,link);
end
% @generateHelp
% @Tagline This function creates a pdf file with the class diagram of all classes in a specified folder
% @Description The function first uses matlab builtin metaclass functionality to parse all the classes in the specified folder. 
% @Description We then convert that information into a class diagram for yUML.me
% @Description We then send that class diagram to yUML and download the resulting pdf file.
% @Description You will need internet access for this function to work.
%% Functions
function res = generateUMLdiagram(classes)
    % define all class boxes
    B = cellfun(@generateUMLbox,classes,'UniformOutput',false);
    % define all inheritance boxes
    I = cellfun(@generateInheritanceBox,classes,'UniformOutput',false);
    res = strjoin([B(:);I(:)],'');
end
function res = generateInheritanceBox(mc)
    superclasses = {mc.SuperclassList.Name};
    res = '';
    for ss=1:length(superclasses)
        res = [res sprintf('[%s]-^[%s],',mc.Name,superclasses{ss})];
    end
end
function res = generateUMLbox(mc)
    %[Band|CenterFrequency;Bandwidth;margin|FMin;FMax|isInBand();alternateBand();adjacentBand()|disp();plot()],
    name = mc.Name;
    res = sprintf('[%s',name);
    T= generateUMLPublicPropertyList(mc);
    if ~isempty(T)
        res = [res sprintf('|Public Properties:|%s',T)];
    end
    T= generateUMLDependentPropertyList(mc);
    if ~isempty(T)
        res = [res sprintf('|Dependent Properties:|%s',T)];
    end
    T= generateUMLProtectedPropertyList(mc);
    if ~isempty(T)
        res = [res sprintf('|Protected Properties:|%s',T)];
    end
    T = generateUMLPublicMethodList(mc);
    if ~isempty(T)
        res = [res sprintf('|Public Methods:|%s',T)];
    end
    T= generateUMLProtectedMethodList(mc);
    if ~isempty(T)
        res = [res sprintf('|Protected Methods:|%s',T)];
    end
    res = [res '],'];
end
function res = generateUMLDependentPropertyList(mc)
    props = {};
    for pp=1:length(mc.PropertyList)
        if strcmp(mc.PropertyList(pp).DefiningClass.Name,mc.Name)
            if mc.PropertyList(pp).Dependent
                props{end+1}=mc.PropertyList(pp).Name;
            end
        end
    end
    res = strjoin(props,';');
end
function res = generateUMLPublicPropertyList(mc)
    props = {};
    for pp=1:length(mc.PropertyList)
        if strcmp(mc.PropertyList(pp).DefiningClass.Name,mc.Name)
            if strcmp(mc.PropertyList(pp).GetAccess,'public')&&(~mc.PropertyList(pp).Dependent)
                props{end+1}=mc.PropertyList(pp).Name;
            end
        end
    end
    res = strjoin(props,';');
end
function res = generateUMLProtectedPropertyList(mc)
    props = {};
    for pp=1:length(mc.PropertyList)
        if strcmp(mc.PropertyList(pp).DefiningClass.Name,mc.Name)
            if strcmp(mc.PropertyList(pp).GetAccess,'private')&&(~mc.PropertyList(pp).Dependent)
                props{end+1}=mc.PropertyList(pp).Name;
            end
        end
    end
    res = strjoin(props,';');
end
function res = generateUMLPublicMethodList(mc)
    meths = {};
    for pp=1:length(mc.MethodList)
        if strcmp(mc.MethodList(pp).DefiningClass.Name,mc.Name)
            if strcmp(mc.MethodList(pp).Access,'public')
                meths{end+1}=displaymethod(mc.MethodList(pp));
            end
        end
    end
    res = strjoin(meths,';');
end
function res = generateUMLProtectedMethodList(mc)
    meths = {};
    for pp=1:length(mc.MethodList)
        if strcmp(mc.MethodList(pp).DefiningClass.Name,mc.Name)
            if strcmp(mc.MethodList(pp).Access,'protected')
                meths{end+1}=displaymethod(mc.MethodList(pp));
            end
        end
    end
    res = strjoin(meths,';');
end
function res=displaymethod(m)
if m.Abstract
    res = sprintf('%s%s%s','+',m.Name,'+');
else
    res = m.Name;
end
end
function classes = getAllClassesInFolder(folder)
D = dir(folder);
% ignore '.' and '..'
D = D(3:end);
classes = {};
for dd=1:length(D)
    if D(dd).isdir   % if it's a folder, recurse into the folder
        classes = [classes getAllClassesInFolder(fullfile(folder,D(dd).name))];
    else
        [path,name,ext]=fileparts(D(dd).name);
        if strcmp(ext,'.m')
            if checkIfClass(fullfile(folder,[name ext]))
                classes{end+1} = name;
            end
        end
    end
end
end
function tf = checkIfClass(file)
    fid = fopen(file);
    filecontents = fread(fid,Inf,'*char').';
    fclose(fid);
    tf = contains(filecontents,'classdef ');
end
function writeUMLfile(filename,UMLlink)
% data={'<head><script>',...
% sprintf('UMLdiagram = "%s";',UMLlink),...
% 'querydata = {method: "POST", mode: "cors",cache: "no-cache",credentials: "same-origin",',...
% 'headers: {"Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",},',...
% 'redirect: "follow",referrer: "no-referrer",body: "dsl_text=" + encodeURI(UMLdiagram) + "name=",}',...
% 'fetch("https://yuml.me/diagram/nofunky/class/", querydata)',...
% '	.then(response => response.text())',...
% '	.then(data => document.getElementById("im").src="http://yuml.me/diagram/class/"+data)',...
% '</script></head><body><img id="im" src=""></img></body>'};
% fid = fopen(filename,'w');
% for ll=1:length(data)
%     fprintf(fid,'%s\r\n',data{ll});
% end
% fclose(fid);
Head = matlab.net.http.HeaderField('Content-Type','application/x-www-form-urlencoded');
Body = matlab.net.http.MessageBody();
Body.Data = ['dsl_text=' urlencode(UMLlink)];
obj = matlab.net.http.RequestMessage('POST',Head,Body);
url = 'https://yuml.me/diagram/nofunky/class/';
[response,~,~] = send(obj,url);
[~,name] = fileparts(response.Body.Data);
url = 'https://yuml.me/';
ext = '.pdf';
websave([filename ext],strjoin([url name ext],''));
end