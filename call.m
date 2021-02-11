files = dir('data/*.mat');
for file = files' 
    nameWithoutExt = regexprep(file.name,'m.mat','');
    try
        write(nameWithoutExt)
    catch
        continue
    end
end