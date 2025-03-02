function out_data = SuperScanf(in_str, in_format)

out_data = textscan(in_str,in_format,'Delimiter',',','CommentStyle','%');