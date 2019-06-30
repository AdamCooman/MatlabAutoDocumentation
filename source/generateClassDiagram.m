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
for cc=length(classNames):-1:1
    classInfo{cc} = meta.class.fromName(classNames{cc});
end
% remove empty results from the list
classInfo = classInfo(~cellfun('isempty',classInfo));
% create the UML diagram
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
I = cellfun(@generateIsaBox,classes,'UniformOutput',false);
% define all hasa boxes
H = cellfun(@generateHasaBox,classes,'UniformOutput',false);
res = strjoin(cat(2,cat(2,B{:}),cat(2,I{:}),cat(2,H{:})));
end
function res = generateIsaBox(mc)
superclasses = {mc.SuperclassList.Name};
res = repmat("",1,length(superclasses));
for ss=1:length(superclasses)
    res(ss) = sprintf('[%s]-^[%s],',mc.Name,superclasses{ss});
end
end
function res = generateUMLbox(mc)
%[Band|CenterFrequency;Bandwidth;margin|FMin;FMax|isInBand();alternateBand();adjacentBand()|disp();plot()],
name = mc.Name;
res = sprintf("[%s",name);
T= generateUMLPublicPropertyList(mc);
if T~=""
    res = strcat(res,sprintf("|Public Properties:|%s",T));
end
T= generateUMLDependentPropertyList(mc);
if T~=""
    res = strcat(res,sprintf("|Dependent Properties:|%s",T));
end
T= generateUMLProtectedPropertyList(mc);
if T~=""
    res = strcat(res,sprintf("|Protected Properties:|%s",T));
end
T = generateUMLPublicMethodList(mc);
if T~=""
    res = strcat(res,sprintf("|Public Methods:|%s",T));
end
T= generateUMLProtectedMethodList(mc);
if T~=""
    res = strcat(res,sprintf("|Protected Methods:|%s",T));
end
res = strcat(res,"],");
end
function res = generateHasaBox(mc)
props = mc.PropertyList;
if ~isempty(props)
    DefiningClass = [props.DefiningClass];
    props = props(string({DefiningClass.Name}) == mc.Name);
    res = repmat("",1,length(props));
    for pp=1:length(props)
        if ~isempty(props(pp).Validation)
            if ~isempty(props(pp).Validation.Class)
                if ~ismember(props(pp).Validation.Class.Name,["double" "string" "cell" "struct" "logical"])
                    res(pp) = sprintf('[%s]- %s >[%s],',mc.Name,props(pp).Name,props(pp).Validation.Class.Name);
                end
            end
        end
    end
    res = res(res~="");
else
    res = "";
end
end
function res = generateUMLDependentPropertyList(mc)
props = mc.PropertyList;
if ~isempty(props)
    DefiningClass = [props.DefiningClass];
    props = props(string({DefiningClass.Name}) == mc.Name);
    props = props([props.Dependent]);
    res = generatePropertyList(props);
else
    res = "";
end
end
function res = generateUMLPublicPropertyList(mc)
props = mc.PropertyList;
if ~isempty(props)
    DefiningClass = [props.DefiningClass];
    props = props(string({DefiningClass.Name}) == mc.Name);
    props = props(string({props.GetAccess}) == "public");
    props = props(~[props.Dependent]);
    res = generatePropertyList(props);
else
    res = "";
end
end
function res = generateUMLProtectedPropertyList(mc)
props = mc.PropertyList;
if ~isempty(props)
    DefiningClass = [props.DefiningClass];
    props = props(string({DefiningClass.Name}) == mc.Name);
    props = props(string({props.GetAccess}) == "private");
    props = props(~[props.Dependent]);
    res = generatePropertyList(props);
else
    res="";
end
end
function res = generateUMLPublicMethodList(mc)
meths = mc.MethodList;
DefiningClass = [meths.DefiningClass];
meths = meths(string({DefiningClass.Name}) == mc.Name);
meths = meths(string({meths.Access}) == "public");
% ignore the 'empty' method which is always present
meths = meths(string({meths.Name}) ~= "empty");
% ignore the constructor too
meths = meths(string({meths.Name}) ~= mc.Name);
res = generateMethodList(meths);
end
function res = generateUMLProtectedMethodList(mc)
meths = mc.MethodList;
DefiningClass = [meths.DefiningClass];
meths = meths(string({DefiningClass.Name}) == mc.Name);
meths = meths(string({meths.Access}) == "protected");
res = generateMethodList(meths);
end
function res = generatePropertyList(props)
res = repmat("",1,length(props));
for pp=1:length(props)
    if isempty(props(pp).Validation)
        res(pp)=props(pp).Name;
    else
        if isempty(props(pp).Validation.Class)
            res(pp)=props(pp).Name;
        else
            % check whether the property is of a built-in class,
            % otherwise, don't do anything with it, we will draw that with a hasa relashionship
            if ismember(props(pp).Validation.Class.Name,["double" "cell" "string" "struct"])
                res(pp)=strcat(props(pp).Name," : ",props(pp).Validation.Class.Name);
            end
        end
    end
end
% remove empty strings
res = res(res~="");
% join all together
res = strjoin(res,';');
end
function res = generateMethodList(meths)
res = repmat("",1,length(meths));
for mm=1:length(meths)
    res(mm)=displaymethod(meths(mm));
end
res = strjoin(res,';');
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
        classes = [classes getAllClassesInFolder(fullfile(folder,D(dd).name))];%#ok
    else
        [~,name,ext]=fileparts(D(dd).name);
        if strcmp(ext,'.m')
            if checkIfClass(fullfile(folder,[name ext]))
                classes{end+1} = name;%#ok
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