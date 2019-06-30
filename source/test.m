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

cd(fileparts(which('generateHelp')))
cd ..
cd demo

code = readTextFile(which('demoClass.m'));
res = classHelp.replaceHelp(code)

%% test for generateHelp
clear variables
close all
clc

cd(fileparts(which('generateHelp')))
cd ..
cd demo

generateHelp('.')

%% test for generateClassDiagram

generateClassDiagram('CodeFolder','.','Output','test.pdf');

