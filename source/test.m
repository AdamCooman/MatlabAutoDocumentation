%% 

clear variables
close all
clc
cd C:\Users\Adam\Documents\MATLAB\generateDocumentation\demo\
code = readTextFile(which('demoFunction.m'));
res = functionHelp.replaceHelp(code);



%%
clear variables
close all
clc
cd C:\Users\Adam\Documents\MATLAB\generateDocumentation\demo\
generateHelp('.')