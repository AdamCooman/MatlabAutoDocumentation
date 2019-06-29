function [out1,out2] = demoFunction(varargin)


p = inputParser();
% this is the first required parameter
p.addRequired('ReqParam1',@isscalar);
% this is the second required parameter
p.addRequired('RequiredParam2',@(x) validateattributes(x,{'double'},{'scalar','positive'}))
% this is the first optional parameter
p.addOptional('OptionalParam1',5,@isscalar);
% this is the first parameter
p.addParameter('Parameter1','adam',@(x) ismember(x,'adam','david'));
% this is the second parameter
p.addParamValue('Parameter2',true,@islogical);

p.addParameter('Parameter3','nodocumentation',@ischar);
p.KeepUnmatched = true;
p.parse(varargin{:})
args = p.results;


out1 = args.ReqParam1;
out2 = 5;

% @generateHelp
% @Tagline This function demonstrates the use of the generateFunctionHelp function
% @Description long description of what the function does, placed afther the function call 
% @Example some example code to show how the function works
% @Example some more example code
% @Example and we have some more
% @Outputs(1).Description(1) this is the description for output 1
% @Outputs(1).Description(2) this is more description for output 1
% @Outputs(1).Type double
% @Outputs(2).Description output 2 description
% @Outputs(2).Type string
