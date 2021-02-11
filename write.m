function write(record)
  % Summary of this function and detailed explanation goes here
    
  % Input for this function is a record, the output is asc file with
  % positions of a qrs complex
  % First transform the records to required format:
  % xform -i 100 -a atr   - set sampling frequency to 200 Hz,
  % then you transform the the record into matlab format (creates recordm.mat):
  % wfdb2mat -r record

  t=cputime();
  [annot, class] = Classificate(record);
  fprintf('Running time: %f\n', cputime() - t);
  asciName = sprintf('data/%s.asc',record);

  fid = fopen(asciName, 'wt');
  for i=1: size(class,2)
      if (class(1,i) == 0)
          beat = 'N';
      else
          beat = 'V';
      end
      fprintf(fid,'0:00:00.00 %d %s 0 0 0\n', annot(i), beat);
  end
  fclose(fid);
  
  % Now convert the .asc text output to binary WFDB format:
  % wrann -r record -a qrs <record.asc
  % And evaluate against reference annotations (atr) using bxb:
  % bxb -r record -f 0 -a atr qrs
end