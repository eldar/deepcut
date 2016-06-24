function printpdf(fname)
%PRINTPDF Prints the current figure into a pdf document
set(gca, 'LooseInset', get(gca, 'TightInset'));
fname = [regexprep(fname, '^(.*)\.pdf$', '$1'), '.eps'];
% fname = [regexprep(fname, '^(.*)\.pdf$', '$1'), '.pdf'];
print('-depsc', fname) ;
% print('-dpdf', fname);
if ~system(['epstopdf ', fname])
% if ~system(['/usr/bin/epstopdf ', fname])
system(['rm ', fname]);
end