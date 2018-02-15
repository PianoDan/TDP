function varargout = readsubject(inputfilename, varargin)
% READSUBJECT  Reads a TDP data file and produces an Excel spreadsheet
%
% Usage:
%   readsubject(filename,[type])
%
%   [Type] is optional - 'matlab', 'excel', or 'both' (include the quotes!)
%   Defaults to 'matlab' if not specified.
%
%
%   Output file is filename_analysis.xlsx
%
%   Daniel Alt (dan@fnerk.com)
%

% Test input arguments for output type
if nargin == 1
    outtype = 'matlab';
elseif ~ismember(varargin{1}, {'excel','matlab','both'})
    disp(strcat('Unrecognized Output Type: ', varargin{1}));
    return
else
    outtype = varargin{1};
end
  
% Setup input and output files
[inpath, inname, ~] = fileparts(inputfilename);
xloutputfilename = strcat(inpath,filesep,inname,'_analysis.xlsx');
moutputfilename = strcat(inpath,filesep,inname,'_analysis.mat');

subject.id = inname(1:end-1);

sumheader = {'Stimulus','Start Answer (ms)','End Answer(ms)'};
header = {'Block','Stim','Trial','Answer (BPM)', 'Time(s)',...
        'Stimulus File','Time(ms)', 'Time Interval(ms)', 'Answer (ms)',...
        'Beat Fraction','Total Beat'};
filere = 'Melody(\d+)\D';

% Open input file
inputfile = fopen(inputfilename);

if inputfile < 0
    disp(strcat('Unable to open input file: ',inputfilename));
    return
end

% Process input file
while ~feof(inputfile)
    linein = fgetl(inputfile);
    
    % Advance to the start of the practice block, skip headers
    while ~strncmp(linein,'block',4) && ~feof(inputfile)
        linein = fgetl(inputfile);
    end
    
    % READ PRACTICE BLOCK
    % Until you get to the end of the practice block, read in a line at a time
    % and add it to the practice block data array
    practicearray = header;
    interparray = header;
    while ~feof(inputfile)
        linein = fgetl(inputfile);
        % If we reach a blank line, assume there was a test block due
        % to audio issues, and start over
        if isempty(linein)
            practicearray = header;
            interparray = header;
            while ~strncmp(linein,'block',4) && ~feof(inputfile)
                linein = fgetl(inputfile);                
            end
            linein = fgetl(inputfile);
        end
        % If we're starting a new block test to see if
        % we're starting over
        if strncmp(linein,'block',4)
            linein = fgetl(inputfile);
            if isempty(linein)
                % If we've reached a blank line, we're starting over
                practicearray = header;
                interparray = header;
            else
                % Test to see if the file number is 1.  If it is, we've
                % started over.
                linein = linein(~isspace(linein));
                linearray = strsplit(linein,',');
                stimfilename = linearray{6};
                [~, tok] = regexp(stimfilename, filere, 'match', 'tokens');
                filenumber = tok{1}{1};
                if ~strcmp(filenumber,'1')
                    break
                else
                    practicearray = header;
                    interparray = header;
                end
            end
        end

        % Read in the next line of the practice block, calculate values
        linein = linein(~isspace(linein));
        linearray = strsplit(linein,',');
        mstime = 1000 * str2double(linearray{5});
        answerms = (60./str2double(linearray{4}))*1000;
        
        if mstime == 0  
            %If this is the first line of the stimulus, initialize values
            interval = 0;
            priortime = 0;
            totalbeat = 0;
            priormark = 0;
            priormarktime = 0;
            priortempo = answerms;
            beatfraction = 0;
            %Determine stiumulus id based on regexp defined at top
            stimfilename = linearray{6};
            [~, tok] = regexp(stimfilename, filere, 'match', 'tokens');
            filenumber = tok{1}{1};
        else
            % Otherwise, update these values based on the prior step
            interval = mstime - priortime;
            beatfraction = interval/priortempo;
            priortempo = answerms;            
            priortime = mstime;
        end
        
        % Caluculate these values each step
        totalbeat = totalbeat + beatfraction;
        linearray = [linearray, mstime, interval, answerms, beatfraction, totalbeat];    

        % Add data to interpolated array if we have passed a multiple of
        % 0.5 beats
        currentmark = floor(totalbeat*2)/2;
        if totalbeat == 0
            % Handle first point
            interparray = [interparray ; linearray];
        elseif currentmark > priormark            
            lastpoint = practicearray(end,:); % prior data point
            for i = priormark + 0.5 : 0.5 : currentmark
                interpline = lastpoint;
                interpline{11} = i; % Total Beat
                interpline{10} = 0.5; % Beat Fraction
                interpline{7} = lastpoint{7} + lastpoint{9}*(i - lastpoint{11});
                interpline{5} = interpline{7} * 0.001;
                interpline{8} = interpline{7} - priormarktime;
                interparray = [interparray ; interpline];
                priormarktime = interpline{7};
            end
            priormark = i;
        end
        
        % Add values to arrays    
        practicearray = [practicearray ; linearray];
        

    end
    % Rearrange array into desired order
    practicearray = practicearray(:,[6,1,2,3,4,5,7,8,9,10,11]);
    interparray = interparray(:,[6,1,2,3,4,5,7,8,9,10,11]);
    combarray = [practicearray(2:end,:);interparray(2:end,:)];
    combarray = sortrows(combarray,11);
    combarray = [header;combarray];
    
    % Write Excel File if requested
    if ~strcmp(outtype,'matlab')
        xlswrite(xloutputfilename,practicearray,'Practice');
        xlswrite(xloutputfilename,interparray,'Practice', 'M1');
        xlswrite(xloutputfilename,combarray,'Practice','Y1');
        sumarray = {'1', practicearray{2,9}, practicearray{end,9}};
    end
    % Add data to output
    subject.data={'1',practicearray,interparray,combarray};    
    
    %Reset Variables after practice block
    trial = '1';
    testarray = header;
    interparray = header;
    interval = 0;
    priortime = 0;
    totalbeat = 0;
    priormark = 0;
    priormarktime = 0;
    beatfraction = 0;
    priortempo = (60./str2double(linearray{4}))*1000;
    
    %Read experimantal blocks
    while ~feof(inputfile)
        
