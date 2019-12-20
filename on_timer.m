function on_timer(timeseries, outfile)

% Timer callback for eH logger. Arguments are
% 1. a cell of two vectors, one of time strings and
% one of eh measurements, and 2. the file name to
% which to write the formatted output.

% S McCue WHOI 2017 smccue@whoi.edu

oh = fopen(outfile, 'w');

formatspec = '%s\t%5.3f\n';

for i = 1:length(timeseries{1,2})
   fprintf(oh, formatspec, timeseries{1,1}(i,:), timeseries{1,2}(i));
end

fclose(oh);


end