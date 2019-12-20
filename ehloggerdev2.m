%% Get rid of any orphaned serial port object.
% If the script has problems connecting to the serial port
% that has been confirmed as below, invoke the following:
orphans = instrfindall;
if ~ isempty(orphans), fclose(orphans), end;

%% Set port ID
% To confirm to which port the USB adapter/eh probe is connected,
% use the MSWindows util at ControlPanel->System->DeviceManager->Ports
port_str = 'COM8';

%% Set subsampling ratio
% Sets how many readings are skipped until a value is
% put on save stack, displayed in text window, and plotted.
% N-1
skip_counter = 11;

% These are just used for feedback. Port setting are hardwired and
% in next stanza.
baud_rate_str = '9600'; % does not control port. Change below. 
data_bits_str='8';  % does not control port. Change below. 


%% Create serial object
% Reconsider changing the params below. They worked on the
% bench and match the info provided by Koichi.
spo = serial(port_str, 'Name','ehlogger-serial');
set(spo, 'BaudRate', 9600);
set(spo, 'DataBits', 8);
set(spo, 'Parity', 'none');
set(spo, 'Terminator', 'CR');
set(spo, 'StopBits', 2);
set(spo, 'BytesAvailableFcnMode', 'Terminator');
set(spo, 'BytesAvailableFcn','');

fopen(spo);
infostr = sprintf('Opening serial port: port %s, baud %s bits\n', port_str, baud_rate_str, data_bits_str);
disp(infostr)
%disp('Close either figure to end logging')

%% Initialize params, timers, etc
% Destroy previous figures
close all
opengl software

% Destroy previous timer instances
delete(timerfindall);

% Clear the working vectors
datastack=[];
timestack=[];
argcell = cell(1,2);

% Outfile names are derived from the start time of this script.
% Logged data file, saved plot, and saved workspace use this root.
outroot = datestr(now, 'yyyymmddHHMMSS');
outfile = sprintf('ehlog_%s.dat', outroot);

% Init the cell array used to pass data into the timer callback
argcell{1,1}=[];
argcell{1,2}=[];
time = now;
timestack=[time];
datastack=[0.0];

% Set up timer that routinely writes to file. The period is
% controlled by variable filewriteperiod.
filewriteperiod = 120; %seconds
tmr = timer('ExecutionMode', 'FixedRate', 'Period', filewriteperiod);
tmr.TimerFcn = 'on_save_timer(argcell, outfile)';

figth = figure('Visible','on','Name','eH Logger','Position',[400,300,400,75]);
figph = figure('Visible','on','Name','eH Plotter','Position',[100,100,550,300]);

uih=uicontrol('Parent',figth,...
    'Style','text',...
    'String','Starting...',...
    'Foregroundcolor','b',...
    'FontSize',32,...
    'Fontname','Helvetica',...
    'Fontweight','bold',...
    'Position',[10, 10, 400, 30] ); 

axh = axes('Parent',figph,...
    'YGrid','on',...
    'YColor',[0.9725 0.9725 0.9725],...
    'XGrid','on',...
    'XColor',[0.9725 0.9725 0.9725],...
    'Color',[0 0 0],...
    'Position',[0.1,0.1,0.8,0.7]);

ploth = plot(axh, time, datastack, 'Marker','.','LineWidth',1,'Color',[0 1 0]);
diag = set(uih,'string','Starting','fontsize',18,'fontweight','bold','foregroundcolor','b');

start(tmr);
set(figth, 'Visible', 'on');
i=0;
while (ishghandle(figph) && ishghandle(figth))

  % Pull measurement from serial port
  indata = str2double(fgetl(spo));
  i=i+1;
  if i >= skip_counter
     i=0;
     newdata=indata;
     time=now;
 
     datastack = [datastack; newdata];
     timestack = [timestack; time];
    
     datetimeformat = 'yyyy/mm/dd HH:MM:SS.FFF';
     argcell{1,1} = datestr(timestack, datetimeformat);
     argcell{1,2} = datastack;
  
     % Update the dialog box with the latest measurement.
     disp_str=sprintf('%s eH=%8.3f', datestr(now), newdata);
     set(uih,'string',disp_str,'Visible','on');
       
%     get(ploth)
     set(ploth, 'YData', datastack, 'XData', timestack);
     axes(axh);
     th=title(axh, 'eH Logger', 'fontsize', 24, 'fontweight', 'bold');
     xl=xlabel(axh,'Time','fontsize', 16, 'fontweight', 'bold');
     ylabel(axh, 'eH','fontsize', 16, 'fontweight', 'bold');
     datetick(axh,'x','HH:MM');
     drawnow
             
  end
    
end

%% This section done upon breaking out of loop
disp('A figure was closed. Ending eh logger script');
delete(tmr);
on_save_timer(argcell, outfile);  % Explicitly invoke final write/close of data file
s_all=instrfindall;
fclose(s_all);
try
  fclose(all);
catch
end

% Save the workspace with same name as logger file
disp('Saving the workspace from this last session');
save(outroot, 'timestack','datastack')
