classdef demoClass
    % FRM   Value class that contains a network response
    %
    %   See also MULTIMATRIX, MULTIPORT.
    properties (Dependent)
        % This contains the data of the FRM. It is a MultiMatrix
        Data
        % Normalised frequency axis, between [-1 and 1]
        Freq_normalised
        % Frequency when the FRM is on the complex plane
        Freq
    end
    properties (Access=protected)
        % Multimatrix containing the raw data
        data
        % 1x1xF array which contains the frequency points at which the FRM is evaluated
        freq_normalised
    end
    
    methods
        %% CONSTRUCTOR
        function obj = demoClass(Data,varargin)
            
            % create input parser
            p = inputParser;
            p.StructExpand = true;
            p.FunctionName = 'FRM';
            p.KeepUnmatched = true;
            % Frequency axis of the FRM
            p.addParameter('Freq'    ,linspace(-1,1,length(obj.Data)),@obj.checkFreq);
            % Maximum frequency used in the frequency normalisation
            p.addParameter('FMax'    ,[]				 ,@isscalar);
            % minimum frequency used in the frequency normalisation
            p.addParameter('FMin'    ,[]				 ,@isscalar);
            % domain on which the data is located. This can be either
            % 'PLANE' or 'DISC'
            p.addParameter('Domain'  ,'PLANE'            ,@obj.checkDomain);
            % frequency normalisation type used. This can be BANDPASS or LOWPASS
            p.addParameter('NormType','BANDPASS'         ,@obj.checkNormType);
            % function handle to the function used to go from the plane to the disc and back
            p.addParameter('Transform_function',@(Z,f,dir) mobiusTransform(Z,f,dir),@obj.checkTransformFunction);
            p.parse(varargin{:});
            args = p.Results;
            
            
            % @Tagline constructor for the class
            % @Outputs{1}.Description{1} Constructed object
            % @Outputs{1}.Type Democlass
            
        end
        
        %% Freq, Getter and Setter
        function obj = set.Freq(obj,freq)
            if ~FRM.checkFreq(freq)
                error('The povided frequency vector is not correct');
            end
            % make sure freq is a 1x1xF array
            freq = permute(freq(:),[3 2 1]);
            % check if fMax and fMin are already set
            if isempty(obj.fMax)
                obj.fMax = max(freq);
            end
            if isempty(obj.fMin)
                obj.fMin = min(freq);
            end
            % normalise the provided frequency axis
            obj.freq_normalised = obj.normalise(freq);
            if strcmpi(obj.Domain,'DISC')
                % transform to the unit disc if needed
                obj.freq_normalised = obj.freq2theta;
            end
        end
        
        %% END function
        function R = end(obj,K,~)
            % used when the FRM is indexed as FRM(:,:,1:end)
            R = size(obj,K);
        end
    end
end

% @Tagline class to test generateHelp
% @Description this is the description of the class
% @Description it can be multiple lines
% @Example it can also contain an example
% @SeeAlso ADAM
% @SeeAlso TEST


