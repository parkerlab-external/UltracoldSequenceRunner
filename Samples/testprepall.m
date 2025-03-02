dict = load("Samples\dict.mat", "dict"); dict = dict.dict;
fid = fopen("Samples/oneeach_num.log", "w");
seq = PrepFromXML(struct(), 'Samples/oneeach_num.xml', fid);
fclose(fid);
fid = fopen("Samples/oneeach_symb.log", "w");
seq = PrepFromXML(dict, 'Samples/oneeach_symb.xml', fid);
fclose(fid);
