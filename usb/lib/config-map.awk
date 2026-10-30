# Map configuration keys to normalized manifest settings, without evaluation.
BEGIN {FS="\t"}
{sub(/\r$/, "")}
FILENAME==ARGV[1] {
    p=index($0,"="); if(!p){bad=1;next}
    values[substr($0,1,p-1)]=substr($0,p+1); next
}
/^#/ || /^$/ {next}
{
    if(NF!=2 || $1!~/^[A-Za-z][A-Za-z0-9_.-]*$/ || $2!~/^[a-z][a-z0-9_]*$/ || seen[$1]++ || !($2 in values)) {bad=1;next}
    lines[++n]=$1 " = " values[$2]
}
END {if(bad || !n){print "Configuration mapping is invalid or references an unknown setting.";exit 1};for(i=1;i<=n;i++)print lines[i]}
