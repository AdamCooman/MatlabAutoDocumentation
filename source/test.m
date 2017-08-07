clear variables
close all
clc

VAR1 = Variable('Name','In1','Type','Double','Description','test param 1');
VAR2 = Variable('Name','In2','Type','Double','Description',{'test param 2','more info about this guy'});
VARO = Variable('Name','Out','Type','Double','Description','output parameter');

A = functionHelp('Name','Adam','Tagline','tests the adam function','RequiredInputs',{VAR1,VAR2},'OutputList',{VARO});

A.print

%% 
clear variables
close all
clc
cd C:\Users\Adam\Documents\MATLAB\generateDocumentation\demo\
code = readTextFile(which('demoFunction.m'));
res = functionHelp.parse(code);

res.print