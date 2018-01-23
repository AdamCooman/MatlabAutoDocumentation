%% test for functionHelp
clear variables
close all
clc

cd(fileparts(which('generateHelp')))
cd ..
cd demo

code = readTextFile(which('demoFunction.m'));
res = functionHelp.replaceHelp(code)

%% test for classHelp
clear variables
close all
clc
cd C:\Users\acooman\Documents\MATLAB\generateFunctionHelp\demo\
code = readTextFile(which('demoClass.m'));
res = classHelp.replaceHelp(code);

%% test for generateHelp
clear variables
close all
clc
cd C:\Users\Adam\Documents\MATLAB\generateDocumentation\demo\
generateHelp('.')

