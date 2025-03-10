fprintf("loading: Ultracold Sequence Runner.\n")

rootpath = fileparts(mfilename("fullpath"));
loadnew(rootpath, "MatlabFunctional");

srcfolders = [  "Abstraction", ...
                "Communication", ...
                "Core", ...
                "DataConv", ...
                "General", ...
                "Modules", ...
                "Samples", ...
                "XMLs" ];

for i = 1 : numel(srcfolders)
    addpath(genpath(rootpath+"\"+srcfolders(i)));
end

function loadnew(rootpath, name)
    if ~contains(path, name); run(sprintf("%s/[%s]/loadlib", rootpath, name)); end
end