%         linein = fgetl(inputfile);
%         linein = linein(~isspace(linein));
%         linearray = strsplit(linein,',');
        
        %If we have started a new trial
        if ~strcmp(linearray{3},trial)
            
            %Write the current test array 
            testarray = testarray(:,[6,1,2,3,4,5,7,8,9,10,11]);
            interparray = interparray(:,[6,1,2,3,4,5,7,8,9,10,11]);    
            combarray = [testarray(2:end,:);interparray(2:end,:)];
            combarray = sortrows(combarray,11);
            combarray = [header;combarray];
            
            if ~strcmp(outtype,'matlab')
                xlswrite(xloutputfilename,testarray,strcat('M',filenumber));
                xlswrite(xloutputfilename,interparray,strcat('M',filenumber), 'M1');
                xlswrite(xloutputfilename,combarray,strcat('M',filenumber), 'Y1');
                sumarray = [sumarray ; {filenumber, testarray{2,9}, testarray{end,9}}];
            end
            subject.data(end+1,:) = {filenumber,testarray,interparray,combarray};
            
            %Reset variables
            testarray = header;
            interparray = header;
            interval = 0;
            priortime = 0;
            priormark = 0;
            priormarktime = 0;
            priortempo = (60./str2double(linearray{4}))*1000;
            totalbeat = 0;
            beatfraction = 0;
            trial = linearray{3};
        end

        %Determine stiumulus id based on regexp defined at top
        stimfilename = linearray{6};
        [~, tok] = regexp(stimfilename, filere, 'match', 'tokens');
        filenumber = tok{1}{1};

        % Determine output values
        mstime = 1000 * str2double(linearray{5});       
        interval = mstime - priortime;
        beatfraction = interval / priortempo;
        priortime = mstime;
        answerms = (60./str2double(linearray{4})) * 1000;
        priortempo = answerms;
        totalbeat = totalbeat + beatfraction;
        linearray = [linearray, mstime, interval, answerms, beatfraction, totalbeat];  
        
        % Add data to interpolated array if we have passed a multiple of
        % 0.5 beats
        currentmark = floor(totalbeat*2)/2;
        if totalbeat == 0
            % Handle first point
            interparray = [interparray ; linearray];
        elseif currentmark > priormark            
            lastpoint = testarray(end,:); % prior data point
            for i = priormark + 0.5 : 0.5 : currentmark
                interpline = lastpoint;
                interpline{11} = i; % Total Beat
                interpline{10} = 0.5; % Beat Fraction
                interpline{7} = lastpoint{7} + lastpoint{9}*(i - lastpoint{11});
                interpline{5} = interpline{7} * 0.001;
                interpline{8} = interpline{7} - priormarktime;
                interparray = [interparray ; interpline];
                priormarktime = interpline{7};
            end
            priormark = i;
        end
        
        % Add a new line to the array for this trial      
        testarray = [testarray ; linearray];
        
        %Read next line
        linein = fgetl(inputfile);
        linein = linein(~isspace(linein));
        linearray = strsplit(linein,',');
                
    end
    
    break
end

% Close the input file
fclose(inputfile);

% Process last trial
testarray = testarray(:,[6,1,2,3,4,5,7,8,9,10,11]);
interparray = interparray(:,[6,1,2,3,4,5,7,8,9,10,11]);
combarray = [testarray(2:end,:);interparray(2:end,:)];
combarray = sortrows(combarray,11);
combarray = [header;combarray];

% If an Excel output file is desired, generate it.
if ~strcmp(outtype,'matlab')
    xlswrite(xloutputfilename,testarray,strcat('M',filenumber));
    xlswrite(xloutputfilename,interparray,strcat('M',filenumber), 'M1');
    xlswrite(xloutputfilename,combarray,strcat('M',filenumber), 'Y1');
    % Generate summary data
    sumarray = [sumarray ; {filenumber, testarray{2,9}, testarray{end,9}}];
    [~,idx] = sort(str2double(sumarray(:,1)));
    sumarray = [sumheader;sumarray(idx,:)];
    xlswrite(xloutputfilename,cellstr(strcat({'Summary for Subject'},{' '},subject.id)));
    xlswrite(xloutputfilename,sumarray,'Sheet1','A3');
end

% Add the last subject to the matlab data, and save matlab file if desired
subject.data(end+1,:) = {filenumber,testarray,interparray,combarray};
if ~strcmp(outtype,'excel')
    save(moutputfilename,'subject');
end

return;

