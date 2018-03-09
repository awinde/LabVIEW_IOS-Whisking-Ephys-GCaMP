function [tdmsData]=ReadInTDMSFile(filename)
%   function [tdmsData]=ReadInTDMSFile(filename)
%
%   Author: Aaron Winder
%   Affiliation: Engineering Science and Mechanics, Penn State University
%   https://github.com/awinde
%
%   DESCRIPTION: Read in the .tdms files acquired using the LabVIEW
%   acquisition scripts found at: 
%       https://github.com/awinde/LabVIEW---NVC-Acquisition
%
%   The called function ConvertTDMS was downloaded from:
%       http://www.mathworks.com/matlabcentral/fileexchange/44206-converttdms--v10-
%_______________________________________________________________
%   PARAMETERS:
%               filename - [string] tdms file name with extension
%_______________________________________________________________
%   RETURN:
%               tdmsData - [structure] contents of the .tdms file organized
%               into a structure
%_______________________________________________________________

% Convert .tdms file into a data structure
[tempStruct,~]=convertTDMS(0,filename);

% Retrieve and name the measured data channels
channels = {tempStruct.Data.MeasuredData(:).Name};
omitString = 'Analog_Data'; % LabVIEW adds Analog_Data to the channel name
for c = 1:length(channels)
    omitInds = length(omitString)+1:length(channels{c});
    tdmsData.Data.(channels{c}(omitInds)) = ...
        tempStruct.Data.MeasuredData(c).Data;
end

% Add trial notes to the structure
tdmsData.Info = tempStruct.Data.Root;

% Convert the numeric fields of the trial notes to integers
fnames = fieldnames(tdmsData.Info);
for fn = 1:length(fnames)
    [converted,status] = str2num(tdmsData.Info.(fnames{fn}));
    if status
        tdmsData.Info.(fnames{fn}) = converted;
    end
end