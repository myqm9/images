# Each marker binds the following Docker ARG to one exported catalog variable.
# In "args" mode emit arguments for Docker. In "defaults" mode refresh the file.
/^# versions\.env: [A-Z0-9_]+\r?$/ {
    key = $3
    sub(/\r$/, "", key)
    if (mode == "defaults") print
    if ((getline) <= 0 || $0 !~ /^ARG [A-Z0-9_]+=/ || ENVIRON[key] == "") {
        print FILENAME ":" FNR ": invalid version binding for " key > "/dev/stderr"
        exit 1
    }
    name = $2
    sub(/=.*/, "", name)
    value = name "=" ENVIRON[key]
    if (check_defaults) {
        current = $0
        sub(/\r$/, "", current)
        if (current != "ARG " value) {
            printf "%s:%d: needs sync for %s in versions.env\n  found:    %s\n  expected: ARG %s\n", FILENAME, FNR, key, current, value > "/dev/stderr"
            drift = 1
        }
    }
    if (mode == "defaults") print "ARG " value ($0 ~ /\r$/ ? "\r" : "")
    else if (!seen[name]++) print value
    bindings++
    next
}
mode == "defaults" { print }
END {
    if (!bindings) {
        print FILENAME ": no version bindings" > "/dev/stderr"
        exit 1
    }
    if (drift) exit 1
}
